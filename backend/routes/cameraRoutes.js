const express = require('express');
const { addCamera, getCameras, getCameraById } = require('../controllers/cameraController');
const { authMiddleware, roleMiddleware } = require('../middlewares/authMiddleware');

const router = express.Router();

// Get all cameras (Requires Auth)
router.get('/', authMiddleware, getCameras);

// Get single camera (Requires Auth)
router.get('/:id', authMiddleware, getCameraById);

// Add camera (Requires Auth, any role can add. If only survey allowed, add roleMiddleware)
router.post('/', authMiddleware, addCamera);

module.exports = router;
