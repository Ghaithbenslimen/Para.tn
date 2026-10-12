const express = require("express")
const router = express.Router()
const Notification = require("../models/Notification")
const Product = require("../models/Product")
const jwt = require("jsonwebtoken")

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

// Middleware to verify parapharmacie
const verifyParapharmacie = (req, res, next) => {
  if (!req.isParapharmacie) {
    return res.status(403).json({ message: "Access denied. Parapharmacie account required." })
  }
  next()
}

// Create a new notification (parapharmacie only)
router.post("/", verifyToken, verifyParapharmacie, async (req, res) => {
  try {
    const { title, message, type, recipients, specificUsers, productId, productName, productImage } = req.body

    if (!title || !message) {
      return res.status(400).json({ message: "Title and message are required" })
    }

    // Create notification
    const notification = new Notification({
      title,
      message,
      type: type || "general",
      sender: req.userId,
      senderName: req.body.senderName,
      recipients: recipients || "all",
      specificUsers: specificUsers || [],
      productId: productId || null,
      productName: productName || "",
      productImage: productImage || "",
    })

    await notification.save()
    res.status(201).json({ message: "Notification created successfully", notification })
  } catch (error) {
    console.error("Error creating notification:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Get all notifications for a parapharmacie (admin view)
router.get("/admin", verifyToken, verifyParapharmacie, async (req, res) => {
  try {
    const notifications = await Notification.find({ sender: req.userId }).sort({ createdAt: -1 }).limit(100)

    res.json(notifications)
  } catch (error) {
    console.error("Error fetching notifications:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Get notifications for a user
router.get("/user", verifyToken, async (req, res) => {
  try {
    // Find notifications that are either for all users or specifically for this user
    const notifications = await Notification.find({
      $or: [{ recipients: "all" }, { recipients: "specific", specificUsers: req.userId }],
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 })
      .limit(50)

    // Mark which ones are read by this user
    const processedNotifications = notifications.map((notification) => {
      const notifObj = notification.toObject()
      notifObj.isReadByUser = notification.isRead && notification.isRead.get(req.userId.toString()) === true
      return notifObj
    })

    res.json(processedNotifications)
  } catch (error) {
    console.error("Error fetching user notifications:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// NEW ENDPOINT: Get public notifications (no authentication required)
router.get("/public", async (req, res) => {
  try {
    // Find notifications that are for all users and not expired
    const notifications = await Notification.find({
      recipients: "all",
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 })
      .limit(20) // Limit to 20 most recent notifications for public view

    // For public notifications, we don't have user-specific read status
    const processedNotifications = notifications.map((notification) => {
      const notifObj = notification.toObject()
      notifObj.isReadByUser = false // Always mark as unread for public view
      return notifObj
    })

    res.json(processedNotifications)
  } catch (error) {
    console.error("Error fetching public notifications:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Mark notification as read
router.put("/read/:id", verifyToken, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id)

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" })
    }

    // Update the isRead map for this user
    notification.isRead.set(req.userId.toString(), true)
    await notification.save()

    res.json({ message: "Notification marked as read" })
  } catch (error) {
    console.error("Error marking notification as read:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Delete a notification (parapharmacie only)
router.delete("/:id", verifyToken, verifyParapharmacie, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id)

    if (!notification) {
      return res.status(404).json({ message: "Notification not found" })
    }

    // Ensure the parapharmacie can only delete their own notifications
    if (notification.sender.toString() !== req.userId.toString()) {
      return res.status(403).json({ message: "Not authorized to delete this notification" })
    }

    await notification.deleteOne()
    res.json({ message: "Notification deleted successfully" })
  } catch (error) {
    console.error("Error deleting notification:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Get unread count for a user
router.get("/unread-count", verifyToken, async (req, res) => {
  try {
    const notifications = await Notification.find({
      $or: [{ recipients: "all" }, { recipients: "specific", specificUsers: req.userId }],
      expiresAt: { $gt: new Date() },
    })

    // Count notifications where this user hasn't read it
    const unreadCount = notifications.filter(
      (notification) => !notification.isRead || !notification.isRead.get(req.userId.toString()),
    ).length

    res.json({ unreadCount })
  } catch (error) {
    console.error("Error fetching unread count:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

// Clear all notifications for a user - CHANGED from DELETE to PUT
router.put("/clear-all", verifyToken, async (req, res) => {
  try {
    // Find notifications that are either for all users or specifically for this user
    const notifications = await Notification.find({
      $or: [{ recipients: "all" }, { recipients: "specific", specificUsers: req.userId }],
      expiresAt: { $gt: new Date() },
    })

    // Mark each notification as read for this user
    let modifiedCount = 0
    for (const notification of notifications) {
      if (!notification.isRead || !notification.isRead.get(req.userId.toString())) {
        notification.isRead.set(req.userId.toString(), true)
        await notification.save()
        modifiedCount++
      }
    }

    res.json({
      message: "All notifications marked as read",
      modifiedCount: modifiedCount,
    })
  } catch (error) {
    console.error("Error clearing notifications:", error)
    res.status(500).json({ message: "Server error", error: error.message })
  }
})

module.exports = router
