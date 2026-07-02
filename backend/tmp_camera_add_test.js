const dotenv = require('dotenv');
dotenv.config();

const base = 'http://127.0.0.1:3000';

(async () => {
  try {
    const registerPayload = {
      name: 'Temp Surveyor',
      email: 'temp-surveyor@example.com',
      password: 'TempPass123',
    };

    let res = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(registerPayload),
    });
    console.log('register status', res.status);
    console.log(await res.text());

    res = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: registerPayload.email, password: registerPayload.password }),
    });
    const loginText = await res.text();
    console.log('login status', res.status, loginText);
    if (res.status !== 200) return;

    const token = JSON.parse(loginText).token;
    const cam = {
      owner_name: 'Test Owner',
      contact_number: '9999999999',
      camera_name: 'private',
      camera_type: 'STATIC',
      latitude: 37.421998,
      longitude: -122.084,
      azimuth_angle: 30,
      camera_range: 40,
    };

    res = await fetch(`${base}/api/cameras/add`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(cam),
    });

    console.log('add status', res.status);
    console.log(await res.text());
  } catch (err) {
    console.error(err);
  }
})();
