const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Generate a random verification code
const generateVerificationCode = () => {
  return crypto.randomBytes(3).toString('hex'); // Generates a 6-character code
};

// Generate a JWT token
const generateToken = (user) => {
  return jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
};

module.exports = { generateVerificationCode, generateToken };