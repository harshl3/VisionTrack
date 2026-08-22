const PLACEHOLDER_MARKERS = [
  'your_postgres_user',
  'your_postgres_password',
  'your_super_secret_jwt_key',
];

function validateDatabaseEnv() {
  require('dotenv').config();

  const missing = [];
  if (!process.env.DB_HOST) missing.push('DB_HOST');
  if (!process.env.DB_PORT) missing.push('DB_PORT');
  if (!process.env.DB_USER) missing.push('DB_USER');
  if (!process.env.DB_PASSWORD) missing.push('DB_PASSWORD');
  if (!process.env.DB_NAME) missing.push('DB_NAME');
  if (!process.env.JWT_SECRET) missing.push('JWT_SECRET');

  if (missing.length > 0) {
    console.error(
      `\nMissing in backend/.env: ${missing.join(', ')}\n` +
        'Copy backend/.env.example to backend/.env and fill in your PostgreSQL details.\n',
    );
    return;
  }

  const stillPlaceholder = PLACEHOLDER_MARKERS.some((marker) => {
    return (
      process.env.DB_USER === marker ||
      process.env.DB_PASSWORD === marker ||
      process.env.JWT_SECRET === marker
    );
  });

  if (stillPlaceholder) {
    console.error(`
PostgreSQL is not configured yet — backend/.env still has template values.

Quick fix (recommended):
  cd backend
  npm run setup
  (enter the password for PostgreSQL user "postgres")

Or edit backend/.env manually:
  DB_USER=postgres
  DB_PASSWORD=<your PostgreSQL password>
  DB_NAME=postgres
  JWT_SECRET=<any long random string>

Then run:
  node initDb.js
  npm run dev

Forgot postgres password? Use pgAdmin 4 → Servers → PostgreSQL 18 → Login/Group Roles → postgres → Properties → Definition.
`);
    return;
  }
}

module.exports = { validateDatabaseEnv };
