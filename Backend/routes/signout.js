// routes/signout.js
const express = require('express');
const router = express.Router();

router.post('/signout', (req, res) => {
  // If you are using cookies (e.g., for a JWT token), clear the token cookie.
  res.clearCookie('token'); // Adjust 'token' if your cookie has a different name

  // If you are using sessions, you can destroy the session.
  if (req.session) {
    req.session.destroy((err) => {
      if (err) {
        return res.status(500).json({ message: 'Error signing out' });
      }
      return res.status(200).json({ message: 'Successfully signed out' });
    });
  } else {
    // If not using sessions, just send the response.
    res.status(200).json({ message: 'Successfully signed out' });
  }
});

module.exports = router;
