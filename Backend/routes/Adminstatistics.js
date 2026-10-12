const express = require('express');
const router = express.Router();
const Parapharmacie = require('../models/Parapharmacie');
const Command = require('../models/Command');
const Product = require('../models/Product');
const User = require('../models/User');
const mongoose = require('mongoose');

// Helper function to get date range
const getDateRange = (period) => {
  const now = new Date();
  let startDate;
  
  switch(period) {
    case 'day':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      break;
    case 'week':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
      break;
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      break;
    case '3months':
      startDate = new Date(now.getFullYear(), now.getMonth() - 3, 1);
      break;
    case '6months':
      startDate = new Date(now.getFullYear(), now.getMonth() - 6, 1);
      break;
    case 'year':
      startDate = new Date(now.getFullYear(), 0, 1);
      break;
    default:
      startDate = new Date(now.getFullYear(), now.getMonth(), 1); // Default to month
  }
  
  return { startDate, endDate: now };
};

// Get total product count
router.get('/product-count', async (req, res) => {
  try {
    const count = await Product.countDocuments();
    res.json({ count });
  } catch (error) {
    console.error('Error fetching product count:', error);
    res.status(500).json({ message: 'Error fetching product count', error: error.message });
  }
});

// Get low stock products
router.get('/low-stock-products', async (req, res) => {
  try {
    const products = await Product.find({ quantity: { $lt: 10 } })
      .sort({ quantity: 1 })
      .limit(5)
      .select('name quantity');
    
    res.json(products);
  } catch (error) {
    console.error('Error fetching low stock products:', error);
    res.status(500).json({ message: 'Error fetching low stock products', error: error.message });
  }
});

// Get total number of users
router.get('/total-users', async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    res.json({ total: totalUsers });
  } catch (error) {
    console.error('Error fetching total users:', error);
    res.status(500).json({ message: 'Error fetching total users', error: error.message });
  }
});

// Get user statistics
router.get('/user-statistics', async (req, res) => {
  try {
    // Get total users
    const totalUsers = await User.countDocuments();
    
    // Get new users in the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const newUsers = await User.countDocuments({
      createdAt: { $gte: thirtyDaysAgo }
    });
    
    // Get users by country (if available)
    const usersByCountry = await User.aggregate([
      { $match: { country: { $exists: true, $ne: "" } } },
      { $group: { _id: "$country", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);
    
    // Get users by registration month for the current year
    const currentYear = new Date().getFullYear();
    const usersByMonth = await User.aggregate([
      { 
        $match: { 
          createdAt: { 
            $gte: new Date(`${currentYear}-01-01`), 
            $lt: new Date(`${currentYear + 1}-01-01`) 
          } 
        } 
      },
      {
        $group: {
          _id: { $month: "$createdAt" },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    // Format the result to include all months
    const monthlyUsers = [];
    for (let i = 1; i <= 12; i++) {
      const monthData = usersByMonth.find(item => item._id === i);
      monthlyUsers.push({
        month: `${currentYear}-${i.toString().padStart(2, '0')}`,
        count: monthData ? monthData.count : 0
      });
    }
    
    res.json({
      totalUsers,
      newUsers,
      usersByCountry: usersByCountry.map(item => ({
        country: item._id || 'Unknown',
        count: item.count
      })),
      usersByMonth: monthlyUsers
    });
  } catch (error) {
    console.error('Error fetching user statistics:', error);
    res.status(500).json({ message: 'Error fetching user statistics', error: error.message });
  }
});

// Get total number of parapharmacies
router.get('/total-parapharmacies', async (req, res) => {
  try {
    const totalParapharmacies = await Parapharmacie.countDocuments();
    res.json({ total: totalParapharmacies });
  } catch (error) {
    console.error('Error fetching total parapharmacies:', error);
    res.status(500).json({ message: 'Error fetching total parapharmacies', error: error.message });
  }
});

// Get monthly revenue
router.get('/monthly-revenue', async (req, res) => {
  try {
    const { year } = req.query;
    const selectedYear = year ? parseInt(year) : new Date().getFullYear();
    
    const monthlyRevenue = await Command.aggregate([
      {
        $match: {
          status: { $ne: 'cancelled' },
          createdAt: {
            $gte: new Date(`${selectedYear}-01-01`),
            $lt: new Date(`${selectedYear + 1}-01-01`)
          }
        }
      },
      {
        $group: {
          _id: { $month: '$createdAt' },
          revenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    // Format the result to include all months
    const result = [];
    for (let i = 1; i <= 12; i++) {
      const monthData = monthlyRevenue.find(item => item._id === i);
      result.push({
        month: `${selectedYear}-${i.toString().padStart(2, '0')}`,
        revenue: monthData ? monthData.revenue : 0
      });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching monthly revenue:', error);
    res.status(500).json({ message: 'Error fetching monthly revenue', error: error.message });
  }
});

// Get yearly revenue
router.get('/yearly-revenue', async (req, res) => {
  try {
    const currentYear = new Date().getFullYear();
    const startYear = currentYear - 4; // Get 5 years of data
    
    const yearlyRevenue = await Command.aggregate([
      {
        $match: {
          status: { $ne: 'cancelled' },
          createdAt: { $gte: new Date(`${startYear}-01-01`) }
        }
      },
      {
        $group: {
          _id: { $year: '$createdAt' },
          revenue: { $sum: '$totalAmount' }
        }
      },
      { $sort: { _id: 1 } }
    ]);
    
    // Format the result to include all years
    const result = [];
    for (let year = startYear; year <= currentYear; year++) {
      const yearData = yearlyRevenue.find(item => item._id === year);
      result.push({
        year: year.toString(),
        revenue: yearData ? yearData.revenue : 0
      });
    }
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching yearly revenue:', error);
    res.status(500).json({ message: 'Error fetching yearly revenue', error: error.message });
  }
});

// Get best selling products
router.get('/best-selling-products', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    
    const bestSellingProducts = await Command.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $unwind: '$products' },
      {
        $group: {
          _id: '$products.product',
          name: { $first: '$products.name' },
          total_sold: { $sum: '$products.quantity' },
          total_revenue: { $sum: { $multiply: ['$products.price', '$products.quantity'] } }
        }
      },
      { $sort: { total_sold: -1 } },
      { $limit: parseInt(limit) }
    ]);
    
    res.json(bestSellingProducts);
  } catch (error) {
    console.error('Error fetching best selling products:', error);
    res.status(500).json({ message: 'Error fetching best selling products', error: error.message });
  }
});

// Get product categories
router.get('/product-categories', async (req, res) => {
  try {
    // Use the actual product categories from the Product schema
    const productCategories = await Product.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // Format the result
    const result = productCategories.map(category => ({
      name: category._id || 'Uncategorized',
      count: category.count
    }));
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching product categories:', error);
    res.status(500).json({ message: 'Error fetching product categories', error: error.message });
  }
});

// Get sales by category
router.get('/sales-by-category', async (req, res) => {
  try {
    const salesByCategory = await Command.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $unwind: '$products' },
      {
        $lookup: {
          from: 'products',
          localField: 'products.product',
          foreignField: '_id',
          as: 'productInfo'
        }
      },
      { $unwind: { path: '$productInfo', preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: { $ifNull: ['$productInfo.category', 'Uncategorized'] },
          total_sales: { $sum: { $multiply: ['$products.price', '$products.quantity'] } },
          total_items: { $sum: '$products.quantity' }
        }
      },
      { $sort: { total_sales: -1 } }
    ]);
    
    // If no data found, use predefined categories
    if (salesByCategory.length === 0) {
      const predefinedCategories = [
        'Moisturizers', 'Cleansers', 'Eye creams', 'Sheet masks', 'Serums', 'Sunscreens'
      ];
      
      res.json(predefinedCategories.map(category => ({
        category,
        total_sales: 0,
        total_items: 0
      })));
    } else {
      res.json(salesByCategory.map(item => ({
        category: item._id,
        total_sales: item.total_sales,
        total_items: item.total_items
      })));
    }
  } catch (error) {
    console.error('Error fetching sales by category:', error);
    res.status(500).json({ message: 'Error fetching sales by category', error: error.message });
  }
});

// Get sales by parapharmacy (location)
router.get('/sales-by-location', async (req, res) => {
  try {
    const salesByParapharmacy = await Command.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      {
        $group: {
          _id: '$parapharmacy',
          total_orders: { $sum: 1 },
          total_sales: { $sum: '$totalAmount' }
        }
      },
      {
        $lookup: {
          from: 'parapharmacies',
          localField: '_id',
          foreignField: '_id',
          as: 'parapharmacyInfo'
        }
      },
      { $unwind: { path: '$parapharmacyInfo', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          id: '$_id',
          name: { $ifNull: ['$parapharmacyInfo.name', 'Unknown Parapharmacy'] },
          location: { $ifNull: ['$parapharmacyInfo.address', 'Unknown Location'] },
          region: {
            $cond: {
              if: { $eq: [{ $ifNull: ['$parapharmacyInfo.address', ''] }, ''] },
              then: 'Unknown',
              else: {
                $switch: {
                  branches: [
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Tunis/i } }, then: 'Tunis' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Ariana/i } }, then: 'Ariana' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Ben Arous/i } }, then: 'Ben Arous' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Manouba/i } }, then: 'Manouba' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Nabeul/i } }, then: 'Nabeul' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Zaghouan/i } }, then: 'Zaghouan' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Bizerte/i } }, then: 'Bizerte' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Béja|Beja/i } }, then: 'Béja' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Jendouba/i } }, then: 'Jendouba' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Kef|Le Kef/i } }, then: 'Le Kef' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Siliana/i } }, then: 'Siliana' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Sousse/i } }, then: 'Sousse' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Monastir/i } }, then: 'Monastir' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Mahdia/i } }, then: 'Mahdia' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Sfax/i } }, then: 'Sfax' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Kairouan/i } }, then: 'Kairouan' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Kasserine/i } }, then: 'Kasserine' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Sidi Bouzid/i } }, then: 'Sidi Bouzid' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Gabès|Gabes/i } }, then: 'Gabès' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Medenine/i } }, then: 'Medenine' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Tataouine/i } }, then: 'Tataouine' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Gafsa/i } }, then: 'Gafsa' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Tozeur/i } }, then: 'Tozeur' },
                    { case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: /Kebili/i } }, then: 'Kebili' }
                  ],
                  default: 'Other'
                }
              }
            }
          },
          total_orders: 1,
          sales: '$total_sales'
        }
      },
      { $sort: { sales: -1 } }
    ]);
    
    res.json(salesByParapharmacy);
  } catch (error) {
    console.error('Error fetching sales by location:', error);
    res.status(500).json({ message: 'Error fetching sales by location', error: error.message });
  }
});

// Get sales by region
router.get('/sales-by-region', async (req, res) => {
  try {
    // Tunisian regions
    const tunisianRegions = [
      'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte', 
      'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia', 
      'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 'Medenine', 
      'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
    ];
    
    const salesByRegion = await Command.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      {
        $lookup: {
          from: 'parapharmacies',
          localField: 'parapharmacy',
          foreignField: '_id',
          as: 'parapharmacyInfo'
        }
      },
      { $unwind: { path: '$parapharmacyInfo', preserveNullAndEmptyArrays: true } },
      {
        $addFields: {
          region: {
            $cond: {
              if: { $eq: [{ $ifNull: ['$parapharmacyInfo.address', ''] }, ''] },
              then: 'Unknown',
              else: {
                $switch: {
                  branches: tunisianRegions.map(region => ({
                    case: { $regexMatch: { input: '$parapharmacyInfo.address', regex: new RegExp(region, 'i') } },
                    then: region
                  })),
                  default: 'Other'
                }
              }
            }
          }
        }
      },
      {
        $group: {
          _id: '$region',
          total_sales: { $sum: '$totalAmount' },
          total_orders: { $sum: 1 }
        }
      },
      { $sort: { total_sales: -1 } }
    ]);
    
    // Create a complete list with all regions, even those with 0 sales
    const result = tunisianRegions.map(region => {
      const found = salesByRegion.find(item => item._id === region);
      return {
        region,
        total_sales: found ? found.total_sales : 0,
        total_orders: found ? found.total_orders : 0
      };
    });
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching sales by region:', error);
    res.status(500).json({ message: 'Error fetching sales by region', error: error.message });
  }
});

// Get parapharmacies by region
router.get('/parapharmacies-by-region', async (req, res) => {
  try {
    // Tunisian regions
    const tunisianRegions = [
      'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 'Bizerte', 
      'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse', 'Monastir', 'Mahdia', 
      'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 'Medenine', 
      'Tataouine', 'Gafsa', 'Tozeur', 'Kebili'
    ];
    
    // This is a simplified approach - in a real application, you would need to
    // extract region from address or have a dedicated region field
    const parapharmaciesByRegion = await Parapharmacie.aggregate([
      {
        $addFields: {
          region: {
            $switch: {
              branches: tunisianRegions.map(region => ({
                case: { $regexMatch: { input: "$address", regex: new RegExp(region, "i") } },
                then: region
              })),
              default: "Other"
            }
          }
        }
      },
      { $group: { _id: "$region", count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // Create a complete list with all regions, even those with 0 parapharmacies
    const result = tunisianRegions.map(region => {
      const found = parapharmaciesByRegion.find(item => item._id === region);
      return {
        region,
        count: found ? found.count : 0
      };
    });
    
    res.json(result);
  } catch (error) {
    console.error('Error fetching parapharmacies by region:', error);
    res.status(500).json({ message: 'Error fetching parapharmacies by region', error: error.message });
  }
});

// Get dashboard overview statistics
router.get('/dashboard', async (req, res) => {
  try {
    // Get total parapharmacies
    const totalParapharmacies = await Parapharmacie.countDocuments();
    
    // Get total users
    const totalUsers = await User.countDocuments();
    
    // Get total orders
    const totalOrders = await Command.countDocuments();
    
    // Get total revenue
    const revenueResult = await Command.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);
    const totalRevenue = revenueResult.length > 0 ? revenueResult[0].total : 0;
    
    // Get recent orders (last 7 days)
    const lastWeek = new Date();
    lastWeek.setDate(lastWeek.getDate() - 7);
    
    const recentOrders = await Command.countDocuments({
      createdAt: { $gte: lastWeek }
    });
    
    // Get new users (last 30 days)
    const lastMonth = new Date();
    lastMonth.setDate(lastMonth.getDate() - 30);
    
    const newUsers = await User.countDocuments({
      createdAt: { $gte: lastMonth }
    });
    
    // Get orders by status
    const ordersByStatus = await Command.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);
    
    // Format orders by status
    const formattedOrdersByStatus = {};
    ordersByStatus.forEach(item => {
      formattedOrdersByStatus[item._id] = item.count;
    });
    
    res.json({
      totalParapharmacies,
      totalUsers,
      newUsers,
      totalOrders,
      totalRevenue,
      recentOrders,
      ordersByStatus: formattedOrdersByStatus
    });
  } catch (error) {
    console.error('Error fetching dashboard statistics:', error);
    res.status(500).json({ message: 'Error fetching dashboard statistics', error: error.message });
  }
});

module.exports = router;