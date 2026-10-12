// models/Command.js
const mongoose = require('mongoose');

const CommandSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Add parapharmacy field to track which parapharmacy the order belongs to
  parapharmacy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Since parapharmacies are stored in the User model with para: true
    required: true
  },
  products: [
    {
      product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
      },
      quantity: {
        type: Number,
        required: true,
        min: 1
      },
      price: {
        type: Number,
        required: true
      },
      name: String,
      image: String
    }
  ],
  totalAmount: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'shipped', 'delivered', 'cancelled'],
    default: 'pending'
  },
  shippingAddress: {
    address: String,
    city: String,
    postalCode: String,
    country: String
  },
  paymentMethod: {
    type: String,
    enum: ['cash_on_delivery', 'credit_card', 'paypal'],
    default: 'cash_on_delivery'
  },
  isPaid: {
    type: Boolean,
    default: false
  },
  paidAt: {
    type: Date
  },
  deliveredAt: {
    type: Date
  }
}, { timestamps: true });

module.exports = mongoose.model('Command', CommandSchema);