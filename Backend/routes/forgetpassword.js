const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const Token = require('../models/Token');
const { generateVerificationCode, generateToken } = require('../helpers');

// Forgot Password (Verification Code) Route
router.post("/forgetpassword", async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    const verificationCode = generateVerificationCode();
    user.resetCode = verificationCode;
    user.resetCodeExpiry = Date.now() + 3600000; // 1 hour from now
    await user.save();

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
            
            <p>This code will expire in 1 hour. If you didn't request a password reset, please ignore this email or contact support if you have questions.</p>
            
            <p>Thank you,<br>The Support Team</p>
            
            
        </div>
    </body>
    </html>
    `;

    await transporter.sendMail({
      from: `"Para.tn" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Password Reset Verification Code",
      html: emailHtml,
      text: `Your verification code is: ${verificationCode}\n\nThis code will expire in 1 hour. If you didn't request a password reset, please ignore this email.`
    });

    res.status(201).send("Please check your email for the verification code.");
  } catch (error) {
    console.error(error);
    res.status(500).send("Error sending verification code.");
  }
});

// Verification Route
router.post("/verify", async (req, res) => {
  try {
    const { email, verificationCode } = req.body;
    const user = await User.findOne({ email, resetCode: verificationCode, resetCodeExpiry: { $gt: Date.now() } });
    if (!user) {
      return res.status(404).send("Invalid or expired verification code.");
    }

    const newToken = generateToken(user);
    const tokenDoc = new Token({
      userId: user._id,
      token: newToken,
    });
    await tokenDoc.save();

    res.status(200).send({ message: "Verified code successfully.", token: newToken });
  } catch (error) {
    console.error(error);
    res.status(500).send("Error verifying code.");
  }
});

// Reset Password Route
router.post("/reset-password", async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    const tokenDoc = await Token.findOne({ token });
    if (!tokenDoc) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    const user = await User.findById(tokenDoc.userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: "Password reset successfully" });
  } catch (error) {
    console.error("Error resetting password:", error);
    res.status(500).json({ message: "Failed to reset password" });
  }
});

module.exports = router;