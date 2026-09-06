const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const cameraRoutes = require('./routes/cameraRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();

// 100% Fail-safe CORS middleware for Chrome / Flutter Web preflight
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.status(200).send();
  }
  next();
});

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/cameras', cameraRoutes);
app.use('/api/users', userRoutes);

// Health & DB check
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'VisionTrack API running' });
});

app.get('/api/db-status', async (req, res) => {
  try {
    const db = require('./config/db');
    const users = await db.query('SELECT id, name, email, role, created_at FROM users');
    const cameras = await db.query('SELECT * FROM cameras');
    res.status(200).json({
      database: 'cctv_app_db',
      usersCount: users.rows.length,
      users: users.rows,
      camerasCount: cameras.rows.length,
      cameras: cameras.rows,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = app;
