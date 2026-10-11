const http = require('http');
const app = require('../src/app');

let server;
const PORT = 5001; // Test port to avoid conflicts

function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, headers: res.headers, body: parsed });
        } catch {
          resolve({ status: res.statusCode, headers: res.headers, rawBody: body });
        }
      });
    });

    req.on('error', reject);

    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

async function runTests() {
  console.log('🧪 Starting Lok Samadhan Backend Automated Verification Tests...\n');

  server = app.listen(PORT, async () => {
    try {
      let passed = 0;
      let total = 0;

      const assert = (condition, name) => {
        total++;
        if (condition) {
          console.log(`  ✅ [PASS] ${name}`);
          passed++;
        } else {
          console.error(`  ❌ [FAIL] ${name}`);
        }
      };

      // 1. Health Check
      console.log('--- Test Suite 1: System Health & Info ---');
      const healthRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/health',
        method: 'GET'
      });
      assert(healthRes.status === 200, 'Health endpoint returns HTTP 200');
      assert(healthRes.body.status === 'healthy', 'Health status is "healthy"');
      assert(healthRes.body.deployment === 'DigitalOcean Ready', 'Deployment target is DigitalOcean Ready');

      // 2. Departments
      console.log('\n--- Test Suite 2: Civic Departments ---');
      const deptRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/departments',
        method: 'GET'
      });
      assert(deptRes.status === 200, 'GET /api/departments returns 200');
      assert(Array.isArray(deptRes.body.data) && deptRes.body.data.length === 8, 'Returns exactly 8 civic departments');

      // 3. AI Classification
      console.log('\n--- Test Suite 3: Gemma / Gemini AI Redressal Engine ---');
      const aiRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/ai/classify',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      }, {
        text: 'અમારા ગામમાં પીવાના પાણીની મુખ્ય પાઇપલાઇન તૂટી ગઈ છે'
      });
      assert(aiRes.status === 200, 'POST /api/ai/classify returns 200');
      assert(aiRes.body.data.departmentCategory === 'waterSupply', 'AI correctly routes Gujarati water issue to "waterSupply"');
      assert(aiRes.body.data.urgency === 'high' || aiRes.body.data.urgency === 'medium', 'AI predicts high or medium urgency');

      // 4. OpenStreetMap Reverse Geocode
      console.log('\n--- Test Suite 4: OpenStreetMap Nominatim Integration ---');
      const osmRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/maps/reverse-geocode?lat=22.9868&lng=72.3812',
        method: 'GET'
      });
      assert(osmRes.status === 200, 'GET /api/maps/reverse-geocode returns 200');
      assert(osmRes.body.data.latitude === 22.9868, 'Preserves latitude precision');

      // 5. Grievances Creation & SLA
      console.log('\n--- Test Suite 5: Grievance Lifecycle & SLA Management ---');
      const createRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/grievances',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      }, {
        citizenName: 'Dev Test User',
        citizenPhone: '+91 99999 88888',
        rawSpeechText: 'Streetlight pole wire snapped near school entrance',
        departmentCategory: 'electricity',
        urgency: 'high',
        latitude: 23.0225,
        longitude: 72.5714
      });
      assert(createRes.status === 201, 'POST /api/grievances creates grievance (HTTP 201)');
      const newTicketId = createRes.body.data.id;
      assert(newTicketId && newTicketId.startsWith('LS-'), 'Generated ticket ID follows LS-YYYY-XXXXX format');

      // 6. Grievance Status Update
      const updateRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: `/api/grievances/${newTicketId}/status`,
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' }
      }, {
        status: 'inProgress',
        note: 'Lineman squad dispatched with replacement fuse and crane.'
      });
      assert(updateRes.status === 200, 'PATCH /api/grievances/:id/status updates status to inProgress');

      // 7. GeoJSON Export
      console.log('\n--- Test Suite 6: OpenStreetMap GeoJSON FeatureCollection ---');
      const geoJsonRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/grievances/geojson',
        method: 'GET'
      });
      assert(geoJsonRes.status === 200, 'GET /api/grievances/geojson returns 200');
      assert(geoJsonRes.body.type === 'FeatureCollection', 'Output is standard GeoJSON FeatureCollection');
      assert(Array.isArray(geoJsonRes.body.features), 'Contains geo-features array');

      // 8. AI Image Verification & Authenticity Analysis Endpoint
      console.log('\n--- Test Suite 7: AI Image Verification & Authenticity Forensics ---');
      // Create minimal valid 1x1 JPEG buffer in base64
      const sampleJpegBase64 = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';
      
      const verifyRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/ai/verify-image',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      }, {
        imageBase64: sampleJpegBase64,
        mimeType: 'image/jpeg',
        description: 'Road damage inspection test'
      });
      assert(verifyRes.status === 200, 'POST /api/ai/verify-image returns HTTP 200');
      assert(verifyRes.body.data && verifyRes.body.data.civicDetection, 'Returns structured civicDetection result');
      assert(verifyRes.body.data && verifyRes.body.data.authenticityAnalysis, 'Returns structured authenticityAnalysis result');
      assert(verifyRes.body.data && verifyRes.body.data.verificationSummary, 'Returns overall verificationSummary');
      assert(
        verifyRes.body.data.authenticityAnalysis.status === 'UNAVAILABLE' ||
        verifyRes.body.data.authenticityAnalysis.status === 'LIKELY_AUTHENTIC' ||
        verifyRes.body.data.authenticityAnalysis.status === 'INCONCLUSIVE' ||
        verifyRes.body.data.authenticityAnalysis.status === 'SUSPICIOUS',
        'Authenticity analysis produces honest state (not fabricated certainty)'
      );

      // Test synthetic prompt chunk detection
      const fakePngBuffer = Buffer.concat([
        Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        Buffer.from('tEXtparameters\x00Steps: 20, Sampler: Euler, Model: Stable Diffusion v1.5, Prompt: A deep pothole on road\x00')
      ]);
      const fakePngRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: '/api/ai/verify-image',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      }, {
        imageBase64: fakePngBuffer.toString('base64'),
        mimeType: 'image/png'
      });
      assert(fakePngRes.status === 200, 'POST /api/ai/verify-image with synthetic PNG metadata returns 200');
      assert(
        fakePngRes.body.data.authenticityAnalysis.status === 'SUSPICIOUS',
        'Correctly flags synthetic/AI metadata markers as SUSPICIOUS'
      );
      assert(
        fakePngRes.body.data.authenticityAnalysis.stateLabel === 'Potentially AI-Generated or Manipulated',
        'State label matches "Potentially AI-Generated or Manipulated"'
      );

      // 9. Officer Flag Review Endpoint
      console.log('\n--- Test Suite 8: Officer Image Verification Review ---');
      const flagRes = await makeRequest({
        hostname: 'localhost',
        port: PORT,
        path: `/api/grievances/${newTicketId}/flag-review`,
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' }
      }, {
        verificationStatus: 'flagged_manual_review',
        note: 'Officer requested on-site field team verification for image authenticity.',
        officerName: 'Senior Nodal Officer'
      });
      assert(flagRes.status === 200, 'PATCH /api/grievances/:id/flag-review returns HTTP 200');
      assert(flagRes.body.data.imageVerificationStatus === 'flagged_manual_review', 'Image verification status updated to flagged_manual_review');
      assert(flagRes.body.data.isHitlFallback === true, 'Grievance marked for Human-in-the-Loop review');

      console.log(`\n======================================================`);
      console.log(`🎉 TEST SUMMARY: ${passed}/${total} Passed (${Math.round((passed / total) * 100)}%)`);
      console.log(`======================================================\n`);

      server.close();
      process.exit(passed === total ? 0 : 1);
    } catch (err) {
      console.error('Test execution failed with error:', err);
      if (server) server.close();
      process.exit(1);
    }
  });
}

runTests();
