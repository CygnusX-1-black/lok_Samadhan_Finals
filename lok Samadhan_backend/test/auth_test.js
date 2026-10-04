const http = require('http');

function postJson(path, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function getJson(path, token = null) {
  return new Promise((resolve, reject) => {
    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const req = http.request({
      hostname: 'localhost',
      port: 5000,
      path,
      method: 'GET',
      headers
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  console.log('--- 1. Testing Google OAuth URL ---');
  const googleRes = await getJson('/api/auth/google-url?redirectTo=http://localhost:8088');
  console.log('Google URL status:', googleRes.status, 'url starts with:', googleRes.data?.data?.url?.slice(0, 50));

  console.log('\n--- 2. Testing Register Citizen (Supabase) ---');
  const testEmail = `srijan_${Date.now()}@lok-samadhan.gov.in`;
  const regRes = await postJson('/api/auth/register', {
    fullName: 'Srijan Verma',
    email: testEmail,
    password: 'Password@12345!'
  });
  console.log('Register status:', regRes.status, 'success:', regRes.data?.success, 'user:', regRes.data?.data?.user?.name, 'provider:', regRes.data?.data?.user?.provider);
  const token = regRes.data?.data?.token;

  console.log('\n--- 3. Testing Login Citizen (Supabase) ---');
  const loginRes = await postJson('/api/auth/login', {
    email: testEmail,
    password: 'Password@12345!'
  });
  console.log('Login status:', loginRes.status, 'success:', loginRes.data?.success, 'token length:', loginRes.data?.data?.token?.length);

  console.log('\n--- 4. Testing GET /api/auth/me ---');
  if (token) {
    const meRes = await getJson('/api/auth/me', token);
    console.log('Me status:', meRes.status, 'user:', meRes.data?.data?.user?.name, 'email:', meRes.data?.data?.user?.email);
  }

  console.log('\n--- 5. Testing Forgot Password ---');
  const forgotRes = await postJson('/api/auth/forgot-password', { email: testEmail });
  console.log('Forgot status:', forgotRes.status, 'success:', forgotRes.data?.success);

  console.log('\n--- 6. Testing Demo Accounts ---');
  const demoRes = await getJson('/api/auth/demo-accounts');
  console.log('Demo accounts count:', demoRes.data?.data?.length);

  console.log('\nAll auth tests finished!');
}

run().catch(console.error);
