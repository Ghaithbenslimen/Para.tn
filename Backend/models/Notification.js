const mongoose = require("mongoose")

const NotificationSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: ["general", "promotion", "update", "reminder"],
      default: "general",
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Parapharmacie",
      required: true,
    },
    senderName: {
      type: String,
      required: true,
    },
    recipients: {
      type: String,
      enum: ["all", "specific"],
      default: "all",
    },
    specificUsers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      default: null,
    },
    productName: {
      type: String,
      default: "",
    },
    productImage: {
      type: String,
      default: "",
    },
    isRead: {
      type: Map,
      of: Boolean,
      default: {},
    },
    expiresAt: {
      type: Date,
      default: () => new Date(+new Date() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true },
)

// Index for faster queries
NotificationSchema.index({ sender: 1, createdAt: -1 })
NotificationSchema.index({ isRead: 1 })
NotificationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }) // TTL index for auto-deletion

module.exports = mongoose.model("Notification", NotificationSchema)
