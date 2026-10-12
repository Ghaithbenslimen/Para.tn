const express = require('express');
const router = express.Router();
const Parapharmacie = require('../models/Parapharmacie'); // Ensure this model is correctly defined
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt'); // For password encryption

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Ensure the uploads directory exists
    if (!fs.existsSync('uploads/')) {
      fs.mkdirSync('uploads/', { recursive: true });
    }
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname)); // Unique filename
  }
});

const upload = multer({ storage });

// Register a new parapharmacy
router.post('/Gererpara/register', upload.single('image'), async (req, res) => {
  try {
    const { name, address, description, phone, email, password } = req.body;

    // Check if email already exists
    const existingPara = await Parapharmacie.findOne({ email });
    if (existingPara) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Hash the password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const newParapharmacie = new Parapharmacie({
      name,
      address,
      description,
      phone,
      email,
      password: hashedPassword, // Store the hashed password
      image: req.file ? req.file.path : null
    });

    await newParapharmacie.save();
    res.status(201).json({ message: 'Parapharmacy registered successfully', parapharmacie: newParapharmacie });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Error registering parapharmacy', error: error.message });
  }
});

// Get all parapharmacies
router.get('/Gererpara', async (req, res) => {
  try {
    const parapharmacies = await Parapharmacie.find().select('-password'); // Exclude password from results
    res.json(parapharmacies);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching parapharmacies', error: error.message });
  }
});

// Update a parapharmacy
router.put('/Gererpara/:id', upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    const updates = { ...req.body };

    // Find the parapharmacy first to check if it exists
    const existingPara = await Parapharmacie.findById(id);
    if (!existingPara) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    // Handle email uniqueness validation
    if (updates.email && updates.email !== existingPara.email) {
      // Exclude the current parapharmacy from the email uniqueness check
      const emailExists = await Parapharmacie.findOne({ email: updates.email, _id: { $ne: id } });
      if (emailExists) {
        return res.status(400).json({ message: 'Email already exists' });
      }
    }

    // Handle password update
    if (updates.password) {
      // Only update password if a new one is provided
      const saltRounds = 10;
      updates.password = await bcrypt.hash(updates.password, saltRounds);
    } else {
      // If no password provided, remove it from updates to keep the existing one
      delete updates.password;
    }

    // Handle image update
    if (req.file) {
      updates.image = req.file.path;

      // Delete old image if it exists
      if (existingPara.image) {
        fs.unlink(existingPara.image, (err) => {
          if (err) console.error('Error deleting old image:', err);
        });
      }
    } else if (updates.existing_image) {
      // If no new image but existing_image is provided, keep the existing image
      updates.image = updates.existing_image;
    }

    // Remove existing_image from updates as it's not a field in the model
    delete updates.existing_image;

    // Update the parapharmacy
    const updatedPara = await Parapharmacie.findByIdAndUpdate(
      id,
      updates,
      { new: true, runValidators: true }
    );

    res.json({ message: 'Parapharmacy updated successfully', parapharmacie: updatedPara });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ message: 'Error updating parapharmacy', error: error.message });
  }
});

// Delete a parapharmacy
router.delete('/Gererpara/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const deletedPara = await Parapharmacie.findByIdAndDelete(id);

    if (!deletedPara) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    // Delete associated image if it exists
    if (deletedPara.image) {
      fs.unlink(deletedPara.image, (err) => {
        if (err) console.error('Error deleting image:', err);
      });
    }

    res.json({ message: 'Parapharmacy deleted successfully' });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ message: 'Error deleting parapharmacy', error: error.message });
  }
});

module.exports = router;