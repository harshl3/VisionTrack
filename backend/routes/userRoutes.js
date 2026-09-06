const express = require('express');
const { deleteSurveyor } = require('../controllers/userController');
const { authMiddleware, roleMiddleware } = require('../middlewares/authMiddleware');

const router = express.Router();

// DELETE /api/users/:id — Police Admin only
router.delete('/:id', authMiddleware, roleMiddleware(['POLICE']), deleteSurveyor);

module.exports = router;
