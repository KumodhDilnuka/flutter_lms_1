const http = require('http');

const loginData = JSON.stringify({
  email: 'admin@test.com',
  password: 'password123'
});

const req = http.request({
  hostname: '127.0.0.1',
  port: 5000,
  path: '/api/v1/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
}, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      const token = parsed.data.accessToken || parsed.data.token;
      console.log('Token:', token ? 'Found' : 'Not found');
      
      // Fetch users
      http.get('http://127.0.0.1:5000/api/v1/users', { headers: { 'Authorization': 'Bearer ' + token } }, res2 => {
        let uData = '';
        res2.on('data', chunk => uData += chunk);
        res2.on('end', () => {
          console.log('Users response structure:');
          try {
            const parsedU = JSON.parse(uData);
            console.log(Object.keys(parsedU));
            if (parsedU.data) {
                console.log('Data keys:', Object.keys(parsedU.data));
                if(Array.isArray(parsedU.data)) console.log('Data is an array');
            }
          } catch(e) { console.log('UData:', uData.substring(0, 100)) }
        });
      });
      
      // Fetch admin courses
      http.get('http://127.0.0.1:5000/api/v1/admin/courses', { headers: { 'Authorization': 'Bearer ' + token } }, res3 => {
        let cData = '';
        res3.on('data', chunk => cData += chunk);
        res3.on('end', () => {
          console.log('Admin courses response structure:');
          try {
            const parsedC = JSON.parse(cData);
            console.log(Object.keys(parsedC));
            if (parsedC.data) {
                console.log('Data keys:', Object.keys(parsedC.data));
                if(Array.isArray(parsedC.data)) console.log('Data is an array');
            }
          } catch(e) { console.log('CData:', cData.substring(0, 100)) }
        });
      });
    } catch (e) {
      console.log('Login parse error', e);
      console.log('Raw:', data);
    }
  });
});

req.write(loginData);
req.end();
