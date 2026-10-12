const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  fullName: { type: String },
  phone: { type: String },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [0, 0]
    },
    address: { type: String, default: '' }
  },
  country: { type: String },
  resetCode: { type: String },
  resetCodeExpiry: { type: Date },
  profilePicture: { type: String } // Field for profile picture
}, { timestamps: true });

// Add geospatial index for location-based queries
UserSchema.index({ "location": '2dsphere' });

module.exports = mongoose.model('User', UserSchema);