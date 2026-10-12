const express = require('express');
const mongoose = require('mongoose');
const authenticateMiddleware = require('../middleware/authenticate.js');

const router = express.Router();

// Create a Wishlist model if it doesn't exist
const WishlistSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  products: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product'
  }],
}, { timestamps: true });

// Check if model already exists to avoid overwriting
const Wishlist = mongoose.models.Wishlist || mongoose.model('Wishlist', WishlistSchema);

// Get user's wishlist
router.get('/', authenticateMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    
    // Find wishlist and populate product details
    let wishlist = await Wishlist.findOne({ user: userId }).populate('products');
    
    if (!wishlist) {
      return res.status(200).json({
        success: true,
        wishlist: []
      });
    }
    
    res.status(200).json({
      success: true,
      wishlist: wishlist.products
    });
  } catch (error) {
    console.error('Error fetching wishlist:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch wishlist', 
      error: error.message 
    });
  }
});

// Add product to wishlist
router.post('/add/:productId', authenticateMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { productId } = req.params;
    
    // Validate product exists
    const product = await mongoose.model('Product').findById(productId);
    if (!product) {
      return res.status(404).json({ 
        success: false, 
        message: 'Product not found' 
      });
    }
    
    // Find or create wishlist
    let wishlist = await Wishlist.findOne({ user: userId });
    
    if (!wishlist) {
      wishlist = new Wishlist({
        user: userId,
        products: [productId]
      });
    } else if (!wishlist.products.includes(productId)) {
      // Only add if not already in wishlist
      wishlist.products.push(productId);
    }
    
    await wishlist.save();
    
    res.status(200).json({
      success: true,
      message: 'Product added to wishlist',
      productId
    });
  } catch (error) {
    console.error('Error adding to wishlist:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to add product to wishlist', 
      error: error.message 
    });
  }
});

// Remove product from wishlist
router.delete('/remove/:productId', authenticateMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { productId } = req.params;
    
    // Find wishlist
    const wishlist = await Wishlist.findOne({ user: userId });
    
    if (!wishlist) {
      return res.status(404).json({ 
        success: false, 
        message: 'Wishlist not found' 
      });
    }
    
    // Remove product from wishlist
    wishlist.products = wishlist.products.filter(
      product => product.toString() !== productId
    );
    
    await wishlist.save();
    
    res.status(200).json({
      success: true,
      message: 'Product removed from wishlist',
      productId
    });
  } catch (error) {
    console.error('Error removing from wishlist:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to remove product from wishlist', 
      error: error.message 
    });
  }
});

// Check if a product is in user's wishlist
router.get('/check/:productId', authenticateMiddleware, async (req, res) => {
  try {
    const userId = req.userId;
    const { productId } = req.params;
    
    const wishlist = await Wishlist.findOne({ user: userId });
    
    const isInWishlist = wishlist ? 
      wishlist.products.some(product => product.toString() === productId) : 
      false;
    
    res.status(200).json({
      success: true,
      isInWishlist
    });
  } catch (error) {
    console.error('Error checking wishlist:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to check wishlist status', 
      error: error.message 
    });
  }
});

module.exports = router;