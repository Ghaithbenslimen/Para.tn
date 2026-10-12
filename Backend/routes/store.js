const express = require("express")
const router = express.Router()
const mongoose = require("mongoose")
const Product = require("../models/Product") // Import your Product model
const Parapharmacy = require("../models/Parapharmacie") // Import your Parapharmacy model

// Middleware to log requests for debugging
router.use((req, res, next) => {
  console.log("Store API Request:", {
    method: req.method,
    path: req.path,
    query: req.query,
    params: req.params,
  })
  next()
})

// Get all products for a specific parapharmacy with filters
router.get("/parapharmacy/:parapharmacyId/products", async (req, res) => {
  try {
    const { parapharmacyId } = req.params
    const { category, skinType, sortBy, search } = req.query

    console.log(`Fetching products for parapharmacy: ${parapharmacyId}`)
    console.log(`Filters: category=${category}, skinType=${skinType}, sortBy=${sortBy}, search=${search}`)

    // Validate parapharmacy ID format
    if (!mongoose.Types.ObjectId.isValid(parapharmacyId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid parapharmacy ID format",
      })
    }

    // Build query filters
    const filter = { parapharmacie: parapharmacyId }

    // Add search filter if provided
    if (search && search.trim() !== "") {
      filter.name = { $regex: search, $options: "i" } // Case-insensitive search
    }

    // Add category filter if provided
    if (category && category !== "All") {
      filter.category = category
    }

    // Add skin type filter if provided
    if (skinType && skinType !== "All") {
      filter.skinTypes = skinType
    }

    // Build sort options
    let sortOptions = {}

    switch (sortBy) {
      case "price_asc":
      case "low":
        sortOptions = { price: 1 }
        break
      case "price_desc":
      case "high":
        sortOptions = { price: -1 }
        break
      case "newest":
        sortOptions = { createdAt: -1 }
        break
      case "popular":
      case "featured":
        // Assuming you have a field for popularity or featured products
        sortOptions = { featured: -1 }
        break
      default:
        // Default sorting (could be by popularity or name)
        sortOptions = { name: 1 }
    }

    console.log("Query filter:", filter)
    console.log("Sort options:", sortOptions)

    // Fetch products with applied filters and sorting
    const products = await Product.find(filter).sort(sortOptions)

    console.log(`Found ${products.length} products`)

    // Return the filtered products
    res.status(200).json({
      success: true,
      count: products.length,
      products: products,
    })
  } catch (error) {
    console.error("Error fetching products:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get product details by ID
router.get("/products/:productId", async (req, res) => {
  try {
    const { productId } = req.params

    // Validate product ID format
    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid product ID format",
      })
    }

    // Find the product by ID
    const product = await Product.findById(productId)

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      })
    }

    // Find the parapharmacy data for this product
    const parapharmacy = await Parapharmacy.findById(product.parapharmacie)

    // Return the product with parapharmacy info
    res.status(200).json({
      success: true,
      product,
      parapharmacy: parapharmacy
        ? {
            id: parapharmacy._id,
            name: parapharmacy.name,
            rating: parapharmacy.rating,
          }
        : null,
    })
  } catch (error) {
    console.error("Error fetching product details:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Search products by name across all parapharmacies
router.get("/products/search", async (req, res) => {
  try {
    const { query } = req.query
    
    if (!query || query.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Search query is required",
      })
    }

    // Find products matching the search query
    const products = await Product.aggregate([
      { 
        $match: { 
          name: { $regex: query, $options: "i" } // Case-insensitive search
        } 
      },
      {
        $lookup: {
          from: "parapharmacies",
          localField: "parapharmacie",
          foreignField: "_id",
          as: "parapharmacyInfo",
        },
      },
      { $unwind: "$parapharmacyInfo" },
      {
        $project: {
          _id: 1,
          name: 1,
          price: 1,
          category: 1,
          skinTypes: 1,
          hasDiscount: 1,
          discountPercentage: 1,
          effectivePrice: {
            $cond: {
              if: "$hasDiscount",
              then: { $subtract: ["$price", { $multiply: ["$price", { $divide: ["$discountPercentage", 100] }] }] },
              else: "$price",
            },
          },
          parapharmacy: {
            id: "$parapharmacyInfo._id",
            name: "$parapharmacyInfo.name",
          },
        },
      },
      { $sort: { name: 1 } },
    ])

    res.status(200).json({
      success: true,
      count: products.length,
      products: products,
    })
  } catch (error) {
    console.error("Error searching products:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get product price comparison across parapharmacies
router.get("/products/:productName/compare", async (req, res) => {
  try {
    const { productName } = req.params

    // Find all products with the same name across different parapharmacies
    const products = await Product.aggregate([
      { $match: { name: { $regex: productName, $options: "i" } } },
      {
        $lookup: {
          from: "parapharmacies", // The collection name in MongoDB
          localField: "parapharmacie",
          foreignField: "_id",
          as: "parapharmacyInfo",
        },
      },
      { $unwind: "$parapharmacyInfo" },
      {
        $project: {
          _id: 1,
          name: 1,
          price: 1,
          hasDiscount: 1,
          discountPercentage: 1,
          effectivePrice: {
            $cond: {
              if: "$hasDiscount",
              then: { $subtract: ["$price", { $multiply: ["$price", { $divide: ["$discountPercentage", 100] }] }] },
              else: "$price",
            },
          },
          parapharmacy: {
            id: "$parapharmacyInfo._id",
            name: "$parapharmacyInfo.name",
            rating: "$parapharmacyInfo.rating",
          },
        },
      },
      { $sort: { effectivePrice: 1 } },
    ])

    res.status(200).json({
      success: true,
      count: products.length,
      comparisons: products,
    })
  } catch (error) {
    console.error("Error comparing product prices:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get all unique categories and skin types for filters
router.get("/filters", async (req, res) => {
  try {
    // Get all unique categories
    const categories = await Product.distinct("category")

    // Get all unique skin types
    const skinTypes = await Product.distinct("skinTypes")

    // Flatten the skin types array (since skinTypes is an array field)
    const flattenedSkinTypes = [...new Set(skinTypes.flat().filter(Boolean))]

    res.status(200).json({
      success: true,
      categories,
      skinTypes: flattenedSkinTypes,
    })
  } catch (error) {
    console.error("Error fetching filter options:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get categories for a specific parapharmacy
router.get("/categories/parapharmacy/:parapharmacyId", async (req, res) => {
  try {
    const { parapharmacyId } = req.params

    // Validate parapharmacy ID format
    if (!mongoose.Types.ObjectId.isValid(parapharmacyId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid parapharmacy ID format",
      })
    }

    // Get all unique categories for this parapharmacy
    const categories = await Product.distinct("category", { parapharmacie: parapharmacyId })

    res.status(200).json({
      success: true,
      categories,
    })
  } catch (error) {
    console.error("Error fetching parapharmacy categories:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get skin types for a specific parapharmacy
router.get("/skin-types/parapharmacy/:parapharmacyId", async (req, res) => {
  try {
    const { parapharmacyId } = req.params

    // Validate parapharmacy ID format
    if (!mongoose.Types.ObjectId.isValid(parapharmacyId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid parapharmacy ID format",
      })
    }

    // Get all products for this parapharmacy
    const products = await Product.find({ parapharmacie: parapharmacyId })

    // Extract and flatten all skin types
    const skinTypesSet = new Set()
    products.forEach((product) => {
      if (product.skinTypes && product.skinTypes.length > 0) {
        product.skinTypes.forEach((type) => {
          if (type) skinTypesSet.add(type)
        })
      }
    })

    const skinTypes = Array.from(skinTypesSet)

    res.status(200).json({
      success: true,
      skinTypes,
    })
  } catch (error) {
    console.error("Error fetching parapharmacy skin types:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

module.exports = router