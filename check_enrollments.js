async function test() {
  try {
    const loginRes = await fetch('http://localhost:5000/api/v1/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'student@test.com', password: 'password123' })
    });
    const loginData = await loginRes.json();
    const token = loginData.data.tokens.accessToken;
    
    // Try multiple routes
    const routes = [
      '/api/v1/enrollments',
      '/api/v1/enrollments/me',
      '/api/v1/enrollments/my-enrollments'
    ];
    
    for (const route of routes) {
      console.log('Trying: ' + route);
      const res = await fetch('http://localhost:5000' + route, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.ok) {
        console.log('SUCCESS: ' + route);
        const data = await res.json();
        console.log(JSON.stringify(data).substring(0, 200));
      } else {
        console.log('FAILED: ' + res.status);
      }
    }
  } catch (err) {
    console.error(err);
  }
}

test();
