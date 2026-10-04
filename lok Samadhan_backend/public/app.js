/**
 * Lok Samadhan - Web Dashboard & OpenStreetMap Controller
 */

// State
let allGrievances = [];
let activeMarkers = [];
let osmMap = null;
let markerLayerGroup = null;
let currentAiDraft = null;

// Dialect Sample Phrases
const SAMPLES = {
  'gujarati-water': 'અમારા ગામમાં પીવાના પાણીની મુખ્ય પાઇપલાઇન તૂટી ગઈ છે, ૪ દિવસથી પાણીનો પુરવઠો બંધ છે. સાણંદ તાલુકો.',
  'bhojpuri-handpump': 'हमार टोला के चापाकल दु हफ्ता से बिगड़ल बा, पीने के पानी ना आवत बा। रामपुर वार्ड 4।',
  'hindi-transformer': 'मेन रोड पर 11KV का बिजली ट्रांसफार्मर जल गया है और तार सड़क पर लटक रहा है। भारी खतरे की स्थिति है।',
  'english-pothole': 'Huge pothole crater near the central bus station causing severe traffic accidents. Immediate asphalt resurfacing needed.'
};

document.addEventListener('DOMContentLoaded', async () => {
  initMap();
  setupEventListeners();
  await loadSystemHealth();
  await refreshData();
});

// ==========================================================================
// 1. Initialize OpenStreetMap (Leaflet)
// ==========================================================================
function initMap() {
  // Center on Gujarat / Western India initially (Lat 23.0225, Lng 72.5714)
  osmMap = L.map('osm-map', {
    zoomControl: true,
    attributionControl: true
  }).setView([24.2, 79.0], 5);

  // High-performance OpenStreetMap Tile Layer
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(osmMap);

  markerLayerGroup = L.layerGroup().addTo(osmMap);
}

function updateMapMarkers(grievances) {
  markerLayerGroup.clearLayers();
  activeMarkers = [];

  const bounds = [];

  grievances.forEach((g) => {
    if (!g.latitude || !g.longitude) return;

    let markerColor = '#F59E0B'; // Amber default
    if (g.status === 'resolved') {
      markerColor = '#10B981'; // Emerald
    } else if (g.urgency === 'high' || g.isSlaBreached) {
      markerColor = '#EF4444'; // Crimson
    }

    // Custom SVG Marker Icon
    const customIcon = L.divIcon({
      className: 'custom-map-pin',
      html: `<div style="
        background: ${markerColor};
        width: 26px;
        height: 26px;
        border-radius: 50% 50% 50% 0;
        transform: rotate(-45deg);
        border: 2px solid white;
        box-shadow: 0 4px 10px rgba(0,0,0,0.5);
        display: flex;
        align-items: center;
        justify-content: center;
      ">
        <div style="width: 8px; height: 8px; background: white; border-radius: 50%;"></div>
      </div>`,
      iconSize: [26, 26],
      iconAnchor: [13, 26],
      popupAnchor: [0, -24]
    });

    const marker = L.marker([g.latitude, g.longitude], { icon: customIcon });

    const popupHtml = `
      <div class="popup-container">
        <h4>${g.id}</h4>
        <p><strong>Dept:</strong> ${formatCategory(g.departmentCategory)}</p>
        <p><strong>Citizen:</strong> ${escapeHtml(g.citizenName)} (${escapeHtml(g.spokenDialect)})</p>
        <p><strong>Issue:</strong> "${escapeHtml(g.rawSpeechText.slice(0, 80))}..."</p>
        <p><strong>Location:</strong> ${escapeHtml(g.villageWard)}, ${escapeHtml(g.district)}</p>
        <p><strong>Status:</strong> <span class="status-badge status-${g.status}">${g.status}</span></p>
        <p><strong>SLA:</strong> ${g.isSlaBreached ? '⚠️ Breached' : g.remainingSlaHours + 'h remaining'}</p>
        <div style="margin-top: 8px; display: flex; gap: 6px;">
          <button onclick="window.viewGrievanceDetail('${g.id}')" style="background:#2563EB; color:white; border:none; padding:4px 8px; border-radius:4px; font-size:11px; cursor:pointer;">
            Audit Trail
          </button>
          ${g.status !== 'resolved' ? `
            <button onclick="window.quickResolve('${g.id}')" style="background:#10B981; color:white; border:none; padding:4px 8px; border-radius:4px; font-size:11px; cursor:pointer;">
              Resolve
            </button>
          ` : ''}
        </div>
      </div>
    `;

    marker.bindPopup(popupHtml);
    markerLayerGroup.addLayer(marker);
    activeMarkers.push(marker);
    bounds.push([g.latitude, g.longitude]);
  });

  if (bounds.length > 0) {
    osmMap.fitBounds(bounds, { padding: [40, 40], maxZoom: 13 });
  }
}

// ==========================================================================
// 2. Data Loading & Stats
// ==========================================================================
async function loadSystemHealth() {
  try {
    const res = await fetch('/api/health');
    const data = await res.json();
    if (data.status === 'healthy') {
      document.getElementById('ai-model-tag').textContent = `AI: ${data.aiModel}`;
      document.getElementById('db-mode-tag').textContent = `DB: ${data.databaseMode.toUpperCase()}`;
    }
  } catch (err) {
    console.warn('Health check error:', err);
  }
}

async function refreshData() {
  try {
    const [grievancesRes, statsRes] = await Promise.all([
      fetch('/api/grievances'),
      fetch('/api/grievances/stats')
    ]);

    const gData = await grievancesRes.json();
    const sData = await statsRes.json();

    if (gData.success) {
      allGrievances = gData.data;
      renderTable(allGrievances);
      updateMapMarkers(allGrievances);
    }

    if (sData.success) {
      const stats = sData.data;
      document.getElementById('stat-total').textContent = stats.totalGrievances;
      document.getElementById('stat-resolved').textContent = stats.resolvedCount;
      document.getElementById('stat-review').textContent = stats.activeUnderReview;
      document.getElementById('stat-escalated').textContent = stats.slaBreachedCount;
      document.getElementById('stat-resolution-rate').textContent = `${stats.resolutionRatePercentage}% Resolution Rate`;
    }
  } catch (err) {
    showToast('Failed to load grievances data: ' + err.message, 'error');
  }
}

// ==========================================================================
// 3. Table Rendering
// ==========================================================================
function renderTable(grievances) {
  const tbody = document.getElementById('table-body');
  if (!grievances || grievances.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" class="text-center py-4 text-muted">No grievances found matching the filters.</td></tr>`;
    return;
  }

  tbody.innerHTML = grievances.map((g) => {
    const isBreached = g.isSlaBreached;
    const slaText = g.status === 'resolved'
      ? '<span class="sla-badge ok">Resolved Closed</span>'
      : isBreached
        ? '<span class="sla-badge breached">⚠️ Breached</span>'
        : `<span class="sla-badge ok">${g.remainingSlaHours}h remaining</span>`;

    return `
      <tr>
        <td>
          <a href="javascript:void(0)" onclick="window.viewGrievanceDetail('${g.id}')" class="ticket-code">
            ${g.id}
          </a>
        </td>
        <td>
          <div style="font-weight:600;">${escapeHtml(g.citizenName)}</div>
          <div class="dialect-tag">${escapeHtml(g.spokenDialect)} &bull; ${escapeHtml(g.citizenPhone)}</div>
        </td>
        <td>
          <div class="dept-badge">${formatCategory(g.departmentCategory)}</div>
          <div class="issue-snippet" title="${escapeHtml(g.rawSpeechText)}">${escapeHtml(g.rawSpeechText)}</div>
        </td>
        <td>
          <div>${escapeHtml(g.villageWard)}</div>
          <div class="dialect-tag">${escapeHtml(g.district)}, ${escapeHtml(g.state)}</div>
        </td>
        <td>
          <span class="status-badge" style="background:${g.urgency === 'high' ? 'rgba(239,68,68,0.2)' : 'rgba(245,158,11,0.2)'}; color:${g.urgency === 'high' ? '#F87171' : '#FBBF24'};">
            ${g.urgency.toUpperCase()}
          </span>
        </td>
        <td>
          <span class="status-badge status-${g.status}">${formatStatus(g.status)}</span>
        </td>
        <td>${slaText}</td>
        <td>
          <div style="display:flex; gap:6px;">
            <button class="btn btn-ghost btn-sm" onclick="window.viewGrievanceDetail('${g.id}')" title="Audit Trail">
              <i class="bi bi-clock-history"></i>
            </button>
            ${g.status !== 'resolved' ? `
              <button class="btn btn-ghost btn-sm" style="color:#10B981;" onclick="window.quickResolve('${g.id}')" title="Mark Resolved">
                <i class="bi bi-check-lg"></i>
              </button>
              <button class="btn btn-ghost btn-sm" style="color:#EF4444;" onclick="window.quickEscalate('${g.id}')" title="Escalate to SDM">
                <i class="bi bi-arrow-up-right-circle"></i>
              </button>
            ` : ''}
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

// ==========================================================================
// 4. Gemma / Gemini AI Playground
// ==========================================================================
async function classifyWithAI() {
  const textarea = document.getElementById('ai-input-text');
  const text = textarea.value.trim();
  if (!text) {
    showToast('Please type or select a sample grievance description first', 'warning');
    return;
  }

  const btn = document.getElementById('btn-classify-ai');
  const originalText = btn.innerHTML;
  btn.innerHTML = `<i class="bi bi-arrow-repeat spin"></i> Analyzing with Gemma AI...`;
  btn.disabled = true;

  try {
    const res = await fetch('/api/ai/classify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text,
        locationHint: { district: 'Ahmedabad', state: 'Gujarat' }
      })
    });

    const result = await res.json();
    if (!result.success) throw new Error(result.message);

    const data = result.data;
    currentAiDraft = {
      rawSpeechText: text,
      problemTitle: data.problemTitle,
      departmentCategory: data.departmentCategory,
      urgency: data.urgency,
      spokenDialect: data.spokenDialect,
      translatedText: data.translatedText,
      villageWard: data.extractedLocation?.villageWard || 'Local Ward',
      block: data.extractedLocation?.block || 'Local Block',
      district: data.extractedLocation?.district || 'Ahmedabad',
      state: data.extractedLocation?.state || 'Gujarat',
      latitude: 22.9868,
      longitude: 72.3812
    };

    // Render result card
    document.getElementById('result-dept-name').textContent = formatCategory(data.departmentCategory);
    document.getElementById('result-urgency-tag').textContent = data.urgency.toUpperCase() + ' URGENCY';
    document.getElementById('result-confidence').textContent = Math.round(data.confidenceScore * 100) + '%';
    document.getElementById('result-dialect').textContent = data.spokenDialect;
    document.getElementById('result-sla').textContent = data.urgency === 'high' ? '24 Hours' : '48 Hours';
    document.getElementById('result-location').textContent = `${currentAiDraft.villageWard}, ${currentAiDraft.district}`;
    document.getElementById('result-translated').textContent = data.translatedText;

    document.getElementById('ai-result-card').style.display = 'block';
    showToast('Gemma AI analysis complete & auto-routed!', 'success');
  } catch (err) {
    showToast('AI classification error: ' + err.message, 'error');
  } finally {
    btn.innerHTML = originalText;
    btn.disabled = false;
  }
}

async function confirmLodgeFromAi() {
  if (!currentAiDraft) return;

  const btn = document.getElementById('btn-confirm-lodge-ai');
  btn.disabled = true;

  try {
    const res = await fetch('/api/grievances', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...currentAiDraft,
        citizenName: 'Nagarik via Web AI',
        citizenPhone: '+91 98250 ' + Math.floor(10000 + Math.random() * 90000)
      })
    });

    const result = await res.json();
    if (!result.success) throw new Error(result.message);

    showToast(`🎉 Complaint registered: ${result.data.id}`, 'success');
    document.getElementById('ai-result-card').style.display = 'none';
    document.getElementById('ai-input-text').value = '';
    currentAiDraft = null;
    await refreshData();
  } catch (err) {
    showToast('Failed to lodge grievance: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
  }
}

// ==========================================================================
// 5. OpenStreetMap Hotspots & Reverse Geocode
// ==========================================================================
async function detectHotspots() {
  try {
    const res = await fetch('/api/maps/hotspots?radiusKm=1.5');
    const result = await res.json();

    if (result.success && result.data.length > 0) {
      const summary = result.data.map(h => `${formatCategory(h.departmentCategory)} (${h.complaintCount} reports)`).join('; ');
      document.getElementById('active-hotspot-summary').innerHTML = `🔥 <strong>Hotspots Detected:</strong> ${summary}`;
      showToast(`Detected ${result.data.length} recurring complaint clusters on OpenStreetMap!`, 'warning');
    } else {
      document.getElementById('active-hotspot-summary').textContent = 'No critical hotspots detected within 1.5km radius.';
      showToast('No active hotspots found nearby.', 'info');
    }
  } catch (err) {
    showToast('Hotspot detection error: ' + err.message, 'error');
  }
}

// ==========================================================================
// 6. Action Handlers (View Detail, Quick Resolve, Quick Escalate)
// ==========================================================================
window.viewGrievanceDetail = async function (id) {
  try {
    const res = await fetch(`/api/grievances/${id}`);
    const result = await res.json();
    if (!result.success) throw new Error(result.message);

    const g = result.data;
    document.getElementById('modal-ticket-id').textContent = g.id;
    document.getElementById('modal-status-badge').textContent = formatStatus(g.status);
    document.getElementById('modal-status-badge').className = `status-badge status-${g.status}`;

    const timelineHtml = (g.auditLog || []).map(step => `
      <div class="timeline-item">
        <div class="timeline-dot"></div>
        <div class="timeline-header">${escapeHtml(step.statusLabel)} &bull; <span class="timeline-time">${new Date(step.timestamp).toLocaleString()}</span></div>
        <div class="timeline-desc"><strong>Actor:</strong> ${escapeHtml(step.actor)}</div>
        <div class="timeline-desc">${escapeHtml(step.description)}</div>
      </div>
    `).join('');

    document.getElementById('modal-detail-body').innerHTML = `
      <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1.25rem;">
        <div>
          <div class="text-dim">Citizen Name</div>
          <div style="font-weight:600;">${escapeHtml(g.citizenName)} (${escapeHtml(g.citizenPhone)})</div>
        </div>
        <div>
          <div class="text-dim">Department & Urgency</div>
          <div style="font-weight:600;">${formatCategory(g.departmentCategory)} &bull; ${g.urgency.toUpperCase()}</div>
        </div>
        <div>
          <div class="text-dim">Location (OpenStreetMap)</div>
          <div>${escapeHtml(g.villageWard)}, ${escapeHtml(g.district)}, ${escapeHtml(g.state)}</div>
          <div class="text-dim" style="font-size:11px;">GPS: ${g.latitude.toFixed(4)}, ${g.longitude.toFixed(4)}</div>
        </div>
        <div>
          <div class="text-dim">SLA Expiry Target</div>
          <div>${new Date(g.dueDate).toLocaleString()} (${g.isSlaBreached ? '⚠️ BREACHED' : g.remainingSlaHours + 'h left'})</div>
        </div>
      </div>

      <div style="background: rgba(0,0,0,0.3); padding: 0.85rem; border-radius: 8px; margin-bottom: 1.25rem;">
        <div class="text-dim" style="font-size:11px; margin-bottom: 4px;">RAW CITIZEN COMPLAINT (${escapeHtml(g.spokenDialect)}):</div>
        <div style="font-style:italic;">"${escapeHtml(g.rawSpeechText)}"</div>
        <div class="text-dim" style="font-size:11px; margin: 8px 0 4px;">STANDARDIZED TRANSLATION:</div>
        <div>"${escapeHtml(g.translatedText)}"</div>
      </div>

      <h4><i class="bi bi-clock-history"></i> Official Redressal Audit Trail</h4>
      <div class="audit-timeline">
        ${timelineHtml}
      </div>
    `;

    document.getElementById('detail-modal').style.display = 'flex';
  } catch (err) {
    showToast('Failed to load grievance details: ' + err.message, 'error');
  }
};

window.quickResolve = async function (id) {
  const note = prompt('Enter official closure note for citizen:', 'Field team verified and resolved the issue on site.');
  if (note === null) return;

  try {
    const res = await fetch(`/api/grievances/${id}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        status: 'resolved',
        note,
        actor: 'Municipal Executive Officer'
      })
    });

    const result = await res.json();
    if (!result.success) throw new Error(result.message);

    showToast(`Complaint ${id} marked as Resolved!`, 'success');
    await refreshData();
  } catch (err) {
    showToast('Failed to resolve complaint: ' + err.message, 'error');
  }
};

window.quickEscalate = async function (id) {
  if (!confirm(`Are you sure you want to escalate ticket ${id} to District Magistrate due to SLA breach?`)) return;

  try {
    const res = await fetch(`/api/grievances/${id}/escalate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        reason: 'SLA timer exceeded by nodal authority. Auto-escalated to Level 1.',
        actor: 'District SLA Sentinel'
      })
    });

    const result = await res.json();
    if (!result.success) throw new Error(result.message);

    showToast(`Complaint ${id} escalated to Higher Authority!`, 'warning');
    await refreshData();
  } catch (err) {
    showToast('Failed to escalate: ' + err.message, 'error');
  }
};

// ==========================================================================
// 7. Event Listeners & Modals
// ==========================================================================
function setupEventListeners() {
  // Classify button
  document.getElementById('btn-classify-ai').addEventListener('click', classifyWithAI);

  // Confirm lodge button
  document.getElementById('btn-confirm-lodge-ai').addEventListener('click', confirmLodgeFromAi);

  // Hotspot detect button
  document.getElementById('btn-detect-hotspots').addEventListener('click', detectHotspots);

  // Sample chips
  document.querySelectorAll('.sample-chips-row .chip').forEach(btn => {
    btn.addEventListener('click', () => {
      const sampleKey = btn.dataset.sample;
      if (SAMPLES[sampleKey]) {
        document.getElementById('ai-input-text').value = SAMPLES[sampleKey];
      }
    });
  });

  // Table filter search
  document.getElementById('filter-search').addEventListener('input', applyFilters);
  document.getElementById('filter-department').addEventListener('change', applyFilters);
  document.getElementById('filter-status').addEventListener('change', applyFilters);
  document.getElementById('btn-refresh-table').addEventListener('click', refreshData);

  // Modal open/close
  document.getElementById('btn-quick-lodge').addEventListener('click', () => {
    document.getElementById('lodge-modal').style.display = 'flex';
  });
  document.getElementById('btn-close-lodge-modal').addEventListener('click', () => {
    document.getElementById('lodge-modal').style.display = 'none';
  });
  document.getElementById('btn-cancel-lodge').addEventListener('click', () => {
    document.getElementById('lodge-modal').style.display = 'none';
  });

  document.getElementById('btn-close-detail-modal').addEventListener('click', () => {
    document.getElementById('detail-modal').style.display = 'none';
  });

  document.getElementById('btn-open-api-docs').addEventListener('click', () => {
    document.getElementById('api-modal').style.display = 'flex';
  });
  document.getElementById('btn-close-api-modal').addEventListener('click', () => {
    document.getElementById('api-modal').style.display = 'none';
  });

  // GPS Detection button in Lodge Modal
  document.getElementById('btn-detect-gps').addEventListener('click', detectDeviceGPS);

  // Submit Lodge Form
  document.getElementById('lodge-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = document.getElementById('btn-submit-lodge');
    btn.disabled = true;

    try {
      const payload = {
        citizenName: document.getElementById('form-citizen-name').value,
        citizenPhone: document.getElementById('form-citizen-phone').value,
        rawSpeechText: document.getElementById('form-speech-text').value,
        departmentCategory: document.getElementById('form-category').value || undefined,
        urgency: document.getElementById('form-urgency').value,
        latitude: parseFloat(document.getElementById('form-lat').value) || 23.0225,
        longitude: parseFloat(document.getElementById('form-lon').value) || 72.5714
      };

      const res = await fetch('/api/grievances', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const result = await res.json();
      if (!result.success) throw new Error(result.message);

      showToast(`Complaint lodged successfully: ${result.data.id}`, 'success');
      document.getElementById('lodge-modal').style.display = 'none';
      document.getElementById('lodge-form').reset();
      await refreshData();
    } catch (err) {
      showToast('Error lodging grievance: ' + err.message, 'error');
    } finally {
      btn.disabled = false;
    }
  });
}

function detectDeviceGPS() {
  const addrSpan = document.getElementById('osm-detected-addr');
  if ('geolocation' in navigator) {
    addrSpan.textContent = 'Fetching device GPS coordinates...';
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const lat = pos.coords.latitude;
        const lon = pos.coords.longitude;
        document.getElementById('form-lat').value = lat.toFixed(4);
        document.getElementById('form-lon').value = lon.toFixed(4);

        // Reverse geocode via OpenStreetMap Nominatim
        try {
          const res = await fetch(`/api/maps/reverse-geocode?lat=${lat}&lng=${lon}`);
          const geoData = await res.json();
          if (geoData.success) {
            addrSpan.textContent = `📍 ${geoData.data.villageWard}, ${geoData.data.district}, ${geoData.data.state}`;
          }
        } catch {
          addrSpan.textContent = `GPS: ${lat.toFixed(4)}, ${lon.toFixed(4)}`;
        }
      },
      (err) => {
        addrSpan.textContent = 'GPS permission denied. Using default coordinates.';
      }
    );
  }
}

function applyFilters() {
  const search = document.getElementById('filter-search').value.toLowerCase();
  const dept = document.getElementById('filter-department').value;
  const status = document.getElementById('filter-status').value;

  const filtered = allGrievances.filter(g => {
    const matchesSearch = !search ||
      g.id.toLowerCase().includes(search) ||
      g.citizenName.toLowerCase().includes(search) ||
      g.rawSpeechText.toLowerCase().includes(search) ||
      g.villageWard.toLowerCase().includes(search) ||
      g.district.toLowerCase().includes(search);

    const matchesDept = !dept || g.departmentCategory === dept;
    const matchesStatus = !status || g.status === status;

    return matchesSearch && matchesDept && matchesStatus;
  });

  renderTable(filtered);
  updateMapMarkers(filtered);
}

// ==========================================================================
// 8. Helper Functions
// ==========================================================================
function formatCategory(cat) {
  const names = {
    waterSupply: '💧 Drinking Water (PHED)',
    electricity: '⚡ Electricity (DISCOM)',
    roadsInfrastructure: '🛣️ Roads & PWD',
    sanitationHealth: '🗑️ Sanitation & Health',
    pdsRation: '🌾 PDS Ration',
    pensionsWelfare: '👵 Pensions & Welfare',
    policeLawOrder: '👮 Police & Safety',
    generalPanchayat: '🏛️ Panchayat'
  };
  return names[cat] || cat;
}

function formatStatus(status) {
  const map = {
    received: 'Received',
    underReview: 'Under Review',
    inProgress: 'In Progress',
    resolved: 'Resolved',
    escalated: 'SLA Breached',
    hitlReview: 'HITL Review'
  };
  return map[status] || status;
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<i class="bi bi-info-circle-fill"></i> ${escapeHtml(message)}`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}
