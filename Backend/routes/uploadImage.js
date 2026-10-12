const express = require("express")
const multer = require("multer")
const router = express.Router()
const jwt = require("jsonwebtoken")
const Parapharmacie = require("../models/Parapharmacie")
const User = require("../models/User")
const fs = require("fs")
const path = require("path")

// Middleware to verify token
const verifyToken = (req, res, next) => {
  const token = req.header("Authorization") && req.header("Authorization").split(" ")[1]

  if (!token) {
    return res.status(401).json({ message: "No token provided, authorization denied." })
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET)
    req.userId = decoded.userId
    req.isParapharmacie = decoded.isParapharmacie
    next()
  } catch (error) {
    return res.status(400).json({ message: "Invalid token" })
  }
}

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "..", "uploads")
const profilePicsDir = path.join(uploadsDir, "profile_pictures")

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true })
}
if (!fs.existsSync(profilePicsDir)) {
  fs.mkdirSync(profilePicsDir, { recursive: true })
}

// Configure multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, profilePicsDir) // Save files in uploads/profile_pictures folder
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9)
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg' // Default to .jpg if no extension
    cb(null, uniqueSuffix + ext)
  },
})

// Less strict file filter that accepts common image types
const fileFilter = (req, file, cb) => {
  console.log("File mimetype:", file.mimetype)
  console.log("File originalname:", file.originalname)
  
  // Accept any file with image/* mimetype
  if (file.mimetype.startsWith("image/")) {
    return cb(null, true)
  }
  
  // Also accept files with common image extensions regardless of mimetype
  const ext = path.extname(file.originalname).toLowerCase()
  if ([".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"].includes(ext)) {
    return cb(null, true)
  }
  
  // Reject other files
  cb(new Error("Only image files are allowed"), false)
}

// Error handling middleware for multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    // A Multer error occurred when uploading
    return res.status(400).json({
      success: false,
      message: `Upload error: ${err.message}`
    })
  } else if (err) {
    // An unknown error occurred
    return res.status(400).json({
      success: false,
      message: `Upload error: ${err.message}`
    })
  }
  // No error occurred, continue
  next()
}

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // Increased to 10MB limit
  },
})

// Route to update profile picture
router.put("/updateProfilePicture", verifyToken, (req, res, next) => {
  // Use single upload with error handling
  upload.single("profilePicture")(req, res, (err) => {
    if (err) {
      console.error("Multer error:", err)
      return res.status(400).json({ 
        success: false,
        message: `Upload error: ${err.message}` 
      })
    }
    next()
  })
}, async (req, res) => {
  try {
    console.log("Processing profile picture update request")

    if (!req.file) {
      return res.status(400).json({ 
        success: false,
        message: "No file uploaded" 
      })
    }

    const imagePath = req.file.path.replace(/\\/g, "/") // Normalize path for all platforms
    const relativePath = imagePath.replace(/^.*\/uploads\//, "uploads/") // Get path relative to server root
    const userId = req.userId

    console.log("User ID:", userId)
    console.log("Image path:", relativePath)
    console.log("File details:", req.file)

    // Check if this is a parapharmacy account
    if (req.isParapharmacie) {
      console.log("Updating parapharmacy profile picture")
      // Update parapharmacy in database
      const updatedPara = await Parapharmacie.findByIdAndUpdate(userId, { image: relativePath }, { new: true }).select(
        "-password",
      )

      if (!updatedPara) {
        return res.status(404).json({ 
          success: false,
          message: "Parapharmacy not found" 
        })
      }

      res.status(200).json({
        success: true,
        message: "Profile picture updated successfully",
        imageUrl: relativePath,
      })
    } else {
      console.log("Updating user profile picture")
      // Updatuser in database
      const updatedUser = await User.findByIdAndUpdate(userId, { profilePicture: relativePath }, { new: true }).select(
        "-password",
      )

      if (!updatedUser) {
        return res.status(404).json({ 
          success: false,
          message: "User not found" 
        })
      }

      res.status(200).json({
        success: true,
        message: "Profile picture updated successfully",
        imageUrl: relativePath,
      })
    }
  } catch (error) {
    console.error("Error updating profile picture:", error)
    res.status(500).json({
      success: false,
      message: "Error updating profile picture",
      error: error.message,
    })
  }
})

module.exports = router
