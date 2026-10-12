const express = require('express');
const router = express.Router();
const Command = require('../models/Command');
const Product = require('../models/Product');
const Parapharmacie = require('../models/Parapharmacie');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

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

// Get statistics for the authenticated parapharmacy
router.get('/my-statistics', verifyToken, async (req, res) => {
  try {
    // Check if the user is a parapharmacy
    if (!req.isParapharmacie) {
      return res.status(403).json({ 
        message: 'Access denied. Only parapharmacies can access statistics.' 
      });
    }

    const parapharmacyId = req.userId;
    
    // Check if parapharmacy exists
    const parapharmacy = await Parapharmacie.findById(parapharmacyId);
    if (!parapharmacy) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    // Get all delivered orders for this parapharmacy
    const deliveredOrders = await Command.find({
      parapharmacy: parapharmacyId,
      status: 'delivered'
    }).populate('products.product');

    // Calculate total revenue
    const totalRevenue = deliveredOrders.reduce((sum, order) => sum + order.totalAmount, 0);
    
    // Calculate total number of orders
    const totalOrders = deliveredOrders.length;
    
    // Count unique customers
    const uniqueCustomers = new Set();
    deliveredOrders.forEach(order => {
      if (order.user) {
        uniqueCustomers.add(order.user.toString());
      }
    });
    const totalCustomers = uniqueCustomers.size;
    
    // Calculate average order value
    const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    
    // Get top selling products
    const productSales = {};
    deliveredOrders.forEach(order => {
      order.products.forEach(item => {
        const productId = item.product?._id?.toString() || 'unknown';
        if (!productSales[productId]) {
          productSales[productId] = {
            id: productId,
            name: item.name || (item.product ? item.product.name : 'Unknown Product'),
            image: item.image || (item.product ? item.product.image : ''),
            category: item.product ? item.product.category : '',
            quantity: 0,
            revenue: 0
          };
        }
        productSales[productId].quantity += item.quantity;
        productSales[productId].revenue += item.price * item.quantity;
      });
    });
    
    const topProducts = Object.values(productSales)
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);
    
    // Calculate sales by category
    const categorySales = {};
    deliveredOrders.forEach(order => {
      order.products.forEach(item => {
        if (item.product && item.product.category) {
          const category = item.product.category;
          if (!categorySales[category]) {
            categorySales[category] = {
              category,
              revenue: 0,
              quantity: 0
            };
          }
          categorySales[category].revenue += item.price * item.quantity;
          categorySales[category].quantity += item.quantity;
        }
      });
    });
    
    // Calculate total revenue to get percentages
    const totalCategoryRevenue = Object.values(categorySales).reduce(
      (sum, cat) => sum + cat.revenue, 0
    );
    
    // Add percentage to each category
    Object.values(categorySales).forEach(category => {
      category.percentage = totalCategoryRevenue > 0 
        ? (category.revenue / totalCategoryRevenue * 100).toFixed(2)
        : 0;
    });
    
    // Get monthly sales for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    
    const monthlySales = [];
    for (let i = 0; i < 6; i++) {
      const month = new Date();
      month.setMonth(month.getMonth() - i);
      
      const startOfMonth = new Date(month.getFullYear(), month.getMonth(), 1);
      const endOfMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0, 23, 59, 59);
      
      const monthlyOrders = deliveredOrders.filter(order => {
        const orderDate = new Date(order.deliveredAt || order.updatedAt || order.createdAt);
        return orderDate >= startOfMonth && orderDate <= endOfMonth;
      });
      
      const monthlyRevenue = monthlyOrders.reduce((sum, order) => sum + order.totalAmount, 0);
      
      monthlySales.unshift({
        month: month.toLocaleString('default', { month: 'short' }),
        sales: monthlyRevenue.toFixed(2),
        orders: monthlyOrders.length
      });
    }
    
    // Return the statistics
    res.json({
      parapharmacy: {
        id: parapharmacy._id,
        name: parapharmacy.name,
        image: parapharmacy.image
      },
      overview: {
        totalRevenue,
        totalOrders,
        totalCustomers,
        averageOrderValue,
        totalProducts: Object.keys(productSales).length
      },
      topProducts,
      categorySales: Object.values(categorySales).sort((a, b) => b.revenue - a.revenue),
      monthlySales
    });
    
  } catch (error) {
    console.error('Error fetching parapharmacy statistics:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get statistics for a specific parapharmacy (admin access or same parapharmacy)
router.get('/parapharmacy/:id', verifyToken, async (req, res) => {
  try {
    const parapharmacyId = req.params.id;
    
    // Validate the parapharmacy ID
    if (!mongoose.Types.ObjectId.isValid(parapharmacyId)) {
      return res.status(400).json({ message: 'Invalid parapharmacy ID' });
    }

    // Check if user has access to this parapharmacy's data
    // Only allow if user is the same parapharmacy or is an admin
    if (req.isParapharmacie && req.userId !== parapharmacyId) {
      return res.status(403).json({ 
        message: 'Access denied. You can only view your own statistics.' 
      });
    }

    // Check if parapharmacy exists
    const parapharmacy = await Parapharmacie.findById(parapharmacyId);
    if (!parapharmacy) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    // Get all delivered orders for this parapharmacy
    const deliveredOrders = await Command.find({
      parapharmacy: parapharmacyId,
      status: 'delivered'
    }).populate('products.product');

    // Calculate total revenue
    const totalRevenue = deliveredOrders.reduce((sum, order) => sum + order.totalAmount, 0);
    
    // Calculate total number of orders
    const totalOrders = deliveredOrders.length;

    // Count unique customers
    const uniqueCustomers = new Set();
    deliveredOrders.forEach(order => {
      if (order.user) {
        uniqueCustomers.add(order.user.toString());
      }
    });
    const totalCustomers = uniqueCustomers.size;
    
    // Calculate average order value
    const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    
    // Get top selling products
    const productSales = {};
    deliveredOrders.forEach(order => {
      order.products.forEach(item => {
        const productId = item.product?._id?.toString() || 'unknown';
        if (!productSales[productId]) {
          productSales[productId] = {
            id: productId,
            name: item.name || (item.product ? item.product.name : 'Unknown Product'),
            image: item.image || (item.product ? item.product.image : ''),
            category: item.product ? item.product.category : '',
            quantity: 0,
            revenue: 0
          };
        }
        productSales[productId].quantity += item.quantity;
        productSales[productId].revenue += item.price * item.quantity;
      });
    });
    
    const topProducts = Object.values(productSales)
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);
    
    // Calculate sales by category
    const categorySales = {};
    deliveredOrders.forEach(order => {
      order.products.forEach(item => {
        if (item.product && item.product.category) {
          const category = item.product.category;
          if (!categorySales[category]) {
            categorySales[category] = {
              category,
              revenue: 0,
              quantity: 0
            };
          }
          categorySales[category].revenue += item.price * item.quantity;
          categorySales[category].quantity += item.quantity;
        }
      });
    });
    
    // Calculate total revenue to get percentages
    const totalCategoryRevenue = Object.values(categorySales).reduce(
      (sum, cat) => sum + cat.revenue, 0
    );
    
    // Add percentage to each category
    Object.values(categorySales).forEach(category => {
      category.percentage = totalCategoryRevenue > 0 
        ? (category.revenue / totalCategoryRevenue * 100).toFixed(2)
        : 0;
    });
    
    // Get monthly sales for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    
    const monthlySales = [];
    for (let i = 0; i < 6; i++) {
      const month = new Date();
      month.setMonth(month.getMonth() - i);
      
      const startOfMonth = new Date(month.getFullYear(), month.getMonth(), 1);
      const endOfMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0, 23, 59, 59);
      
      const monthlyOrders = deliveredOrders.filter(order => {
        const orderDate = new Date(order.deliveredAt || order.updatedAt || order.createdAt);
        return orderDate >= startOfMonth && orderDate <= endOfMonth;
      });
      
      const monthlyRevenue = monthlyOrders.reduce((sum, order) => sum + order.totalAmount, 0);
      
      monthlySales.unshift({
        month: month.toLocaleString('default', { month: 'short' }),
        sales: monthlyRevenue.toFixed(2),
        orders: monthlyOrders.length
      });
    }
    
    // Return the statistics
    res.json({
      parapharmacy: {
        id: parapharmacy._id,
        name: parapharmacy.name,
        image: parapharmacy.image
      },
      overview: {
        totalRevenue,
        totalOrders,
        totalCustomers,
        averageOrderValue,
        totalProducts: Object.keys(productSales).length
      },
      topProducts,
      categorySales: Object.values(categorySales).sort((a, b) => b.revenue - a.revenue),
      monthlySales
    });
    
  } catch (error) {
    console.error('Error fetching parapharmacy statistics:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get statistics for all parapharmacies (for admin)
router.get('/admin', verifyToken, async (req, res) => {
  try {
    // Check if user is admin (you may need to adjust this based on your admin check)
    if (req.isParapharmacie) {
      return res.status(403).json({ 
        message: 'Access denied. Only admins can access all statistics.' 
      });
    }
    
    // Get all delivered orders
    const deliveredOrders = await Command.find({
      status: 'delivered'
    }).populate('parapharmacy');
    
    // Calculate total revenue across all parapharmacies
    const totalRevenue = deliveredOrders.reduce((sum, order) => sum + order.totalAmount, 0);
    
    // Calculate total number of orders
    const totalOrders = deliveredOrders.length;
    
    // Count unique customers across all parapharmacies
    const uniqueCustomers = new Set();
    deliveredOrders.forEach(order => {
      if (order.user) {
        uniqueCustomers.add(order.user.toString());
      }
    });
    const totalCustomers = uniqueCustomers.size;
    
    // Get sales by parapharmacy
    const parapharmacySales = {};
    deliveredOrders.forEach(order => {
      if (!order.parapharmacy) return;
      
      const parapharmacyId = order.parapharmacy._id.toString();
      if (!parapharmacySales[parapharmacyId]) {
        parapharmacySales[parapharmacyId] = {
          id: parapharmacyId,
          name: order.parapharmacy.name,
          image: order.parapharmacy.image,
          revenue: 0,
          orders: 0
        };
      }
      parapharmacySales[parapharmacyId].revenue += order.totalAmount;
      parapharmacySales[parapharmacyId].orders += 1;
    });
    
    
    // Sort parapharmacies by revenue
    const topParapharmacies = Object.values(parapharmacySales)
      .sort((a, b) => b.revenue - a.revenue);
    
    // Get monthly sales for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    
    const monthlySales = [];
    for (let i = 0; i < 6; i++) {
      const month = new Date();
      month.setMonth(month.getMonth() - i);
      
      const startOfMonth = new Date(month.getFullYear(), month.getMonth(), 1);
      const endOfMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0, 23, 59, 59);
      
      const monthlyOrders = deliveredOrders.filter(order => {
        const orderDate = new Date(order.deliveredAt || order.updatedAt || order.createdAt);
        return orderDate >= startOfMonth && orderDate <= endOfMonth;
      });
      
      const monthlyRevenue = monthlyOrders.reduce((sum, order) => sum + order.totalAmount, 0);
      
      monthlySales.unshift({
        month: month.toLocaleString('default', { month: 'short' }),
        sales: monthlyRevenue.toFixed(2),
        orders: monthlyOrders.length
      });
    }
    
    // Return the statistics
    res.json({
      overview: {
        totalRevenue,
        totalOrders,
        totalCustomers,
        averageOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
        totalParapharmacies: Object.keys(parapharmacySales).length
      },
      topParapharmacies,
      monthlySales
    });
    
  } catch (error) {
    console.error('Error fetching admin statistics:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});


module.exports = router;