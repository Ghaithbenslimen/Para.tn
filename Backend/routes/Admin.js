const express = require("express")
const router = express.Router()
const bcrypt = require("bcrypt")
const jwt = require("jsonwebtoken")
const Admin = require("../models/Admin")
const crypto = require("crypto")
const nodemailer = require("nodemailer")
const { generateVerificationCode, generateToken } = require("../helpers")

// Middleware to verify admin token
const verifyAdminToken = (req, res, next) => {
  const token = req.header("Authorization")?.split(" ")[1]

  if (!token) {
    return res.status(401).json({ message: "Access denied. No token provided." })
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET)

    // Check if the user is an admin
    if (!decoded.isAdmin) {
      return res.status(403).json({ message: "Access denied. Admin privileges required." })
    }

    req.adminId = decoded.userId
    next()
  } catch (error) {
    return res.status(400).json({ message: "Invalid token" })
  }
}

// Create admin account (protected - only for initial setup or super admin)
router.post("/create", async (req, res) => {
  try {
    const { name, email, password } = req.body

    if (!name || !email || !password) {
      return res.status(400).json({ message: "All fields are required." })
    }

    // Check if admin already exists
    const existingAdmin = await Admin.findOne({ email })
    if (existingAdmin) {
      return res.status(400).json({ message: "Admin with that email already exists." })
    }

    // Hash password
    const saltRounds = 10
    const hashedPassword = await bcrypt.hash(password, saltRounds)

    // Create new admin
    const newAdmin = new Admin({
      name,
      email,
      password: hashedPassword,
      admin: true,
    })

    await newAdmin.save()
    res.status(201).json({ message: "Admin account created successfully." })
  } catch (error) {
    console.error("Admin creation error:", error)
    res.status(500).json({ message: "Server error during admin creation." })
  }
})

// Admin login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required." })
    }

    // Find admin by email
    const admin = await Admin.findOne({ email })
    if (!admin) {
      return res.status(400).json({ message: "Invalid credentials." })
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, admin.password)
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials." })
    }

    // Check if user is an admin
    if (!admin.admin) {
      return res.status(403).json({ message: "Access denied. Admin privileges required." })
    }

    // Generate JWT token
    const payload = {
      userId: admin._id,
      isAdmin: true,
    }

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "24h" })

    res.json({
      message: "Admin logged in successfully.",
      token,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
      },
    })
  } catch (error) {
    console.error("Admin login error:", error)
    res.status(500).json({ message: "Server error during login." })
  }
})

// Get admin profile
router.get("/profile", verifyAdminToken, async (req, res) => {
  try {
    const admin = await Admin.findById(req.adminId).select("-password")

    if (!admin) {
      return res.status(404).json({ message: "Admin not found." })
    }

    res.json(admin)
  } catch (error) {
    console.error("Admin profile error:", error)
    res.status(500).json({ message: "Server error while fetching admin profile." })
  }
})

// Forget password route
router.post("/forgetpassword", async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ message: "Email is required." });
    }
    
    // Find admin by email
    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ message: "Admin not found" });
    }
    
    // Generate a verification code (alphanumeric)
    const verificationCode = generateVerificationCode();
    
    // Set expiry time (3 minutes from now)
    const resetCodeExpiry = new Date();
    resetCodeExpiry.setMinutes(resetCodeExpiry.getMinutes() + 3);
    
    // Update admin with reset code and expiry
    admin.resetCode = verificationCode;
    admin.resetCodeExpiry = resetCodeExpiry;
    await admin.save();
    
    // Create email transporter
    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const emailHtml = `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Password Reset Verification</title>
        <style>
            body {
                font-family: 'Arial', sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }
            .header {
                background-color:rgb(68, 224, 128);
                color: white;
                padding: 20px;
                text-align: center;
                border-radius: 5px 5px 0 0;
            }
            .content {
                padding: 30px;
                background-color: #f9f9f9;
                border-radius: 0 0 5px 5px;
                border: 1px solid #ddd;
                border-top: none;
            }
            .code {
                font-size: 24px;
                font-weight: bold;
                text-align: center;
                margin: 25px 0;
                padding: 15px;
                background-color: #e9f0f9;
                border-radius: 5px;
                letter-spacing: 3px;
            }
            .footer {
                margin-top: 30px;
                font-size: 12px;
                color: #777;
                text-align: center;
            }
            .button {
                display: inline-block;
                padding: 10px 20px;
                background-color:rgb(172, 209, 177);
                color: white;
                text-decoration: none;
                border-radius: 5px;
                margin-top: 15px;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Password Reset Request</h1>
        </div>
        <div class="content">
            <p>Hello,</p>
            <p>We received a request to reset your password. Please use the following verification code to proceed:</p>
            
            <div class="code">${verificationCode}</div>
            
            <p>This code will expire in 3 minutes. If you didn't request a password reset, please ignore this email or contact support if you have questions.</p>
            
            <p>Thank you,<br>The Support Team</p>
        </div>
    </body>
    </html>
    `;

    await transporter.sendMail({
      from: `"Admin Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Password Reset Verification Code",
      html: emailHtml,
      text: `Your verification code is: ${verificationCode}\n\nThis code will expire in 3 minutes. If you didn't request a password reset, please ignore this email.`
    });
    
    res.status(200).json({ message: 'Recovery code sent successfully' });
  } catch (error) {
    console.error('Password recovery error:', error);
    res.status(500).json({ message: 'Server error during password recovery' });
  }
});

// Verify code route
router.post("/verify", async (req, res) => {
  try {
    const { email, verificationCode } = req.body;
    
    if (!email || !verificationCode) {
      return res.status(400).json({ message: "Email and verification code are required." });
    }
    
    // Find admin by email
    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }
    
    console.log("Stored code:", admin.resetCode);
    console.log("Received code:", verificationCode);
    
    // Convert both codes to uppercase for case-insensitive comparison
    const storedCode = admin.resetCode ? admin.resetCode.toUpperCase() : null;
    const receivedCode = verificationCode.toUpperCase();
    
    // Check if code is valid and not expired
    if (storedCode !== receivedCode) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }
    
    if (!admin.resetCodeExpiry || new Date() > admin.resetCodeExpiry) {
      return res.status(400).json({ message: 'Verification code has expired' });
    }
    
    // Generate a reset token
    const token = jwt.sign(
      { userId: admin._id, isAdmin: true },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );
    
    res.status(200).json({ message: 'Code verified successfully', token });
  } catch (error) {
    console.error('Code verification error:', error);
    res.status(500).json({ message: 'Server error during code verification' });
  }
});

// Reset password route
router.post("/reset-password", async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    
    if (!token || !newPassword) {
      return res.status(400).json({ message: "Token and new password are required." });
    }
    
    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(401).json({ message: 'Invalid or expired token' });
    }
    
    // Find admin by ID from token
    const admin = await Admin.findById(decoded.userId);
    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }
    
    // Hash the new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    
    // Update admin password and clear reset code fields
    admin.password = hashedPassword;
    admin.resetCode = null;
    admin.resetCodeExpiry = null;
    await admin.save();
    
    res.status(200).json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Password reset error:', error);
    res.status(500).json({ message: 'Server error during password reset' });
  }
});

// Test route to check server connection
router.get("/test", (req, res) => {
  res.status(200).json({ message: 'Server is running' });
});

module.exports = router