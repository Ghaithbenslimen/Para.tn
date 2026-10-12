const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Product = require('../models/Product');
const Parapharmacie = require('../models/Parapharmacie');
const jwt = require('jsonwebtoken');

// Debug middleware to log incoming requests
router.use((req, res, next) => {
  console.log('Product API Request received:', {
    method: req.method,
    path: req.path,
    body: req.body,
    headers: req.headers,
    files: req.file || req.files
  });
  next();
});

// Middleware to verify token and ensure it's a parapharmacie
const verifyParapharmacie = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ message: 'Access denied. No token provided' });
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const parapharmacie = await Parapharmacie.findById(decoded.userId);
    if (!parapharmacie || !parapharmacie.para) {
      return res.status(403).json({ message: 'Access denied. Not a parapharmacie' });
    }
    req.parapharmacie = parapharmacie;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(400).json({ message: 'Invalid token', error: error.message });
  }
};

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = 'uploads/products';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});
const fileFilter = (req, file, cb) => {
  if (file.mimetype && file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    const ext = path.extname(file.originalname).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Not an image! Please upload only images.'), false);
    }
  }
};
const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: fileFilter
});

// Add a new product
router.post('/products', verifyParapharmacie, upload.single('image'), async (req, res) => {
  try {
    console.log('Processing product addition request:', req.body);
    const { 
      name, 
      category, 
      price, 
      quantity, 
      hasDiscount, 
      discountPercentage, 
      description, 
      howToUse,
      intelfaceassis,
      skinTypes  // NEW: Get skinTypes from req.body
    } = req.body;

    if (!req.file) {
      console.error('Product image missing');
      return res.status(400).json({ message: 'Product image is required' });
    }

    const newProduct = new Product({
      parapharmacie: req.parapharmacie._id,
      name,
      category,
      price: parseFloat(price),
      quantity: parseInt(quantity),
      hasDiscount: hasDiscount === 'true',
      discountPercentage: hasDiscount === 'true' ? parseFloat(discountPercentage) : 0,
      description,
      howToUse,
      intelfaceassis: intelfaceassis || 'none',
      skinTypes: skinTypes ? JSON.parse(skinTypes) : [], // NEW: Parse and set skinTypes
      image: req.file.path
    });

    console.log('Attempting to save product:', newProduct);
    const savedProduct = await newProduct.save();
    console.log('Product saved successfully:', savedProduct);
    
    res.status(201).json({
      success: true,
      message: 'Product added successfully',
      product: savedProduct
    });
  } catch (error) {
    console.error('Failed to add product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add product',
      error: error.message
    });
  }
});

// Get all products for a parapharmacie
router.get('/products', verifyParapharmacie, async (req, res) => {
  try {
    const products = await Product.find({ parapharmacie: req.parapharmacie._id });
    res.status(200).json({
      success: true,
      count: products.length,
      products
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch products',
      error: error.message
    });
  }
});

// ... (Other routes remain unchanged)
// Update a product
router.put('/products/:id', verifyParapharmacie, upload.single('image'), async (req, res) => {
  try {
    const productId = req.params.id;
    const { 
      name, 
      category, 
      price, 
      quantity, 
      hasDiscount, 
      discountPercentage, 
      description, 
      howToUse,
      intelfaceassis,
      skinTypes  // NEW: Get skinTypes from req.body
    } = req.body;

    // Find the product
    const product = await Product.findById(productId);
    
    if (!product) {
      return res.status(404).json({ 
        success: false, 
        message: 'Product not found' 
      });
    }
    
    // Check if this parapharmacie owns the product
    if (product.parapharmacie.toString() !== req.parapharmacie._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Not authorized to update this product' 
      });
    }

    // Update fields
    product.name = name;
    product.category = category;
    product.price = parseFloat(price);
    product.quantity = parseInt(quantity);
    product.hasDiscount = hasDiscount === 'true';
    product.discountPercentage = hasDiscount === 'true' ? parseFloat(discountPercentage) : 0;
    product.description = description;
    product.howToUse = howToUse;
    product.intelfaceassis = intelfaceassis || 'none';
    product.skinTypes = skinTypes ? JSON.parse(skinTypes) : product.skinTypes; // NEW: Update skinTypes
    
    // Update image if provided
    if (req.file) {
      // Delete old image if it exists
      if (product.image && fs.existsSync(product.image)) {
        fs.unlinkSync(product.image);
      }
      product.image = req.file.path;
    }

    const updatedProduct = await product.save();
    
    res.status(200).json({
      success: true,
      message: 'Product updated successfully',
      product: updatedProduct
    });
  } catch (error) {
    console.error('Failed to update product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update product',
      error: error.message
    });
  }
});
// Delete a product
router.delete('/products/:id', verifyParapharmacie, async (req, res) => {
  try {
    const productId = req.params.id;
    
    // Find the product
    const product = await Product.findById(productId);
    
    if (!product) {
      return res.status(404).json({ 
        success: false, 
        message: 'Product not found' 
      });
    }
    
    // Check if this parapharmacie owns the product
    if (product.parapharmacie.toString() !== req.parapharmacie._id.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Not authorized to delete this product' 
      });
    }
    
    // Delete the product image if it exists
    if (product.image && fs.existsSync(product.image)) {
      fs.unlinkSync(product.image);
    }
    
    // Delete the product
    await Product.findByIdAndDelete(productId);
    
    res.status(200).json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    console.error('Failed to delete product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete product',
      error: error.message
    });
  }
});

module.exports = router;
