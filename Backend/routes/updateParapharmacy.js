// routes/updateParapharmacy.js

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Parapharmacie = require('../models/Parapharmacie');

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
    req.isParapharmacie = decoded.isParapharmacie;
    next();
  } catch (error) {
    return res.status(400).json({ message: 'Invalid token' });
  }
};

// PUT /auth/update-parapharmacy - update parapharmacy info
router.put('/update-parapharmacy', verifyToken, async (req, res) => {
  try {
    const { name, phone, email, address, description, image } = req.body;
    const userId = req.userId;
    
    // Check if this is a parapharmacy account
    if (!req.isParapharmacie) {
      return res.status(403).json({ message: 'Only parapharmacy accounts can use this endpoint' });
    }
    
    // Create update object with only provided fields
    const updateData = {};
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;
    if (email) updateData.email = email;
    if (address) updateData.address = address;
    if (description) updateData.description = description;
    if (image) updateData.image = image;
    
    const updatedPara = await Parapharmacie.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('-password');

    if (!updatedPara) {
      return res.status(404).json({ message: 'Parapharmacy Not Found' });
    }
    
    // Return the updated parapharmacy
    res.json({
      message: 'Parapharmacy information updated successfully',
      parapharmacy: updatedPara
    });
  } catch (error) {
    console.error('Error updating parapharmacy:', error);
    res.status(500).json({ message: 'Error Updating Parapharmacy', error: error.message });
  }
});

module.exports = router;