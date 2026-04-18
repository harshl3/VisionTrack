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
    
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
};

initDb();
