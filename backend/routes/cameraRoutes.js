const express = require('express');
const {
  addCamera,
  getCameras,
  getCameraById,
  updateCamera,
  deleteCamera,
  getSurveyors,
} = require('../controllers/cameraController');
const { authMiddleware, roleMiddleware } = require('../middlewares/authMiddleware');

const router = express.Router();

router.get('/surveyors/list', authMiddleware, roleMiddleware(['POLICE']), getSurveyors);
router.get('/', authMiddleware, getCameras);
router.get('/:id', authMiddleware, getCameraById);
router.post('/add', authMiddleware, roleMiddleware(['SURVEY']), addCamera);
router.post('/', authMiddleware, roleMiddleware(['SURVEY']), addCamera);
router.put('/:id', authMiddleware, updateCamera);
router.delete('/:id', authMiddleware, deleteCamera);

module.exports = router;
