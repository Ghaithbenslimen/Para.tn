// routes/adminOrders.js
const express = require('express');
const router = express.Router();
const Command = require('../models/Command');
const authenticateMiddleware = require('../middleware/authenticate');

// @route   GET /api/admin/orders
// @desc    Get all orders for the parapharmacy
// @access  Private (Parapharmacy owners only)
router.get('/', authenticateMiddleware, async (req, res) => {
  try {
    // Check if user is a parapharmacy owner
    if (!req.isParapharmacie) {
      return res.status(403).json({ message: 'Access denied. User is not a parapharmacy owner.' });
    }
    
    const ownerId = req.userId;
    
    // Find all orders for this parapharmacy directly using the parapharmacy field
    const orders = await Command.find({ parapharmacy: ownerId })
      .populate('user', 'username email')
      .populate({
        path: 'products.product',
        model: 'Product'
      })
      .sort({ createdAt: -1 });

    console.log('Orders found for parapharmacy:', orders.length);

    res.json({
      success: true,
      count: orders.length,
      orders
    });
  } catch (error) {
    console.error('Error fetching parapharmacy orders:', error);
    res.status(500).json({ 
      message: 'Server error', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// @route   GET /api/admin/orders/:id
// @desc    Get specific order details
// @access  Private (Parapharmacy owners only)
router.get('/:id', authenticateMiddleware, async (req, res) => {
  try {
    // Check if user is a parapharmacy owner
    if (!req.isParapharmacie) {
      return res.status(403).json({ message: 'Access denied. User is not a parapharmacy owner.' });
    }
    
    const ownerId = req.userId;
    
    const order = await Command.findOne({
      _id: req.params.id,
      parapharmacy: ownerId // Ensure the order belongs to this parapharmacy
    })
      .populate('user', 'username email')
      .populate({
        path: 'products.product',
        model: 'Product'
      });
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found or not authorized to view this order' });
    }
    
    res.json({
      success: true,
      order
    });
  } catch (error) {
    console.error('Error fetching order details:', error);
    res.status(500).json({ 
      message: 'Server error', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// @route   PUT /api/admin/orders/:id/update-status
// @desc    Update order status
// @access  Private (Parapharmacy owners only)
router.put('/:id/update-status', authenticateMiddleware, async (req, res) => {
  try {
    // Check if user is a parapharmacy owner
    if (!req.isParapharmacie) {
      return res.status(403).json({ message: 'Access denied. User is not a parapharmacy owner.' });
    }
    
    const { status } = req.body;
    
    if (!status || !['pending', 'processing', 'shipped', 'delivered', 'cancelled'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    
    const ownerId = req.userId;
    
    // Find the order and ensure it belongs to this parapharmacy
    const order = await Command.findOne({
      _id: req.params.id,
      parapharmacy: ownerId
    });
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found or not authorized to update this order' });
    }
    
    // Update the order status
    order.status = status;
    
    // If delivered, set deliveredAt
    if (status === 'delivered') {
      order.deliveredAt = Date.now();
    }
    
    const updatedOrder = await order.save();
    
    res.json({
      success: true,
      message: `Order status updated to ${status}`,
      order: updatedOrder
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json({ 
      message: 'Server error', 
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

module.exports = router;