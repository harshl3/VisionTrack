const { validateDatabaseEnv } = require('./config/validateEnv');
validateDatabaseEnv();

const db = require('./config/db');

const initDb = async () => {
  const usersTable = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL,
      role VARCHAR(50) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const camerasTable = `
    CREATE TABLE IF NOT EXISTS cameras (
      id SERIAL PRIMARY KEY,
      serial_number VARCHAR(100) UNIQUE,
      owner_name VARCHAR(100) NOT NULL,
      contact_number VARCHAR(20) NOT NULL,
      camera_name VARCHAR(100),
      camera_type VARCHAR(50),
      camera_brand VARCHAR(100),
      latitude DOUBLE PRECISION NOT NULL,
      longitude DOUBLE PRECISION NOT NULL,
      azimuth_angle DOUBLE PRECISION NOT NULL,
      camera_range DOUBLE PRECISION NOT NULL,
      installation_date DATE,
      notes TEXT,
      status VARCHAR(50) DEFAULT 'ACTIVE',
      created_by INTEGER REFERENCES users(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;

  const migrateCamerasTable = `
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'contact_details'
      ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'contact_number'
      ) THEN
        ALTER TABLE cameras RENAME COLUMN contact_details TO contact_number;
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'direction'
      ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'azimuth_angle'
      ) THEN
        ALTER TABLE cameras RENAME COLUMN direction TO azimuth_angle;
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'coverage_range'
      ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'camera_range'
      ) THEN
        ALTER TABLE cameras RENAME COLUMN coverage_range TO camera_range;
      END IF;

      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'type'
      ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'camera_type'
      ) THEN
        ALTER TABLE cameras RENAME COLUMN type TO camera_type;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'camera_name'
      ) THEN
        ALTER TABLE cameras ADD COLUMN camera_name VARCHAR(100);
      END IF;

      -- New columns migration
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'serial_number'
      ) THEN
        ALTER TABLE cameras ADD COLUMN serial_number VARCHAR(100);
        ALTER TABLE cameras ADD CONSTRAINT cameras_serial_number_unique UNIQUE (serial_number);
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'camera_brand'
      ) THEN
        ALTER TABLE cameras ADD COLUMN camera_brand VARCHAR(100);
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'installation_date'
      ) THEN
        ALTER TABLE cameras ADD COLUMN installation_date DATE;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'cameras' AND column_name = 'notes'
      ) THEN
        ALTER TABLE cameras ADD COLUMN notes TEXT;
      END IF;
    END $$;
  `;

  try {
    await db.query(usersTable);
    console.log('Users table created or exists.');

    await db.query(camerasTable);
    console.log('Cameras table created or exists.');

    await db.query(migrateCamerasTable);
    console.log('Cameras table migration applied.');

    const bcrypt = require('bcryptjs');
    const admins = [
      { email: 'admin1@gmail.com', password: 'admin1', name: 'Admin One' },
      { email: 'admin2@gmail.com', password: 'admin2', name: 'Admin Two' },
      { email: 'admin3@gmail.com', password: 'admin3', name: 'Admin Three' },
    ];

    for (const admin of admins) {
      const hashedPass = await bcrypt.hash(admin.password, 10);
      await db.query(
        `
        INSERT INTO users (name, email, password, role)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (email) DO UPDATE
        SET password = EXCLUDED.password
      `,
        [admin.name, admin.email, hashedPass, 'POLICE']
      );
      console.log(`[SUCCESS] Seeded/Updated admin account: ${admin.email}`);
    }
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
};

module.exports = initDb;

if (require.main === module) {
  initDb()
    .then(() => {
      console.log('Database initialization completed.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Error initializing database:', error);
      process.exit(1);
    });
}
