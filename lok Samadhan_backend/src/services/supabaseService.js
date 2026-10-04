const { supabaseClient, pgPool, inMemoryStore, getDatabaseMode } = require('../config/database');
const { getDepartmentByCategory } = require('../constants/departments');

class SupabaseService {
  /**
   * Retrieves grievances with optional filters
   */
  async getGrievances(filters = {}) {
    const mode = getDatabaseMode();

    if (mode === 'supabase' && supabaseClient) {
      try {
        let query = supabaseClient.from('grievances').select('*, grievance_audit_logs(*)');

        if (filters.status) query = query.eq('status', filters.status);
        if (filters.departmentCategory) query = query.eq('department_category', filters.departmentCategory);
        if (filters.urgency) query = query.eq('urgency', filters.urgency);
        if (filters.district) query = query.ilike('district', `%${filters.district}%`);
        if (filters.citizenPhone) query = query.eq('citizen_phone', filters.citizenPhone);

        query = query.order('created_at', { ascending: false });

        const { data, error } = await query;
        if (error) throw error;

        // Transform snake_case to camelCase
        return data.map(this._mapFromDb);
      } catch (err) {
        console.warn(`[SupabaseService] Query failed, falling back to in-memory: ${err.message}`);
      }
    }

    if (mode === 'postgres' && pgPool) {
      try {
        let queryText = 'SELECT * FROM grievances WHERE 1=1';
        const params = [];
        let pIndex = 1;

        if (filters.status) {
          queryText += ` AND status = $${pIndex++}`;
          params.push(filters.status);
        }
        if (filters.departmentCategory) {
          queryText += ` AND department_category = $${pIndex++}`;
          params.push(filters.departmentCategory);
        }
        if (filters.urgency) {
          queryText += ` AND urgency = $${pIndex++}`;
          params.push(filters.urgency);
        }
        if (filters.district) {
          queryText += ` AND district ILIKE $${pIndex++}`;
          params.push(`%${filters.district}%`);
        }
        if (filters.citizenPhone) {
          queryText += ` AND citizen_phone = $${pIndex++}`;
          params.push(filters.citizenPhone);
        }

        queryText += ' ORDER BY created_at DESC';
        const res = await pgPool.query(queryText, params);
        return res.rows.map(this._mapFromDb);
      } catch (err) {
        console.warn(`[PostgresService] Query failed, falling back to in-memory: ${err.message}`);
      }
    }

    // In-memory fallback
    let list = [...inMemoryStore.grievances];

    if (filters.status) {
      list = list.filter((g) => g.status === filters.status);
    }
    if (filters.departmentCategory) {
      list = list.filter((g) => g.departmentCategory === filters.departmentCategory);
    }
    if (filters.urgency) {
      list = list.filter((g) => g.urgency === filters.urgency);
    }
    if (filters.district) {
      const distLower = filters.district.toLowerCase();
      list = list.filter((g) => g.district.toLowerCase().includes(distLower));
    }
    if (filters.citizenPhone) {
      const cleanPhone = filters.citizenPhone.replace(/[\s-]/g, '');
      list = list.filter((g) => g.citizenPhone.replace(/[\s-]/g, '').includes(cleanPhone));
    }
    if (filters.search) {
      const s = filters.search.toLowerCase();
      list = list.filter(
        (g) =>
          g.id.toLowerCase().includes(s) ||
          g.rawSpeechText.toLowerCase().includes(s) ||
          g.translatedText.toLowerCase().includes(s) ||
          g.villageWard.toLowerCase().includes(s) ||
          g.citizenName.toLowerCase().includes(s)
      );
    }

    return list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  /**
   * Retrieves single grievance by ID with audit logs
   */
  async getGrievanceById(id) {
    const cleanId = id.trim().toUpperCase();
    const mode = getDatabaseMode();

    if (mode === 'supabase' && supabaseClient) {
      try {
        const { data, error } = await supabaseClient
          .from('grievances')
          .select('*, grievance_audit_logs(*)')
          .eq('id', cleanId)
          .single();
        if (!error && data) return this._mapFromDb(data);
      } catch (err) {
        console.warn(`[SupabaseService] getGrievanceById fallback: ${err.message}`);
      }
    }

    return inMemoryStore.grievances.find((g) => g.id.toUpperCase() === cleanId) || null;
  }

  /**
   * Creates a new grievance
   */
  async createGrievance(data) {
    const mode = getDatabaseMode();
    const grievanceId = data.id || `LS-${new Date().getFullYear()}-${Math.floor(10000 + Math.random() * 90000)}`;

    const record = {
      ...data,
      id: grievanceId,
      createdAt: data.createdAt || new Date().toISOString(),
      auditLog: data.auditLog || [
        {
          timestamp: new Date().toISOString(),
          statusLabel: 'Voice Grievance Registered',
          actor: 'Lok Samadhan Gateway',
          description: `Grievance registered in dialect: ${data.spokenDialect || 'Hindi'}.`
        }
      ]
    };

    if (mode === 'supabase' && supabaseClient) {
      try {
        const dbPayload = this._mapToDb(record);
        const { error } = await supabaseClient.from('grievances').insert(dbPayload);
        if (error) throw error;

        // Insert initial audit logs
        if (record.auditLog && record.auditLog.length > 0) {
          const auditRows = record.auditLog.map((log) => ({
            grievance_id: grievanceId,
            timestamp: log.timestamp,
            status_label: log.statusLabel,
            actor: log.actor,
            description: log.description
          }));
          await supabaseClient.from('grievance_audit_logs').insert(auditRows);
        }
      } catch (err) {
        console.warn(`[SupabaseService] Failed to insert to Supabase: ${err.message}`);
      }
    }

    // Always keep in-memory store synchronized
    inMemoryStore.grievances.unshift(record);
    return record;
  }

  /**
   * Updates grievance status, notes, or resolution
   */
  async updateGrievance(id, updates) {
    const cleanId = id.trim().toUpperCase();
    const mode = getDatabaseMode();

    if (mode === 'supabase' && supabaseClient) {
      try {
        const dbUpdates = this._mapToDb(updates);
        await supabaseClient.from('grievances').update(dbUpdates).eq('id', cleanId);
      } catch (err) {
        console.warn(`[SupabaseService] update failed on Supabase: ${err.message}`);
      }
    }

    const index = inMemoryStore.grievances.findIndex((g) => g.id.toUpperCase() === cleanId);
    if (index !== -1) {
      inMemoryStore.grievances[index] = {
        ...inMemoryStore.grievances[index],
        ...updates
      };
      return inMemoryStore.grievances[index];
    }
    return null;
  }

  /**
   * Appends an audit log step to a grievance
   */
  async addAuditLog(grievanceId, step) {
    const cleanId = grievanceId.trim().toUpperCase();
    const mode = getDatabaseMode();
    const newStep = {
      timestamp: step.timestamp || new Date().toISOString(),
      statusLabel: step.statusLabel,
      actor: step.actor || 'System Automation',
      description: step.description
    };

    if (mode === 'supabase' && supabaseClient) {
      try {
        await supabaseClient.from('grievance_audit_logs').insert({
          grievance_id: cleanId,
          timestamp: newStep.timestamp,
          status_label: newStep.statusLabel,
          actor: newStep.actor,
          description: newStep.description
        });
      } catch (err) {
        console.warn(`[SupabaseService] addAuditLog failed on Supabase: ${err.message}`);
      }
    }

    const g = inMemoryStore.grievances.find((item) => item.id.toUpperCase() === cleanId);
    if (g) {
      if (!g.auditLog) g.auditLog = [];
      g.auditLog.push(newStep);
    }
    return newStep;
  }

  /**
   * Returns aggregated statistics
   */
  async getStats() {
    const grievances = await this.getGrievances();
    const now = new Date();

    const total = grievances.length;
    const resolved = grievances.filter((g) => g.status === 'resolved').length;
    const underReview = grievances.filter((g) => g.status === 'underReview' || g.status === 'inProgress').length;
    const hitlPending = grievances.filter((g) => g.status === 'hitlReview' || g.isHitlFallback).length;
    const escalated = grievances.filter((g) => g.status === 'escalated' || (g.status !== 'resolved' && new Date(g.dueDate) < now)).length;

    // Category breakdown
    const byCategory = {};
    const byDistrict = {};

    grievances.forEach((g) => {
      byCategory[g.departmentCategory] = (byCategory[g.departmentCategory] || 0) + 1;
      byDistrict[g.district] = (byDistrict[g.district] || 0) + 1;
    });

    const resolutionRate = total > 0 ? Number(((resolved / total) * 100).toFixed(1)) : 0;

    return {
      totalGrievances: total,
      resolvedCount: resolved,
      activeUnderReview: underReview,
      hitlReviewPending: hitlPending,
      slaBreachedCount: escalated,
      resolutionRatePercentage: resolutionRate,
      breakdownByCategory: byCategory,
      breakdownByDistrict: byDistrict
    };
  }

  _mapFromDb(row) {
    if (!row) return null;
    return {
      id: row.id,
      citizenPhone: row.citizen_phone || row.citizenPhone,
      citizenName: row.citizen_name || row.citizenName,
      spokenDialect: row.spoken_dialect || row.spokenDialect,
      rawSpeechText: row.raw_speech_text || row.rawSpeechText,
      translatedText: row.translated_text || row.translatedText,
      departmentCategory: row.department_category || row.departmentCategory,
      villageWard: row.village_ward || row.villageWard,
      block: row.block,
      district: row.district,
      state: row.state,
      latitude: parseFloat(row.latitude) || 25.5941,
      longitude: parseFloat(row.longitude) || 85.1376,
      photoUrl: row.photo_url || row.photoUrl || null,
      photoAnalysisSummary: row.photo_analysis_summary || row.photoAnalysisSummary || null,
      urgency: row.urgency,
      aiConfidenceScore: parseFloat(row.ai_confidence_score || row.aiConfidenceScore) || 0.9,
      status: row.status,
      isHitlFallback: Boolean(row.is_hitl_fallback ?? row.isHitlFallback),
      hitlReviewerNotes: row.hitl_reviewer_notes || row.hitlReviewerNotes || null,
      createdAt: row.created_at || row.createdAt,
      dueDate: row.due_date || row.dueDate,
      resolutionNote: row.resolution_note || row.resolutionNote || null,
      resolutionTimestamp: row.resolution_timestamp || row.resolutionTimestamp || null,
      escalationLevel: parseInt(row.escalation_level ?? row.escalationLevel, 10) || 0,
      assignedOfficerId: row.assigned_officer_id || row.assignedOfficerId || null,
      assignedOfficerName: row.assigned_officer_name || row.assignedOfficerName || null,
      auditLog: (row.grievance_audit_logs || row.auditLog || []).map((a) => ({
        timestamp: a.timestamp,
        statusLabel: a.status_label || a.statusLabel,
        actor: a.actor,
        description: a.description
      }))
    };
  }

  _mapToDb(obj) {
    const mapped = {};
    if (obj.id !== undefined) mapped.id = obj.id;
    if (obj.citizenPhone !== undefined) mapped.citizen_phone = obj.citizenPhone;
    if (obj.citizenName !== undefined) mapped.citizen_name = obj.citizenName;
    if (obj.spokenDialect !== undefined) mapped.spoken_dialect = obj.spokenDialect;
    if (obj.rawSpeechText !== undefined) mapped.raw_speech_text = obj.rawSpeechText;
    if (obj.translatedText !== undefined) mapped.translated_text = obj.translatedText;
    if (obj.departmentCategory !== undefined) mapped.department_category = obj.departmentCategory;
    if (obj.villageWard !== undefined) mapped.village_ward = obj.villageWard;
    if (obj.block !== undefined) mapped.block = obj.block;
    if (obj.district !== undefined) mapped.district = obj.district;
    if (obj.state !== undefined) mapped.state = obj.state;
    if (obj.latitude !== undefined) mapped.latitude = obj.latitude;
    if (obj.longitude !== undefined) mapped.longitude = obj.longitude;
    if (obj.photoUrl !== undefined) mapped.photo_url = obj.photoUrl;
    if (obj.photoAnalysisSummary !== undefined) mapped.photo_analysis_summary = obj.photoAnalysisSummary;
    if (obj.urgency !== undefined) mapped.urgency = obj.urgency;
    if (obj.aiConfidenceScore !== undefined) mapped.ai_confidence_score = obj.aiConfidenceScore;
    if (obj.status !== undefined) mapped.status = obj.status;
    if (obj.isHitlFallback !== undefined) mapped.is_hitl_fallback = obj.isHitlFallback;
    if (obj.hitlReviewerNotes !== undefined) mapped.hitl_reviewer_notes = obj.hitlReviewerNotes;
    if (obj.createdAt !== undefined) mapped.created_at = obj.createdAt;
    if (obj.dueDate !== undefined) mapped.due_date = obj.dueDate;
    if (obj.resolutionNote !== undefined) mapped.resolution_note = obj.resolutionNote;
    if (obj.resolutionTimestamp !== undefined) mapped.resolution_timestamp = obj.resolutionTimestamp;
    if (obj.escalationLevel !== undefined) mapped.escalation_level = obj.escalationLevel;
    if (obj.assignedOfficerId !== undefined) mapped.assigned_officer_id = obj.assignedOfficerId;
    if (obj.assignedOfficerName !== undefined) mapped.assigned_officer_name = obj.assignedOfficerName;
    return mapped;
  }
}

module.exports = new SupabaseService();
