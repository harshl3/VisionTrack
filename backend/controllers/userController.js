const db = require('../config/db');

// Delete a surveyor account (admin-only, cannot delete POLICE roles)
const deleteSurveyor = async (req, res) => {
  const userId = req.params.id;

  try {
    const existing = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = existing.rows[0];

    // Cannot delete a POLICE admin
    if (user.role === 'POLICE') {
      return res.status(403).json({ message: 'Cannot delete a Police Admin account.' });
    }

    // Cannot delete yourself
    if (user.id === req.user.id) {
      return res.status(400).json({ message: 'You cannot delete your own account.' });
    }

    // Nullify cameras created by this surveyor (do not cascade delete cameras)
    await db.query('UPDATE cameras SET created_by = NULL WHERE created_by = $1', [userId]);

    await db.query('DELETE FROM users WHERE id = $1', [userId]);
    res.status(200).json({ message: `Surveyor "${user.name}" removed successfully.` });
  } catch (error) {
    console.error(`[USER] ERROR deleting user ${userId}:`, error);
    res.status(500).json({ message: 'Error deleting user', error: error.message });
  }
};

module.exports = { deleteSurveyor };
