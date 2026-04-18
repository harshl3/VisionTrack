const db = require('../config/db');

// Adds a new camera to the database
const addCamera = async (req, res) => {
  const {
    owner_name, contact_details, type,
    latitude, longitude, direction, coverage_range, image_url
  } = req.body;

  console.log(`[CAMERA] Adding new ${type} camera by user ID: ${req.user.id}`);

  try {
    const result = await db.query(
      `INSERT INTO cameras 
      (owner_name, contact_details, type, latitude, longitude, direction, coverage_range, image_url, created_by) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [owner_name, contact_details, type, latitude, longitude, direction, coverage_range, image_url, req.user.id]
    );

    console.log(`[CAMERA] Camera successfully inserted with ID: ${result.rows[0].id}`);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('[CAMERA] ERROR inserting new camera:', error);
    res.status(500).json({ message: 'Error adding camera', error: error.message });
  }
};

// Gets all registered cameras for the Map View
const getCameras = async (req, res) => {
  console.log(`[CAMERA] Fetching all cameras for user ID: ${req.user.id} (${req.user.role})`);
  try {
    const result = await db.query('SELECT * FROM cameras');
    console.log(`[CAMERA] Fetched ${result.rows.length} cameras successfully.`);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('[CAMERA] ERROR fetching cameras:', error);
    res.status(500).json({ message: 'Error fetching cameras', error: error.message });
  }
};

// Get a single camera by ID
const getCameraById = async (req, res) => {
  const cameraId = req.params.id;
  console.log(`[CAMERA] Fetching stats for Camera ID: ${cameraId}`);
  
  try {
    const result = await db.query('SELECT * FROM cameras WHERE id = $1', [cameraId]);
    if (result.rows.length === 0) {
      console.warn(`[CAMERA] Camera not found for ID: ${cameraId}`);
      return res.status(404).json({ message: 'Camera not found' });
    }
    
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error(`[CAMERA] ERROR fetching camera ${cameraId}:`, error);
    res.status(500).json({ message: 'Error fetching camera detail', error: error.message });
  }
};

module.exports = { addCamera, getCameras, getCameraById };
