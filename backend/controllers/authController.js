const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

// Register a new user (Police or Survey)
const register = async (req, res) => {
  const { name, email, password, role } = req.body;
  console.log(`[AUTH] Register request received for email: ${email}, role: ${role}`);
  
  if (!['POLICE', 'SURVEY'].includes(role)) {
    console.warn(`[AUTH] Registration failed: Invalid role provided (${role})`);
    return res.status(400).json({ message: 'Invalid role' });
  }

  try {
    const existingUser = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      console.log(`[AUTH] Registration failed: User with email ${email} already exists.`);
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password before saving
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await db.query(
      'INSERT INTO users (name, email, password, role) VALUES ($1, $2, $3, $4) RETURNING id, name, email, role',
      [name, email, hashedPassword, role]
    );

    console.log(`[AUTH] User registered successfully with ID: ${result.rows[0].id}`);
    res.status(201).json({ user: result.rows[0] });
  } catch (error) {
    console.error(`[AUTH] Server ERROR during registration:`, error);
    res.status(500).json({ message: 'Server error during registration', error: error.message });
  }
};

// Login standard action
const login = async (req, res) => {
  const { email, password } = req.body;
  console.log(`[AUTH] Login attempt for email: ${email}`);

  try {
    // Find user in postgres
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      console.warn(`[AUTH] Login failed: No user found with email ${email}`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const user = result.rows[0];
    
    // Compare provided password with hashed password stored in DB
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      console.warn(`[AUTH] Login failed: Incorrect password for user ${email}`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Sign a JSON Web Token
    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    console.log(`[AUTH] Login successful for user ${email}`);
    res.status(200).json({
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role }
    });
  } catch (error) {
    console.error(`[AUTH] Server ERROR during login:`, error);
    res.status(500).json({ message: 'Server error during login', error: error.message });
  }
};

module.exports = { register, login };
