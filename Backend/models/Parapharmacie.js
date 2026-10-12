const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  user: { type: String, default: 'Anonymous' },
  rating: { type: Number, required: true },
  comment: { type: String, required: true },
  date: { type: Date, default: Date.now },
});

const ParapharmacieSchema = new mongoose.Schema({
  para: { type: Boolean, default: true },
  name: { type: String, required: true },
  address: { type: String, required: true },
  description: String,
  image: String,
  phone: String,
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [0, 0]
    }
  },
  reviews: [ReviewSchema],
  rating: { type: Number, default: 0 }, // overall rating (average)
});

// Add geospatial index for location-based queries
ParapharmacieSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Parapharmacie', ParapharmacieSchema);