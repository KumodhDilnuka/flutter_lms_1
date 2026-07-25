async function test() {
  try {
    const fetch = require('node-fetch'); // wait, native fetch is available
  } catch (e) {}

  try {
    // Register
    const email = 'testuser' + Date.now() + '@test.com';
    const password = 'password123';
    
    let res = await fetch('http://localhost:5000/api/v1/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test User', email, password, role: 'STUDENT' })
    });
    
    if (res.status === 404) {
      res = await fetch('http://localhost:5000/api/v1/auth/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Test User', email, password, role: 'STUDENT' })
      });
    }

    let token = null;
    try {
      const data = await res.json();
      token = data.data.tokens.accessToken;
    } catch (e) {
      // maybe login is required
      const loginRes = await fetch('http://localhost:5000/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const loginData = await loginRes.json();
      token = loginData.data.tokens.accessToken;
    }

    console.log('Got token: ' + (!!token));

    // Test endpoint
    const routes = [
      '/api/v1/enrollments/my-enrollments',
      '/api/v1/enrollments/my-enrollments?page=1&limit=50',
      '/api/v1/enrollments/me',
      '/api/v1/users/me/enrollments'
    ];

    for (const r of routes) {
      console.log('\nTesting: ' + r);
      const er = await fetch('http://localhost:5000' + r, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const txt = await er.text();
      console.log('Status: ' + er.status);
      console.log(txt.substring(0, 300));
    }
  } catch (err) {
    console.error(err);
  }
}

test();
