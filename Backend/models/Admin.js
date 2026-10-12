const mongoose = require("mongoose")
const Schema = mongoose.Schema

const AdminSchema = new Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
  },
  admin: {
    type: Boolean,
    default: true,
  },
  resetCode: {
    type: String,
    default: null,
  },
  resetCodeExpiry: {
    type: Date,
    default: null,
  },
  name: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
})

module.exports = mongoose.model("Admin", AdminSchema)
