// routes/trackOrder.js
const express = require('express');
const router = express.Router();
const Command = require('../models/Command');
const authenticateMiddleware = require('../middleware/authenticate');

// @route   GET /api/track-orders
// @desc    Get all orders for the logged-in user
// @access  Private
router.get('/', authenticateMiddleware, async (req, res) => {
  try {
    const orders = await Command.find({ user: req.userId })
      .populate('products.product', 'name price image category')
      .populate('parapharmacy', 'name email image') // Populate parapharmacy info
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: orders.length,
      orders
    });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/track-orders/:id
// @desc    Get specific order details
// @access  Private
router.get('/:id', authenticateMiddleware, async (req, res) => {
  try {
    const order = await Command.findById(req.params.id)
      .populate('products.product', 'name price image category')
      .populate('user', 'username email')
      .populate('parapharmacy', 'name email image address phone'); // Populate detailed parapharmacy info
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Ensure the order belongs to the logged-in user
    if (order.user._id.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to view this order' });
    }
    
    res.json({
      success: true,
      order
    });
  } catch (error) {
    console.error('Error fetching order details:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   PUT /api/track-orders/:id/cancel
// @desc    Cancel an order
// @access  Private
router.put('/:id/cancel', authenticateMiddleware, async (req, res) => {
  try {
    const order = await Command.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Ensure the order belongs to the logged-in user
    if (order.user.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to cancel this order' });
    }
    
    // Only allow cancellation if status is pending or processing
    if (!['pending', 'processing'].includes(order.status)) {
      return res.status(400).json({ 
        message: `Cannot cancel order with status: ${order.status}` 
      });
    }
    
    order.status = 'cancelled';
    const updatedOrder = await order.save();
    
    res.json({
      success: true,
      order: updatedOrder
    });
  } catch (error) {
    console.error('Error cancelling order:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;