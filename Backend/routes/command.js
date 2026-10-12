const express = require('express');
const router = express.Router();
const Command = require('../models/Command');
const Product = require('../models/Product');
const authenticateMiddleware = require('../middleware/authenticate');

// @route   POST /api/commands
// @desc    Create new command(s) - one per parapharmacy
// @access  Private
router.post('/', authenticateMiddleware, async (req, res) => {
  try {
    const { products, shippingAddress, paymentMethod } = req.body;
    
    if (!products || products.length === 0) {
      return res.status(400).json({ message: 'No products in the order' });
    }
    
    // Group products by parapharmacy
    const productsByParapharmacy = {};
    const productDetails = {};
    
    // First, fetch all product details and organize them
    for (const item of products) {
      const { productId, quantity } = item;
      
      if (!productId || !quantity) {
        return res.status(400).json({ message: 'Product ID and quantity are required for each item' });
      }
      
      // Find the product in the database
      const product = await Product.findById(productId);
      
      if (!product) {
        return res.status(404).json({ message: `Product not found: ${productId}` });
      }
      
      // Check if product has a parapharmacie
      if (!product.parapharmacie) {
        return res.status(400).json({ 
          message: `Product ${productId} has no associated parapharmacy owner` 
        });
      }
      
      // Check if enough quantity is available
      if (product.quantity < quantity) {
        return res.status(400).json({ 
          message: `Not enough stock for ${product.name}. Available: ${product.quantity}` 
        });
      }
      
      // Store product details for later use
      productDetails[productId] = product;
      
      // Group by parapharmacy
      const parapharmacyId = product.parapharmacie.toString();
      if (!productsByParapharmacy[parapharmacyId]) {
        productsByParapharmacy[parapharmacyId] = [];
      }
      
      productsByParapharmacy[parapharmacyId].push({
        productId,
        quantity,
        product
      });
    }
    
    // Create one order per parapharmacy
    const createdCommands = [];
    
    for (const [parapharmacyId, parapharmacyProducts] of Object.entries(productsByParapharmacy)) {
      // Calculate order items and total for this parapharmacy
      const orderItems = [];
      let totalAmount = 0;
      
      for (const item of parapharmacyProducts) {
        const { product, quantity } = item;
        
        // Calculate price (considering discounts)
        const price = product.hasDiscount 
          ? product.price * (1 - product.discountPercentage / 100) 
          : product.price;
        
        // Add to order items
        orderItems.push({
          product: product._id,
          quantity,
          price,
          name: product.name,
          image: product.image
        });
        
        // Add to total amount
        totalAmount += price * quantity;
        
        // Update product quantity
        product.quantity -= quantity;
        await product.save();
      }
      
      // Create the command for this parapharmacy
      const command = new Command({
        user: req.userId,
        parapharmacy: parapharmacyId,
        products: orderItems,
        totalAmount,
        shippingAddress,
        paymentMethod
      });
      
      const savedCommand = await command.save();
      
      // Populate product details for the response
      const populatedCommand = await Command.findById(savedCommand._id)
        .populate('user', 'username email')
        .populate('parapharmacy', 'name email image')
        .populate('products.product', 'name price image');
      
      createdCommands.push(populatedCommand);
    }
    
    res.status(201).json({
      success: true,
      commands: createdCommands,
      // Return the first command ID as the main order ID for backward compatibility
      commandId: createdCommands[0]?._id
    });
    
  } catch (error) {
    console.error('Error creating command:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// The rest of your routes remain the same
// @route   GET /api/commands
// @desc    Get all commands for the logged-in user
// @access  Private
router.get('/', authenticateMiddleware, async (req, res) => {
  try {
    const commands = await Command.find({ user: req.userId })
      .populate('products.product', 'name price image')
      .populate('parapharmacy', 'name email image')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      count: commands.length,
      commands
    });
    
  } catch (error) {
    console.error('Error fetching commands:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/commands/:id
// @desc    Get command by ID
// @access  Private
router.get('/:id', authenticateMiddleware, async (req, res) => {
  try {
    const command = await Command.findById(req.params.id)
      .populate('user', 'username email')
      .populate('parapharmacy', 'name email image address phone')
      .populate('products.product', 'name price image');
    
    if (!command) {
      return res.status(404).json({ message: 'Command not found' });
    }
    
    // Check if the command belongs to the logged-in user
    if (command.user._id.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to access this command' });
    }
    
    // Get all related commands (from the same checkout process)
    // This is a new feature to support multi-parapharmacy orders
    const relatedCommands = await Command.find({
      user: req.userId,
      createdAt: {
        // Find commands created within 1 minute of this command
        $gte: new Date(new Date(command.createdAt).getTime() - 60000),
        $lte: new Date(new Date(command.createdAt).getTime() + 60000)
      },
      _id: { $ne: command._id } // Exclude the current command
    })
      .populate('parapharmacy', 'name email image address phone')
      .populate('products.product', 'name price image');
    
    res.json({
      success: true,
      command,
      relatedCommands
    });
    
  } catch (error) {
    console.error('Error fetching command:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   PUT /api/commands/:id/pay
// @desc    Update command to paid
// @access  Private
router.put('/:id/pay', authenticateMiddleware, async (req, res) => {
  try {
    const command = await Command.findById(req.params.id);
    
    if (!command) {
      return res.status(404).json({ message: 'Command not found' });
    }
    
    // Check if the command belongs to the logged-in user
    if (command.user.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to update this command' });
    }
    
    command.isPaid = true;
    command.paidAt = Date.now();
    command.status = 'processing';
    
    const updatedCommand = await command.save();
    
    res.json({
      success: true,
      command: updatedCommand
    });
    
  } catch (error) {
    console.error('Error updating payment status:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   PUT /api/commands/:id/cancel
// @desc    Cancel a command
// @access  Private
router.put('/:id/cancel', authenticateMiddleware, async (req, res) => {
  try {
    const command = await Command.findById(req.params.id);
    
    if (!command) {
      return res.status(404).json({ message: 'Command not found' });
    }
    
    // Check if the command belongs to the logged-in user
    if (command.user.toString() !== req.userId) {
      return res.status(403).json({ message: 'Not authorized to cancel this command' });
    }
    
    // Only allow cancellation if status is pending or processing
    if (!['pending', 'processing'].includes(command.status)) {
      return res.status(400).json({ 
        message: `Cannot cancel command with status: ${command.status}` 
      });
    }
    
    // Restore product quantities
    for (const item of command.products) {
      const product = await Product.findById(item.product);
      if (product) {
        product.quantity += item.quantity;
        await product.save();
      }
    }
    
    command.status = 'cancelled';
    const updatedCommand = await command.save();
    
    res.json({
      success: true,
      command: updatedCommand
    });
    
  } catch (error) {
    console.error('Error cancelling command:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;