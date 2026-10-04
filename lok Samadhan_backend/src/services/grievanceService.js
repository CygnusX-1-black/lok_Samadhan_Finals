const supabaseService = require('./supabaseService');
const aiService = require('./aiService');
const osmService = require('./osmService');
const { getDepartmentByCategory } = require('../constants/departments');
const { URGENCY_LEVELS } = require('../constants/statuses');

class GrievanceService {
  /**
   * Retrieves all grievances with SLA breach checks
   */
  async getAllGrievances(filters = {}) {
    const list = await supabaseService.getGrievances(filters);
    const now = new Date();

    // Check SLA status dynamically
    return list.map((g) => {
      const isBreached = g.status !== 'resolved' && new Date(g.dueDate) < now;
      return {
        ...g,
        isSlaBreached: isBreached,
        remainingSlaHours: g.status === 'resolved'
          ? 0
          : Math.max(0, Math.round((new Date(g.dueDate) - now) / (1000 * 3600)))
      };
    });
  }

  /**
   * Retrieves single grievance by ID with department info and SLA calculations
   */
  async getGrievanceById(id) {
    const g = await supabaseService.getGrievanceById(id);
    if (!g) return null;

    const now = new Date();
    const isBreached = g.status !== 'resolved' && new Date(g.dueDate) < now;
    const dept = getDepartmentByCategory(g.departmentCategory);

    return {
      ...g,
      departmentInfo: dept,
      isSlaBreached: isBreached,
      remainingSlaHours: g.status === 'resolved'
        ? 0
        : Math.max(0, Math.round((new Date(g.dueDate) - now) / (1000 * 3600)))
    };
  }

  /**
   * Creates a new civic grievance
   * - Performs AI classification if category is missing
   * - Performs OSM reverse geocoding if lat/lng are provided
   * - Calculates SLA Due Date
   */
  async createGrievance(payload) {
    const now = new Date();
    let category = payload.departmentCategory;
    let urgency = payload.urgency || 'medium';
    let confidence = payload.aiConfidenceScore || 0.95;
    let dialect = payload.spokenDialect || 'Hindi';
    let translated = payload.translatedText;
    let isHitl = payload.isHitlFallback || false;

    // 1. If category or translation is not provided, trigger Gemma / Gemini AI
    if (!category || !translated) {
      const aiResult = await aiService.classifyGrievance(payload.rawSpeechText, {
        villageWard: payload.villageWard,
        block: payload.block,
        district: payload.district,
        state: payload.state
      });

      category = category || aiResult.departmentCategory;
      urgency = urgency || aiResult.urgency;
      confidence = aiResult.confidenceScore || 0.92;
      dialect = dialect || aiResult.spokenDialect;
      translated = translated || aiResult.translatedText;
      isHitl = aiResult.isHitlRequired || confidence < 0.75;
    }

    // 2. OpenStreetMap reverse geocode if location details missing but coordinates provided
    let villageWard = payload.villageWard;
    let block = payload.block;
    let district = payload.district;
    let state = payload.state;
    const lat = parseFloat(payload.latitude) || 25.5941;
    const lon = parseFloat(payload.longitude) || 85.1376;

    if (!villageWard || !district || villageWard === 'Unknown') {
      try {
        const osmLocation = await osmService.reverseGeocode(lat, lon);
        villageWard = villageWard || osmLocation.villageWard;
        block = block || osmLocation.block;
        district = district || osmLocation.district;
        state = state || osmLocation.state;
      } catch (err) {
        console.warn(`[GrievanceService] Reverse geocode fallback: ${err.message}`);
      }
    }

    // 3. Compute Department SLA Due Date
    const dept = getDepartmentByCategory(category);
    const urgencyConfig = URGENCY_LEVELS[urgency] || URGENCY_LEVELS.medium;
    const effectiveSlaHours = Math.round(dept.defaultSlaHours * urgencyConfig.slaMultiplier);
    const dueDate = new Date(now.getTime() + effectiveSlaHours * 3600 * 1000);

    // Initial status
    const initialStatus = isHitl ? 'hitlReview' : 'received';
    const id = payload.id || `LS-${now.getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;

    const initialAuditLogs = [
      {
        timestamp: now.toISOString(),
        statusLabel: 'Voice Grievance Registered',
        actor: 'Lok Samadhan Gateway',
        description: `Spoken language detected: ${dialect}. GPS: Lat ${lat.toFixed(4)}° N, Long ${lon.toFixed(4)}° E.`
      },
      {
        timestamp: new Date(now.getTime() + 1000).toISOString(),
        statusLabel: isHitl ? 'Routed to HITL Queue' : `Auto-Routed to ${dept.code}`,
        actor: 'Lok Samadhan AI Router',
        description: isHitl
          ? 'Confidence score below threshold. Routed for manual Human-In-The-Loop review.'
          : `Classified as ${dept.nameEn}. Allotted SLA: ${effectiveSlaHours} hours.`
      }
    ];

    const newRecord = {
      id,
      citizenPhone: payload.citizenPhone || '+91 98000 00000',
      citizenName: payload.citizenName || 'Citizen Nagarik',
      spokenDialect: dialect,
      rawSpeechText: payload.rawSpeechText,
      translatedText: translated,
      departmentCategory: category,
      villageWard: villageWard || 'Local Ward',
      block: block || 'Local Block',
      district: district || 'Local District',
      state: state || 'Gujarat',
      latitude: lat,
      longitude: lon,
      photoUrl: payload.photoUrl || null,
      photoAnalysisSummary: payload.photoAnalysisSummary || null,
      urgency,
      aiConfidenceScore: confidence,
      status: initialStatus,
      isHitlFallback: isHitl,
      hitlReviewerNotes: isHitl ? 'Awaiting officer categorization review' : null,
      createdAt: now.toISOString(),
      dueDate: dueDate.toISOString(),
      resolutionNote: null,
      resolutionTimestamp: null,
      escalationLevel: 0,
      assignedOfficerId: null,
      assignedOfficerName: null,
      auditLog: initialAuditLogs
    };

    return await supabaseService.createGrievance(newRecord);
  }

  /**
   * Updates status of grievance (e.g. Under Investigation, In Progress, Resolved)
   */
  async updateStatus(id, newStatus, { actor = 'Government Officer', note = '', officerId = null, officerName = null } = {}) {
    const existing = await supabaseService.getGrievanceById(id);
    if (!existing) {
      throw new Error(`Grievance with ID ${id} not found`);
    }

    const updates = {
      status: newStatus
    };

    if (newStatus === 'resolved') {
      updates.resolutionNote = note || 'Issue resolved and field work verified.';
      updates.resolutionTimestamp = new Date().toISOString();
    }

    if (officerId) updates.assignedOfficerId = officerId;
    if (officerName) updates.assignedOfficerName = officerName;

    // Add audit log
    await supabaseService.addAuditLog(id, {
      statusLabel: `Status Updated to ${newStatus}`,
      actor,
      description: note || `Grievance status transitioned from ${existing.status} to ${newStatus}.`
    });

    return await supabaseService.updateGrievance(id, updates);
  }

  /**
   * Escalates an overdue or breached grievance
   */
  async escalateGrievance(id, { reason = 'SLA Breached - Auto Escalation', actor = 'Lok Samadhan SLA Sentinel' } = {}) {
    const existing = await supabaseService.getGrievanceById(id);
    if (!existing) {
      throw new Error(`Grievance with ID ${id} not found`);
    }

    const newLevel = (existing.escalationLevel || 0) + 1;
    const updates = {
      status: 'escalated',
      escalationLevel: newLevel
    };

    await supabaseService.addAuditLog(id, {
      statusLabel: `Escalated to Level ${newLevel}`,
      actor,
      description: reason
    });

    return await supabaseService.updateGrievance(id, updates);
  }

  /**
   * Proximity query using OpenStreetMap coordinates
   */
  async getNearby(lat, lon, radiusKm = 5) {
    const all = await supabaseService.getGrievances();
    return osmService.filterNearbyGrievances(all, lat, lon, radiusKm);
  }
}

module.exports = new GrievanceService();
