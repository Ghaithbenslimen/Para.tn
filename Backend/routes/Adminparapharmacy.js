const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const Parapharmacie = require('../models/Parapharmacie');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/profile_pictures';
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  // Accept only image files
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB limit
});

// GET all parapharmacies
router.get('/', async (req, res) => {
  try {
    const parapharmacies = await Parapharmacie.find({}, { password: 0 }); // Exclude password
    res.status(200).json(parapharmacies);
  } catch (error) {
    console.error('Error fetching parapharmacies:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// GET a single parapharmacie by ID
router.get('/:id', async (req, res) => {
  try {
    const parapharmacie = await Parapharmacie.findById(req.params.id, { password: 0 }); // Exclude password
    
    if (!parapharmacie) {
      return res.status(404).json({ message: 'Parapharmacie not found' });
    }
    
    res.status(200).json(parapharmacie);
  } catch (error) {
    console.error('Error fetching parapharmacie:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// POST create a new parapharmacie
router.post('/register', upload.single('image'), async (req, res) => {
  try {
    const { name, address, description, email, phone, password } = req.body;
    
    // Check if parapharmacie with this email already exists
    const existingParapharmacie = await Parapharmacie.findOne({ email });
    if (existingParapharmacie) {
      return res.status(400).json({ message: 'A parapharmacie with this email already exists' });
    }
    
    // Hash the password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    // Create new parapharmacie object
    const newParapharmacie = new Parapharmacie({
      para: true,
      name,
      address,
      description,
      email,
      phone,
      password: hashedPassword,
      image: req.file ? req.file.path : undefined,
      location: {
        type: 'Point',
        coordinates: [0, 0] // Default coordinates, can be updated later
      }
    });
    
    // Save to database
    const savedParapharmacie = await newParapharmacie.save();
    
    // Return the created parapharmacie without password
    const responseParapharmacie = savedParapharmacie.toObject();
    delete responseParapharmacie.password;
    
    res.status(201).json({
      message: 'Parapharmacie created successfully',
      parapharmacie: responseParapharmacie
    });
  } catch (error) {
    console.error('Error creating parapharmacie:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// PUT update a parapharmacie
router.put('/:id', upload.single('image'), async (req, res) => {
  try {
    const { name, address, description, email, phone, password } = req.body;
    const parapharmacieId = req.params.id;
    
    // Check if parapharmacie exists
    const parapharmacie = await Parapharmacie.findById(parapharmacieId);
    if (!parapharmacie) {
      return res.status(404).json({ message: 'Parapharmacie not found' });
    }
    
    // Check if email is being changed and if it's already in use by ANOTHER parapharmacie
    if (email !== parapharmacie.email) {
      // Use $ne (not equal) to exclude the current parapharmacie from the check
      const existingParapharmacie = await Parapharmacie.findOne({ 
        email: email,
        _id: { $ne: parapharmacieId } // Exclude the current parapharmacie
      });
      
      if (existingParapharmacie) {
        return res.status(400).json({ message: 'A parapharmacie with this email already exists' });
      }
    }
    
    // Prepare update object
    const updateData = {
      name,
      address,
      description,
      email,
      phone
    };
    
    // Handle password update if provided
    if (password && password.trim() !== '') {
      const salt = await bcrypt.genSalt(10);
      updateData.password = await bcrypt.hash(password, salt);
    }
    
    // Handle image update
    if (req.file) {
      // Delete old image if exists
      if (parapharmacie.image) {
        try {
          fs.unlinkSync(parapharmacie.image);
        } catch (err) {
          console.error('Error deleting old image:', err);
          // Continue even if delete fails
        }
      }
      updateData.image = req.file.path;
    }
    
    // Update parapharmacie
    const updatedParapharmacie = await Parapharmacie.findByIdAndUpdate(
      parapharmacieId,
      updateData,
      { new: true, runValidators: true }
    ).select('-password'); // Exclude password from response
    
    res.status(200).json({
      message: 'Parapharmacie updated successfully',
      parapharmacie: updatedParapharmacie
    });
  } catch (error) {
    console.error('Error updating parapharmacie:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// DELETE a parapharmacie
router.delete('/:id', async (req, res) => {
  try {
    const parapharmacieId = req.params.id;
    
    // Find parapharmacie to get image path before deletion
    const parapharmacie = await Parapharmacie.findById(parapharmacieId);
    
    if (!parapharmacie) {
      return res.status(404).json({ message: 'Parapharmacie not found' });
    }
    
    // Delete the parapharmacie
    await Parapharmacie.findByIdAndDelete(parapharmacieId);
    
    // Delete associated image if exists
    if (parapharmacie.image) {
      try {
        fs.unlinkSync(parapharmacie.image);
      } catch (err) {
        console.error('Error deleting image file:', err);
        // Continue even if delete fails
      }
    }
    
    res.status(200).json({ message: 'Parapharmacie deleted successfully' });
  } catch (error) {
    console.error('Error deleting parapharmacie:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update parapharmacie location
router.patch('/:id/location', async (req, res) => {
  try {
    const { longitude, latitude } = req.body;
    const parapharmacieId = req.params.id;
    
    if (!longitude || !latitude) {
      return res.status(400).json({ message: 'Longitude and latitude are required' });
    }
    
    // Update location
    const updatedParapharmacie = await Parapharmacie.findByIdAndUpdate(
      parapharmacieId,
      {
        location: {
          type: 'Point',
          coordinates: [parseFloat(longitude), parseFloat(latitude)]
        }
      },
      { new: true, runValidators: true }
    ).select('-password');
    
    if (!updatedParapharmacie) {
      return res.status(404).json({ message: 'Parapharmacie not found' });
    }
    
    res.status(200).json({
      message: 'Location updated successfully',
      parapharmacie: updatedParapharmacie
    });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Add or update a review
router.post('/:id/reviews', async (req, res) => {
  try {
    const { user, rating, comment } = req.body;
    const parapharmacieId = req.params.id;
    
    if (!rating || !comment) {
      return res.status(400).json({ message: 'Rating and comment are required' });
    }
    
    // Create review object
    const review = {
      user: user || 'Anonymous',
      rating: parseInt(rating),
      comment,
      date: new Date()
    };
    
    // Add review to parapharmacie
    const parapharmacie = await Parapharmacie.findByIdAndUpdate(
      parapharmacieId,
      { $push: { reviews: review } },
      { new: true, runValidators: true }
    );
    
    if (!parapharmacie) {
      return res.status(404).json({ message: 'Parapharmacie not found' });
    }
    
    // Calculate and update average rating
    const totalRating = parapharmacie.reviews.reduce((sum, review) => sum + review.rating, 0);
    const averageRating = totalRating / parapharmacie.reviews.length;
    
    await Parapharmacie.findByIdAndUpdate(
      parapharmacieId,
      { rating: averageRating }
    );
    
    res.status(201).json({
      message: 'Review added successfully',
      review
    });
  } catch (error) {
    console.error('Error adding review:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;