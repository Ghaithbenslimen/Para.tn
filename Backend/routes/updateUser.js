const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware to verify token
const verifyToken = (req, res, next) => {
  const token =
    req.header('Authorization') &&
    req.header('Authorization').split(' ')[1];

  if (!token) {
    return res
      .status(401)
      .json({ message: 'No token provided, authorization denied.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(400).json({ message: 'Invalid token' });
  }
};

// GET /auth/profile - retrieve the logged-in user's profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Return user data as JSON
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving user profile', error: error.message });
  }
});

// PUT /auth/update - update user info
router.put('/update', verifyToken, async (req, res) => {
  const { fullName, phone, country } = req.body;
  const locationAddress = req.body.location || '';
  const userId = req.userId;

  try {
    // Create update object
    const updateData = {
      fullName,
      phone,
      country
    };

    // Only update the address part of the location, not the entire location object
    if (locationAddress) {
      updateData['location.address'] = locationAddress;
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User Not Found' });
    }
    
    // Return the updated user
    res.json({
      message: 'Profile updated successfully',
      user: updatedUser
    });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ message: 'Error Updating User', error: error.message });
  }
});



module.exports = router;