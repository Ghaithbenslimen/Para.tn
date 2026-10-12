const express = require("express")
const router = express.Router()
const Parapharmacie = require("../models/Parapharmacie")
const User = require("../models/User") // Import the User model
const authenticateMiddleware = require("../middleware/authenticate") // Import your existing middleware

// Get all parapharmacies (public route)
router.get("/parapharmacies", async (req, res) => {
  try {
    // Find all parapharmacies, but only return necessary fields
    const parapharmacies = await Parapharmacie.find(
      {},
      {
        name: 1,
        address: 1,
        description: 1,
        image: 1,
        phone: 1,
        email: 1,
        rating: 1,
        region: 1, // Include region field
      },
    )

    res.status(200).json({
      success: true,
      count: parapharmacies.length,
      parapharmacies,
    })
  } catch (error) {
    console.error("Error fetching parapharmacies:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch parapharmacies",
      error: error.message,
    })
  }
})

// New route: Filter parapharmacies by name, region, and/or rating
router.get("/parapharmacies/filter", async (req, res) => {
  try {
    const { name, region, minRating } = req.query

    // Build filter object
    const filter = {}

    if (name) {
      filter.name = { $regex: name, $options: "i" }
    }

    if (region && region !== "All") {
      // If region is provided in the database, use it directly
      filter.$or = [
        { region: { $regex: region, $options: "i" } },
        // Also search in address field for region
        { address: { $regex: region, $options: "i" } },
      ]
    }

    if (minRating) {
      filter.rating = { $gte: Number.parseFloat(minRating) }
    }

    const parapharmacies = await Parapharmacie.find(filter, {
      name: 1,
      address: 1,
      description: 1,
      image: 1,
      phone: 1,
      email: 1,
      rating: 1,
      region: 1,
    })

    res.status(200).json({
      success: true,
      count: parapharmacies.length,
      parapharmacies,
    })
  } catch (error) {
    console.error("Error filtering parapharmacies:", error)
    res.status(500).json({
      success: false,
      message: "Failed to filter parapharmacies",
      error: error.message,
    })
  }
})

// Get a single parapharmacy by ID (public route)
router.get("/parapharmacies/:id", async (req, res) => {
  try {
    const parapharmacyId = req.params.id

    const parapharmacy = await Parapharmacie.findById(parapharmacyId, {
      name: 1,
      address: 1,
      description: 1,
      image: 1,
      phone: 1,
      email: 1,
      rating: 1,
      region: 1, // Include region field
    })

    if (!parapharmacy) {
      return res.status(404).json({
        success: false,
        message: "Parapharmacy not found",
      })
    }

    res.status(200).json({
      success: true,
      parapharmacy,
    })
  } catch (error) {
    console.error("Error fetching parapharmacy:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch parapharmacy",
      error: error.message,
    })
  }
})

// Search parapharmacies by name or address
router.get("/parapharmacies/search/:query", async (req, res) => {
  try {
    const searchQuery = req.params.query

    const parapharmacies = await Parapharmacie.find(
      {
        $or: [
          { name: { $regex: searchQuery, $options: "i" } },
          { address: { $regex: searchQuery, $options: "i" } },
          { region: { $regex: searchQuery, $options: "i" } }, // Add region to search
        ],
      },
      {
        name: 1,
        address: 1,
        description: 1,
        image: 1,
        phone: 1,
        email: 1,
        rating: 1,
        region: 1, // Include region field
      },
    )

    res.status(200).json({
      success: true,
      count: parapharmacies.length,
      parapharmacies,
    })
  } catch (error) {
    console.error("Error searching parapharmacies:", error)
    res.status(500).json({
      success: false,
      message: "Failed to search parapharmacies",
      error: error.message,
    })
  }
})

// Add a review to a parapharmacy (protected route - requires authentication)
router.post("/parapharmacies/:id/reviews", authenticateMiddleware, async (req, res) => {
  try {
    console.log("Review submission request received")
    console.log("User ID from token:", req.userId)

    const { rating, comment, user, userId } = req.body

    if (!rating || !comment) {
      return res.status(400).json({
        success: false,
        message: "Rating and comment are required",
      })
    }

    const parapharmacy = await Parapharmacie.findById(req.params.id)

    if (!parapharmacy) {
      return res.status(404).json({
        success: false,
        message: "Parapharmacy not found",
      })
    }

    // Fetch the user details from the database
    const userDoc = await User.findById(req.userId)
    if (!userDoc) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Create the new review using user details from the document
    // Use the provided user/userId from the request if available, otherwise use from the database
    const newReview = {
      userId: userId || req.userId, // Store the user ID for authorization checks
      user: user || userDoc.name || userDoc.username || "User",
      rating: Number(rating),
      comment,
      date: new Date(),
    }

    console.log("Creating new review:", newReview)

    // Initialize reviews array if it doesn't exist
    if (!parapharmacy.reviews) {
      parapharmacy.reviews = []
    }

    parapharmacy.reviews.push(newReview)

    // Calculate the new average rating
    const totalRating = parapharmacy.reviews.reduce((sum, review) => sum + review.rating, 0)
    parapharmacy.rating = totalRating / parapharmacy.reviews.length

    await parapharmacy.save()

    res.status(201).json({
      success: true,
      message: "Review added successfully",
      review: newReview,
    })
  } catch (error) {
    console.error("Error adding review:", error)
    res.status(500).json({
      success: false,
      message: "Failed to add review",
      error: error.message,
    })
  }
})

// Get all reviews for a parapharmacy (public route)
router.get("/parapharmacies/:id/reviews", async (req, res) => {
  try {
    const parapharmacy = await Parapharmacie.findById(req.params.id)

    if (!parapharmacy) {
      return res.status(404).json({
        success: false,
        message: "Parapharmacy not found",
      })
    }

    // Return empty array if no reviews
    const reviews = parapharmacy.reviews || []

    res.status(200).json({
      success: true,
      count: reviews.length,
      reviews,
    })
  } catch (error) {
    console.error("Error fetching reviews:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch reviews",
      error: error.message,
    })
  }
})

// NEW ROUTE: Get reviews for the authenticated parapharmacy
router.get("/my-parapharmacy/reviews", authenticateMiddleware, async (req, res) => {
  try {
    console.log("Fetching reviews for authenticated parapharmacy")
    console.log("User ID from token:", req.userId)

    // Find the parapharmacy associated with the authenticated user
    const parapharmacy = await Parapharmacie.findOne({
      // Check if the user is a parapharmacy (para field is true)
      para: true,
      // Match by the user ID from the token
      _id: req.userId,
    })

    if (!parapharmacy) {
      return res.status(404).json({
        success: false,
        message: "Parapharmacy not found or user is not authorized",
      })
    }

    // Return empty array if no reviews
    const reviews = parapharmacy.reviews || []

    res.status(200).json({
      success: true,
      count: reviews.length,
      parapharmacyName: parapharmacy.name,
      parapharmacyId: parapharmacy._id,
      reviews,
    })
  } catch (error) {
    console.error("Error fetching parapharmacy reviews:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch parapharmacy reviews",
      error: error.message,
    })
  }
})

// Delete a review (protected route - only the review author can delete)
router.delete("/parapharmacies/:id/reviews/:reviewId", authenticateMiddleware, async (req, res) => {
  try {
    console.log("Delete review request received")
    console.log("User ID from token:", req.userId)
    console.log("Review ID:", req.params.reviewId)

    const parapharmacy = await Parapharmacie.findById(req.params.id)

    if (!parapharmacy) {
      return res.status(404).json({
        success: false,
        message: "Parapharmacy not found",
      })
    }

    // Find the review
    const reviewIndex = parapharmacy.reviews.findIndex((review) => review._id.toString() === req.params.reviewId)

    if (reviewIndex === -1) {
      return res.status(404).json({
        success: false,
        message: "Review not found",
      })
    }

    // Get the review
    const review = parapharmacy.reviews[reviewIndex]

    // Get the current user
    const user = await User.findById(req.userId)
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    console.log("Review user:", review.user)
    console.log("Review userId:", review.userId)
    console.log("Current user ID:", req.userId)
    console.log("Current username:", user.username)
    console.log("Current user name:", user.name)

    // Check if the user is the author of the review by comparing userIds or usernames
    const isAuthorById = review.userId && review.userId.toString() === req.userId
    const isAuthorByName = review.user === user.name || review.user === user.username

    // Also check if the user is the parapharmacy owner (can delete any review on their parapharmacy)
    const isParapharmacyOwner = parapharmacy._id.toString() === req.userId

    console.log("Is author by ID:", isAuthorById)
    console.log("Is author by name:", isAuthorByName)
    console.log("Is parapharmacy owner:", isParapharmacyOwner)

    if (!isAuthorById && !isAuthorByName && !isParapharmacyOwner) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to delete this review",
      })
    }

    // Remove the review
    parapharmacy.reviews.splice(reviewIndex, 1)

    // Recalculate the average rating if there are still reviews
    if (parapharmacy.reviews.length > 0) {
      const totalRating = parapharmacy.reviews.reduce((sum, review) => sum + review.rating, 0)
      parapharmacy.rating = totalRating / parapharmacy.reviews.length
    } else {
      parapharmacy.rating = 0 // No reviews, reset rating
    }

    await parapharmacy.save()

    res.status(200).json({
      success: true,
      message: "Review deleted successfully",
    })
  } catch (error) {
    console.error("Error deleting review:", error)
    res.status(500).json({
      success: false,
      message: "Failed to delete review",
      error: error.message,
    })
  }
})

// Update Parapharmacie schema to include region field
router.post("/parapharmacies/update-regions", async (req, res) => {
  try {
    const parapharmacies = await Parapharmacie.find({})

    // List of Tunisian regions
    const tunisianRegions = [
      "Ariana",
      "Béja",
      "Ben Arous",
      "Bizerte",
      "Gabès",
      "Gafsa",
      "Jendouba",
      "Kairouan",
      "Kasserine",
      "Kébili",
      "Kef",
      "Mahdia",
      "Manouba",
      "Médenine",
      "Monastir",
      "Nabeul",
      "Sfax",
      "Sidi Bouzid",
      "Siliana",
      "Sousse",
      "Tataouine",
      "Tozeur",
      "Tunis",
      "Zaghouan",
    ]

    let updatedCount = 0

    for (const parapharmacy of parapharmacies) {
      if (!parapharmacy.region) {
        // Try to extract region from address
        const address = parapharmacy.address.toLowerCase()
        let foundRegion = null

        for (const region of tunisianRegions) {
          if (address.includes(region.toLowerCase())) {
            foundRegion = region
            break
          }
        }

        if (foundRegion) {
          parapharmacy.region = foundRegion
          await parapharmacy.save()
          updatedCount++
        }
      }
    }

    res.status(200).json({
      success: true,
      message: `Updated ${updatedCount} parapharmacies with region information`,
    })
  } catch (error) {
    console.error("Error updating regions:", error)
    res.status(500).json({
      success: false,
      message: "Failed to update regions",
      error: error.message,
    })
  }
})

module.exports = router
