const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
  parapharmacie: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Parapharmacie',
    required: true
  },
  name: { 
    type: String, 
    required: true 
  },
  category: { 
    type: String, 
    required: true,
    enum: ['Moisturizers', 'Cleansers', 'Eye creams', 'Sheet masks', 'Serums', 'Sunscreens']
  },
  price: { 
    type: Number, 
    required: true 
  },
  quantity: { 
    type: Number, 
    required: true 
  },
  hasDiscount: { 
    type: Boolean, 
    default: false 
  },
  discountPercentage: { 
    type: Number, 
    default: 0 
  },
  description: { 
    type: String, 
    required: true 
  },
  howToUse: { 
    type: String, 
    required: true 
  },
  image: { 
    type: String, 
    required: true 
  },
  intelfaceassis: {
    type: String,
    enum: ['none', 'Acne', 'Actinic Keratosis', 'Basal Cell Carcinoma', 'Eczema', 'Rosacea'],
    default: 'none'
  },
  skinTypes: {  // NEW: Array of skin types
    type: [String],
    enum: ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'],
    default: []
  }
}, { timestamps: true });

module.exports = mongoose.model('Product', ProductSchema);