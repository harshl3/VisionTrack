const db = require('./config/db');

const initDb = async () => {
  const usersTable = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL, -- POLICE, SURVEY
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const camerasTable = `
    CREATE TABLE IF NOT EXISTS cameras (
      id SERIAL PRIMARY KEY,
      owner_name VARCHAR(100),
      contact_details VARCHAR(100),
      type VARCHAR(50), -- GOVT, PRIVATE
      latitude NUMERIC(10, 6) NOT NULL,
      longitude NUMERIC(10, 6) NOT NULL,
      direction NUMERIC(5, 2), -- Degrees 0-360
      coverage_range NUMERIC(5, 2), -- In meters
      image_url TEXT,
      status VARCHAR(50) DEFAULT 'ACTIVE',
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  try {
    await db.query(usersTable);
    console.log('Users table created or exists.');

    await db.query(camerasTable);
    console.log('Cameras table created or exists.');
    
    // Seed Admins
    const bcrypt = require('bcrypt');
    const admins = [
      { email: 'admin1@gmail.com', password: 'admin1', name: 'Admin One' },
      { email: 'admin2@gmail.com', password: 'admin2', name: 'Admin Two' },
      { email: 'admin3@gmail.com', password: 'admin3', name: 'Admin Three' }
    ];

    for (let admin of admins) {
      const hashedPass = await bcrypt.hash(admin.password, 10);
      await db.query(`
        INSERT INTO users (name, email, password, role) 
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (email) DO UPDATE 
        SET password = EXCLUDED.password
      `, [admin.name, admin.email, hashedPass, 'POLICE']);
      console.log(`[SUCCESS] Seeded/Updated admin account: ${admin.email}`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
};

initDb();
