const db = require('../config/db');

const validateCameraPayload = (body, requireAll = true) => {
  const {
    owner_name,
    contact_number,
    latitude,
    longitude,
    azimuth_angle,
    camera_range,
  } = body;

  const missing = [];
  if (requireAll || owner_name !== undefined) {
    if (!owner_name || String(owner_name).trim() === '') missing.push('owner_name');
  }
  if (requireAll || contact_number !== undefined) {
    if (!contact_number || String(contact_number).trim() === '') missing.push('contact_number');
  }
  if (requireAll || latitude !== undefined) {
    if (latitude === undefined || latitude === null || Number.isNaN(Number(latitude))) {
      missing.push('latitude');
    }
  }
  if (requireAll || longitude !== undefined) {
    if (longitude === undefined || longitude === null || Number.isNaN(Number(longitude))) {
      missing.push('longitude');
    }
  }
  if (requireAll || azimuth_angle !== undefined) {
    if (azimuth_angle === undefined || azimuth_angle === null || Number.isNaN(Number(azimuth_angle))) {
      missing.push('azimuth_angle');
    }
  }
  if (requireAll || camera_range !== undefined) {
    if (camera_range === undefined || camera_range === null || Number.isNaN(Number(camera_range))) {
      missing.push('camera_range');
    }
  }

  return missing;
};

const buildCameraQuery = (req) => {
  const {
    search,
    min_range,
    max_range,
    surveyor_id,
    from_date,
    to_date,
  } = req.query;

  let query = `
    SELECT c.*, u.name AS surveyor_name, u.email AS surveyor_email
    FROM cameras c
    LEFT JOIN users u ON c.created_by = u.id
    WHERE 1=1
  `;
  const params = [];
  let index = 1;

  if (req.user.role === 'SURVEY') {
    query += ` AND c.created_by = ${index++}`;
    params.push(req.user.id);
  }

  if (search) {
    query += ` AND (
      c.owner_name ILIKE ${index}
      OR c.camera_name ILIKE ${index}
      OR c.contact_number ILIKE ${index}
      OR c.serial_number ILIKE ${index}
      OR c.camera_brand ILIKE ${index}
    )`;
    params.push(`%${search}%`);
    index++;
  }

  if (min_range) {
    query += ` AND c.camera_range >= ${index++}`;
    params.push(Number(min_range));
  }

  if (max_range) {
    query += ` AND c.camera_range <= ${index++}`;
    params.push(Number(max_range));
  }

  if (surveyor_id && req.user.role === 'POLICE') {
    query += ` AND c.created_by = ${index++}`;
    params.push(Number(surveyor_id));
  }

  if (from_date) {
    query += ` AND c.created_at >= ${index++}`;
    params.push(from_date);
  }

  if (to_date) {
    query += ` AND c.created_at <= ${index++}`;
    params.push(to_date);
  }

  query += ' ORDER BY c.created_at DESC';
  return { query, params };
};

const addCamera = async (req, res) => {
  const missing = validateCameraPayload(req.body, true);
  if (missing.length > 0) {
    return res.status(400).json({ message: `Missing or invalid fields: ${missing.join(', ')}` });
  }

  const {
    owner_name,
    contact_number,
    camera_name,
    camera_type,
    camera_brand,
    serial_number,
    latitude,
    longitude,
    azimuth_angle,
    camera_range,
    installation_date,
    notes,
  } = req.body;

  try {
    // Check serial number uniqueness before insert
    if (serial_number && String(serial_number).trim() !== '') {
      const existingSerial = await db.query(
        'SELECT id FROM cameras WHERE serial_number = $1',
        [String(serial_number).trim()]
      );
      if (existingSerial.rows.length > 0) {
        return res.status(409).json({
          message: `Camera with serial number "${serial_number}" is already registered in the system. Each camera can only be added once.`,
        });
      }
    }

    const result = await db.query(
      `INSERT INTO cameras
      (serial_number, owner_name, contact_number, camera_name, camera_type, camera_brand,
       latitude, longitude, azimuth_angle, camera_range, installation_date, notes, created_by)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        serial_number ? String(serial_number).trim() : null,
        owner_name,
        contact_number,
        camera_name || owner_name,
        camera_type || 'STATIC',
        camera_brand || null,
        Number(latitude),
        Number(longitude),
        Number(azimuth_angle),
        Number(camera_range),
        installation_date || null,
        notes || null,
        req.user.id,
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('[CAMERA] ERROR inserting new camera:', error);
    if (error.code === '23505') {
      // Unique constraint violation
      return res.status(409).json({
        message: `Camera with serial number "${serial_number}" is already registered in the system.`,
      });
    }
    res.status(500).json({ message: 'Error adding camera', error: error.message });
  }
};

const getCameras = async (req, res) => {
  try {
    const { query, params } = buildCameraQuery(req);
    const result = await db.query(query, params);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('[CAMERA] ERROR fetching cameras:', error);
    res.status(500).json({ message: 'Error fetching cameras', error: error.message });
  }
};

const getCameraById = async (req, res) => {
  const cameraId = req.params.id;

  try {
    const result = await db.query(
      `SELECT c.*, u.name AS surveyor_name, u.email AS surveyor_email
       FROM cameras c
       LEFT JOIN users u ON c.created_by = u.id
       WHERE c.id = $1`,
      [cameraId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Camera not found' });
    }

    const camera = result.rows[0];
    if (req.user.role === 'SURVEY' && camera.created_by !== req.user.id) {
      return res.status(403).json({ message: 'Access denied.' });
    }

    res.status(200).json(camera);
  } catch (error) {
    console.error(`[CAMERA] ERROR fetching camera ${cameraId}:`, error);
    res.status(500).json({ message: 'Error fetching camera detail', error: error.message });
  }
};

const updateCamera = async (req, res) => {
  const cameraId = req.params.id;
  const missing = validateCameraPayload(req.body, false);
  if (missing.length > 0) {
    return res.status(400).json({ message: `Invalid fields: ${missing.join(', ')}` });
  }

  try {
    const existing = await db.query('SELECT * FROM cameras WHERE id = $1', [cameraId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ message: 'Camera not found' });
    }

    const camera = existing.rows[0];
    if (req.user.role === 'SURVEY' && camera.created_by !== req.user.id) {
      return res.status(403).json({ message: 'Access denied.' });
    }

    const fields = [
      'serial_number',
      'owner_name',
      'contact_number',
      'camera_name',
      'camera_type',
      'camera_brand',
      'latitude',
      'longitude',
      'azimuth_angle',
      'camera_range',
      'installation_date',
      'notes',
      'status',
    ];

    const updates = [];
    const values = [];
    let index = 1;

    for (const field of fields) {
      if (req.body[field] !== undefined) {
        updates.push(`${field} = ${index++}`);
        values.push(req.body[field]);
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({ message: 'No valid fields provided for update.' });
    }

    values.push(cameraId);
    const result = await db.query(
      `UPDATE cameras SET ${updates.join(', ')} WHERE id = ${index} RETURNING *`,
      values
    );

    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error(`[CAMERA] ERROR updating camera ${cameraId}:`, error);
    if (error.code === '23505') {
      return res.status(409).json({ message: 'Serial number already in use by another camera.' });
    }
    res.status(500).json({ message: 'Error updating camera', error: error.message });
  }
};

const deleteCamera = async (req, res) => {
  const cameraId = req.params.id;

  try {
    const existing = await db.query('SELECT * FROM cameras WHERE id = $1', [cameraId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ message: 'Camera not found' });
    }

    const camera = existing.rows[0];
    if (req.user.role === 'SURVEY' && camera.created_by !== req.user.id) {
      return res.status(403).json({ message: 'Access denied.' });
    }

    await db.query('DELETE FROM cameras WHERE id = $1', [cameraId]);
    res.status(200).json({ message: 'Camera deleted successfully' });
  } catch (error) {
    console.error(`[CAMERA] ERROR deleting camera ${cameraId}:`, error);
    res.status(500).json({ message: 'Error deleting camera', error: error.message });
  }
};

const getSurveyors = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, name, email FROM users WHERE role = 'SURVEY' ORDER BY name ASC`
    );
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('[CAMERA] ERROR fetching surveyors:', error);
    res.status(500).json({ message: 'Error fetching surveyors', error: error.message });
  }
};

module.exports = {
  addCamera,
  getCameras,
  getCameraById,
  updateCamera,
  deleteCamera,
  getSurveyors,
};


