const express = require("express")
const router = express.Router()
const mongoose = require("mongoose")
const Product = require("../models/Product")
const Parapharmacie = require("../models/Parapharmacie")

// Get complementary products based on current product's attributes
router.get("/products/:productId/complementary", async (req, res) => {
  try {
    const { productId } = req.params

    // Validate product ID
    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid product ID format",
      })
    }

    // Find the current product to get its attributes
    const currentProduct = await Product.findById(productId)
    if (!currentProduct) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      })
    }

    console.log("Finding complementary products for:", {
      name: currentProduct.name,
      category: currentProduct.category,
      skinTypes: currentProduct.skinTypes,
      intelfaceassis: currentProduct.intelfaceassis,
    })

    // Build query for complementary products
    const complementaryQuery = {
      _id: { $ne: productId }, // Exclude the current product
      category: currentProduct.category, // Same category
      intelfaceassis: currentProduct.intelfaceassis, // Same medical condition
    }

    // Add skin type filter if the current product has skin types
    if (currentProduct.skinTypes && currentProduct.skinTypes.length > 0) {
      complementaryQuery.skinTypes = {
        $in: currentProduct.skinTypes, // Products that share at least one skin type
      }
    }

    // Find complementary products with parapharmacy information
    const complementaryProducts = await Product.aggregate([
      { $match: complementaryQuery },
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
          category: 1,
          price: 1,
          hasDiscount: 1,
          discountPercentage: 1,
          description: 1,
          image: 1,
          skinTypes: 1,
          intelfaceassis: 1,
          quantity: 1,
          effectivePrice: {
            $cond: {
              if: "$hasDiscount",
              then: {
                $subtract: ["$price", { $multiply: ["$price", { $divide: ["$discountPercentage", 100] }] }],
              },
              else: "$price",
            },
          },
          parapharmacy: {
            id: "$parapharmacyInfo._id",
            name: "$parapharmacyInfo.name",
            rating: "$parapharmacyInfo.rating",
            address: "$parapharmacyInfo.address",
          },
        },
      },
      { $sort: { effectivePrice: 1 } }, // Sort by effective price (lowest first)
    ])

    // Group products by name to show price comparison across parapharmacies
    const groupedProducts = {}

    complementaryProducts.forEach((product) => {
      const productName = product.name
      if (!groupedProducts[productName]) {
        groupedProducts[productName] = {
          productInfo: {
            id: product._id,
            name: product.name,
            category: product.category,
            description: product.description,
            image: product.image,
            skinTypes: product.skinTypes,
            intelfaceassis: product.intelfaceassis,
          },
          parapharmacies: [],
        }
      }

      groupedProducts[productName].parapharmacies.push({
        parapharmacyId: product.parapharmacy.id,
        parapharmacyName: product.parapharmacy.name,
        parapharmacyRating: product.parapharmacy.rating,
        parapharmacyAddress: product.parapharmacy.address,
        productId: product._id,
        originalPrice: product.price,
        effectivePrice: product.effectivePrice,
        hasDiscount: product.hasDiscount,
        discountPercentage: product.discountPercentage,
        quantity: product.quantity,
        inStock: product.quantity > 0,
      })
    })

    // Convert grouped products to array and sort by lowest price
    const result = Object.values(groupedProducts).map((group) => {
      // Sort parapharmacies by effective price
      group.parapharmacies.sort((a, b) => a.effectivePrice - b.effectivePrice)

      return {
        ...group,
        lowestPrice: group.parapharmacies.length > 0 ? group.parapharmacies[0].effectivePrice : 0,
        availableInStores: group.parapharmacies.filter((p) => p.inStock).length,
      }
    })

    // Sort by lowest price
    result.sort((a, b) => a.lowestPrice - b.lowestPrice)

    console.log(`Found ${result.length} complementary product groups`)

    res.status(200).json({
      success: true,
      currentProduct: {
        id: currentProduct._id,
        name: currentProduct.name,
        category: currentProduct.category,
        skinTypes: currentProduct.skinTypes,
        intelfaceassis: currentProduct.intelfaceassis,
      },
      complementaryProducts: result,
      totalGroups: result.length,
      totalProducts: complementaryProducts.length,
    })
  } catch (error) {
    console.error("Error fetching complementary products:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

// Get detailed comparison for a specific product across all parapharmacies
router.get("/products/:productName/detailed-comparison", async (req, res) => {
  try {
    const { productName } = req.params

    // Find all instances of this product across parapharmacies
    const productComparisons = await Product.aggregate([
      {
        $match: {
          name: { $regex: new RegExp("^" + productName + "$", "i") }, // Exact match, case insensitive
        },
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
          category: 1,
          price: 1,
          hasDiscount: 1,
          discountPercentage: 1,
          description: 1,
          howToUse: 1,
          image: 1,
          skinTypes: 1,
          intelfaceassis: 1,
          quantity: 1,
          effectivePrice: {
            $cond: {
              if: "$hasDiscount",
              then: {
                $subtract: ["$price", { $multiply: ["$price", { $divide: ["$discountPercentage", 100] }] }],
              },
              else: "$price",
            },
          },
          parapharmacy: {
            id: "$parapharmacyInfo._id",
            name: "$parapharmacyInfo.name",
            rating: "$parapharmacyInfo.rating",
            address: "$parapharmacyInfo.address",
            phone: "$parapharmacyInfo.phone",
          },
        },
      },
      { $sort: { effectivePrice: 1 } },
    ])

    if (productComparisons.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No products found with this name",
      })
    }

    res.status(200).json({
      success: true,
      productName: productName,
      comparisons: productComparisons,
      totalStores: productComparisons.length,
      priceRange: {
        lowest: productComparisons[0].effectivePrice,
        highest: productComparisons[productComparisons.length - 1].effectivePrice,
      },
    })
  } catch (error) {
    console.error("Error fetching detailed product comparison:", error)
    res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    })
  }
})

module.exports = router
