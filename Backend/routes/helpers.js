// Generate verification code (alphanumeric if alphanumeric=true)
const generateVerificationCode = (alphanumeric = false) => {
    const length = 6;
    let result = '';
    const numbers = '0123456789';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    
    if (alphanumeric) {
      // Alphanumeric code (letters and numbers)
      const characters = numbers + chars;
      for (let i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * characters.length));
      }
    } else {
      // Numeric code (only numbers)
      for (let i = 0; i < length; i++) {
        result += numbers.charAt(Math.floor(Math.random() * numbers.length));
      }
    }
    
    return result;
  };
  
  // Generate JWT token
  const generateToken = (user) => {
    return jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
  };
  
  module.exports = {
    generateVerificationCode,
    generateToken
  };