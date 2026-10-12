const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Enable CORS for frontend requests
app.use(cors({
  origin: 'http://localhost:3001', // Your frontend URL
  credentials: true // Allow cookies to be sent with requests
}));

// Add a root test route for debugging connection issues
app.get('/test', (req, res) => {
  res.status(200).json({ message: 'Server is running' });
});

app.use(express.json());
app.use('/uploads', express.static('uploads')); // Serve uploaded files

// Import Routes
const authRoutes = require('./routes/auth');
const forgetPasswordRoutes = require('./routes/forgetpassword');
const signoutRoute = require('./routes/signout');
const updateUserRoutes = require('./routes/updateUser');
const uploadImageRoute = require('./routes/uploadImage');
const updateParapharmacyRoute = require('./routes/updateParapharmacy');
const productRoutes = require('./routes/product');
const parapharmacyRoutes = require('./routes/parapharmacy');
const locationRoutes = require('./routes/location');
const storeRoutes = require('./routes/store');
const adminRoutes = require("./routes/Admin") // Add admin routes
const paraRoutes = require('./routes/paraRoutes');
const wishlistRoutes = require('./routes/wishlist');
const commandRoutes = require('./routes/command');
const trackOrderRoutes = require('./routes/trackOrder'); // Add the new track order routes
const adminOrdersRoutes = require('./routes/adminOrders'); // Add the new admin orders routes
const statisticsRoutes = require('./routes/statistics');
const parapharmacyAdminRoutes = require('./routes/Adminparapharmacy');
const adminStatisticsRoutes = require('./routes/Adminstatistics'); // Add the new admin statistics routes
const notificationRoutes = require("./routes/notifications")
const complementaryRoutes = require('./routes/complementaryComparison');


// Use Routes
app.use('/auth', authRoutes);
app.use('/auth', forgetPasswordRoutes);
app.use('/auth', signoutRoute);
app.use('/auth', updateUserRoutes);
app.use('/auth', uploadImageRoute);
app.use('/auth', updateParapharmacyRoute);
app.use('/auth', productRoutes);
app.use('/api', parapharmacyRoutes); // Mount the parapharmacy route under /api
app.use('/api/location', locationRoutes);
app.use('/api/store', storeRoutes);
app.use("/admin", adminRoutes) // Mount admin routes under /admin (lowercase)
app.use('/api', paraRoutes); // Updated to use paraRoutes
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/commands', commandRoutes);
app.use('/api/track-orders', trackOrderRoutes); // Mount the track order routes
app.use('/api/admin/orders', adminOrdersRoutes); // Mount the admin orders routes
app.use('/api/statistics', statisticsRoutes);
app.use('/api/admin/parapharmacies', parapharmacyAdminRoutes);
app.use('/api/admin/statistics', adminStatisticsRoutes); // Mount the admin statistics routes
app.use("/api/notifications", notificationRoutes)
app.use('/api/complementary', complementaryRoutes);



mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('MongoDB Connected Successfully'))
  .catch((err) => console.error('MongoDB Connection Error:', err));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server Running On Port ${PORT}`));