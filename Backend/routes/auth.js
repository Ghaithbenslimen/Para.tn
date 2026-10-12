const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Parapharmacie = require('../models/Parapharmacie');

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

// -------------------
// USER SIGNUP ROUTE (for normal users only)
// -------------------
router.post('/signup', async (req, res) => {
  try {
    const { username, email, password, confirmPassword } = req.body;
    if (!username || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: 'All fields are required.' });
    }
    if (password !== confirmPassword) {
      return res.status(400).json({ message: 'Passwords do not match.' });
    }
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res
        .status(400)
        .json({ message: 'User with that email already exists.' });
    }
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const newUser = new User({
      username,
      email,
      password: hashedPassword,
    });
    await newUser.save();
    res.status(201).json({ message: 'User created successfully.' });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Server error during signup.' });
  }
});

// -------------------
// PARAPHARMACIE SIGNUP ROUTE
// -------------------
router.post('/signup-parapharmacie', async (req, res) => {
  try {
    const {
      name,
      phone,
      email,
      address,
      description,
      password,
      confirmPassword,
      image,
    } = req.body;
    if (!name || !phone || !email || !address || !password || !confirmPassword) {
      return res
        .status(400)
        .json({ message: 'All required fields must be provided.' });
    }
    if (password !== confirmPassword) {
      return res.status(400).json({ message: 'Passwords do not match.' });
    }
    const existingPara = await Parapharmacie.findOne({ email });
    if (existingPara) {
      return res
        .status(400)
        .json({ message: 'Parapharmacie with that email already exists.' });
    }
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const newParapharmacie = new Parapharmacie({
      para: true,
      name,
      phone,
      email,
      address,
      description,
      image: image || '',
      password: hashedPassword,
    });
    await newParapharmacie.save();
    res
      .status(201)
      .json({ message: 'Parapharmacie account created successfully.' });
  } catch (error) {
    console.error('Parapharmacie signup error:', error);
    res
      .status(500)
      .json({ message: 'Server error during parapharmacie signup.' });
  }
});

// -------------------
// LOGIN ROUTE (for both normal users and parapharmacie)
// -------------------
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res
        .status(400)
        .json({ message: 'Email and password are required.' });
    }
    // Check if the email belongs to a parapharmacie account.
    const paraAccount = await Parapharmacie.findOne({ email });
    if (paraAccount) {
      const isMatch = await bcrypt.compare(password, paraAccount.password);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid credentials.' });
      }
      // Generate a token (expires in 7 days)
      const payload = { userId: paraAccount._id, isParapharmacie: true };
      const token = jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: '7d',
      });
      return res.json({
        message: 'Logged in successfully as parapharmacie.',
        token,
      });
    }
    // Otherwise, check for a normal user.
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }
    const payload = { userId: user._id, isParapharmacie: false };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });
    return res.json({ message: 'Logged in successfully as user.', token });
  } catch (error) {
    console.error('Login error:', error);
    return res
      .status(500)
      .json({ message: 'Server error during login.' });
  }
});

// -------------------
// PROFILE ROUTE - Enhanced version
// -------------------
router.get('/profile', verifyToken, async (req, res) => {
  try {
    if (req.isParapharmacie) {
      const paraAccount = await Parapharmacie.findById(req.userId).select(
        '-password'
      );
      if (!paraAccount) {
        return res.status(404).json({ message: 'Parapharmacie not found.' });
      }
      return res.json({
        _id: paraAccount._id,
        name: paraAccount.name,
        phone: paraAccount.phone,
        email: paraAccount.email,
        address: paraAccount.address,
        description: paraAccount.description,
        image: paraAccount.image,
        isParapharmacie: true,
      });
    } else {
      const user = await User.findById(req.userId).select('-password');
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      return res.json({
        _id: user._id,
        username: user.username,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        location: user.location,
        country: user.country,
        profilePicture: user.profilePicture,
        isParapharmacie: false,
      });
    }
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({
      message: 'Server error while fetching profile.',
      error,
    });
  }
});

module.exports = router;
