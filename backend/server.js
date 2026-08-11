const { validateDatabaseEnv } = require('./config/validateEnv');
validateDatabaseEnv();

const app = require('./app');
const initDb = require('./initDb');

const PORT = process.env.PORT || 3000;

initDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Database init failed:', error);
    process.exit(1);
  });
