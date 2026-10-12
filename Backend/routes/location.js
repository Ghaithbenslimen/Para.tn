const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const Parapharmacie = require('../models/Parapharmacie');
const User = require('../models/User');

// Middleware to verify token
const verifyToken = (req, res, next) => {
  const token =
    req.header('Authorization') &&
    req.header('Authorization').split(' ')[1];

  if (!token) {
    return res
      .status(401)
      .json({ message: 'No token provided, authorization denied.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.isParapharmacie = decoded.isParapharmacie;
    next();
  } catch (error) {
    return res.status(400).json({ message: 'Invalid token' });
  }
};

// Update user location
router.put('/user-location', verifyToken, async (req, res) => {
  try {
    const { latitude, longitude, address } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    // Check if this is a regular user account
    if (req.isParapharmacie) {
      return res.status(403).json({ message: 'This endpoint is for regular users only' });
    }

    // Convert latitude and longitude to numbers
    const lat = Number(latitude);
    const lng = Number(longitude);

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ message: 'Latitude and longitude must be valid numbers' });
    }

    // Validate coordinate ranges
    if (lat < -90 || lat > 90) {
      return res.status(400).json({ message: 'Latitude must be between -90 and 90' });
    }

    if (lng < -180 || lng > 180) {
      return res.status(400).json({ message: 'Longitude must be between -180 and 180' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.userId,
      {
        location: {
          type: 'Point',
          coordinates: [lng, lat], // GeoJSON format is [longitude, latitude]
          address: address || ''
        }
      },
      { new: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({
      message: 'Location updated successfully',
      user: updatedUser
    });
  } catch (error) {
    console.error('Error updating user location:', error);
    res.status(500).json({ message: 'Error updating location', error: error.message });
  }
});

// Update parapharmacy location
router.put('/parapharmacy-location', verifyToken, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    // Check if this is a parapharmacy account
    if (!req.isParapharmacie) {
      return res.status(403).json({ message: 'This endpoint is for parapharmacy accounts only' });
    }

    // Convert latitude and longitude to numbers
    const lat = Number(latitude);
    const lng = Number(longitude);

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ message: 'Latitude and longitude must be valid numbers' });
    }

    // Validate coordinate ranges
    if (lat < -90 || lat > 90) {
      return res.status(400).json({ message: 'Latitude must be between -90 and 90' });
    }

    if (lng < -180 || lng > 180) {
      return res.status(400).json({ message: 'Longitude must be between -180 and 180' });
    }

    const updatedPara = await Parapharmacie.findByIdAndUpdate(
      req.userId,
      {
        location: {
          type: 'Point',
          coordinates: [lng, lat] // GeoJSON format is [longitude, latitude]
        }
      },
      { new: true }
    ).select('-password');

    if (!updatedPara) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    res.json({
      message: 'Location updated successfully',
      parapharmacy: updatedPara
    });
  } catch (error) {
    console.error('Error updating parapharmacy location:', error);
    res.status(500).json({ message: 'Error updating location', error: error.message });
  }
});

// Get all parapharmacies with location data
router.get('/all-parapharmacies', async (req, res) => {
  try {
    const parapharmacies = await Parapharmacie.find({
      'location.coordinates.0': { $ne: 0 },
      'location.coordinates.1': { $ne: 0 }
    }).select('name address location image rating');

    res.json({
      count: parapharmacies.length,
      parapharmacies
    });
  } catch (error) {
    console.error('Error fetching parapharmacies:', error);
    res.status(500).json({ message: 'Error fetching parapharmacies', error: error.message });
  }
});

// Get parapharmacy location coordinates by ID
router.get('/parapharmacy-coordinates/:id', async (req, res) => {
  try {
    const parapharmacyId = req.params.id;

    if (!mongoose.Types.ObjectId.isValid(parapharmacyId)) {
      return res.status(400).json({ message: 'Invalid parapharmacy ID format' });
    }

    const parapharmacy = await Parapharmacie.findById(parapharmacyId).select('location name');

    if (!parapharmacy) {
      return res.status(404).json({ message: 'Parapharmacy not found' });
    }

    // Check if location exists and has valid coordinates
    if (!parapharmacy.location ||
        !parapharmacy.location.coordinates ||
        parapharmacy.location.coordinates.length < 2 ||
        (parapharmacy.location.coordinates[0] === 0 && parapharmacy.location.coordinates[1] === 0)) {
      return res.status(404).json({ message: 'Location coordinates not available for this parapharmacy' });
    }

    // GeoJSON format is [longitude, latitude], but for Google Maps we need [latitude, longitude]
    const coordinates = {
      longitude: parapharmacy.location.coordinates[0],
      latitude: parapharmacy.location.coordinates[1],
      name: parapharmacy.name
    };

    console.log('Sending coordinates:', coordinates);
    res.json(coordinates);
  } catch (error) {
    console.error('Error fetching parapharmacy coordinates:', error);
    res.status(500).json({ message: 'Error fetching coordinates', error: error.message });
  }
});

// NEW ENDPOINT: Get nearby parapharmacies based on coordinates
router.get('/nearby', async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 10000 } = req.query; // maxDistance in meters, default 10km
    
    if (!latitude || !longitude) {
      return res.status(400).json({ 
        success: false,
        message: 'Latitude and longitude are required' 
      });
    }
    
    // Convert string parameters to numbers
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const distance = parseInt(maxDistance);
    
    if (isNaN(lat) || isNaN(lng) || isNaN(distance)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid parameters. Latitude, longitude, and maxDistance must be valid numbers' 
      });
    }
    
    // Find parapharmacies within the specified distance
    const parapharmacies = await Parapharmacie.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [lng, lat] // MongoDB uses [longitude, latitude] order
          },
          $maxDistance: distance
        }
      }
    }).select('name address description image phone email rating location reviews');
    
    // Calculate distance for each parapharmacy and add region
    const parapharmaciesWithDistance = parapharmacies.map(parapharmacy => {
      const parapharmacyObj = parapharmacy.toObject();
      
      // Calculate distance in kilometers using the Haversine formula
      const parapharmacyCoords = parapharmacy.location.coordinates;
      const distanceInKm = calculateDistance(lat, lng, parapharmacyCoords[1], parapharmacyCoords[0]);
      
      // Extract region from address if not already present
      let region = null;
      if (parapharmacyObj.address) {
        region = extractRegionFromAddress(parapharmacyObj.address);
      }
      
      return {
        ...parapharmacyObj,
        distance: distanceInKm.toFixed(1), // Distance in km with 1 decimal place
        region: region
      };
    });
    
    // Sort by distance
    parapharmaciesWithDistance.sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));
    
    res.status(200).json({
      success: true,
      count: parapharmaciesWithDistance.length,
      parapharmacies: parapharmaciesWithDistance
    });
  } catch (error) {
    console.error('Error finding nearby parapharmacies:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to find nearby parapharmacies',
      error: error.message
    });
  }
});

// NEW ENDPOINT: Get nearby parapharmacies for the authenticated user
router.get('/nearby-user', verifyToken, async (req, res) => {
  try {
    const { maxDistance = 5000000000000000 } = req.query; // maxDistance in meters, default 10km
    
    // Get the user's location
    const user = await User.findById(req.userId);
    
    if (!user || !user.location || !user.location.coordinates) {
      return res.status(400).json({
        success: false,
        message: 'User location not available'
      });
    }
    
    const userCoords = user.location.coordinates;
    const distance = parseInt(maxDistance);
    
    if (isNaN(distance)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid maxDistance parameter. Must be a valid number' 
      });
    }
    
    // Find parapharmacies within the specified distance
    const parapharmacies = await Parapharmacie.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: userCoords // MongoDB uses [longitude, latitude] order
          },
          $maxDistance: distance
        }
      }
    }).select('name address description image phone email rating location reviews');
    
    // Calculate distance for each parapharmacy and add region
    const parapharmaciesWithDistance = parapharmacies.map(parapharmacy => {
      const parapharmacyObj = parapharmacy.toObject();
      
      // Calculate distance in kilometers using the Haversine formula
      const parapharmacyCoords = parapharmacy.location.coordinates;
      const distanceInKm = calculateDistance(
        userCoords[1], userCoords[0], 
        parapharmacyCoords[1], parapharmacyCoords[0]
      );
      
      // Extract region from address if not already present
      let region = null;
      if (parapharmacyObj.address) {
        region = extractRegionFromAddress(parapharmacyObj.address);
      }
      
      return {
        ...parapharmacyObj,
        distance: distanceInKm.toFixed(1), // Distance in km with 1 decimal place
        region: region
      };
    });
    
    // Sort by distance
    parapharmaciesWithDistance.sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));
    
    res.status(200).json({
      success: true,
      count: parapharmaciesWithDistance.length,
      parapharmacies: parapharmaciesWithDistance
    });
  } catch (error) {
    console.error('Error finding nearby parapharmacies for user:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to find nearby parapharmacies',
      error: error.message
    });
  }
});

// Helper function to calculate distance using the Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2); 
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  const distance = R * c; // Distance in km
  return distance;
}

function deg2rad(deg) {
  return deg * (Math.PI/180);
}

// Helper function to extract region from address
function extractRegionFromAddress(address) {
  // List of Tunisian regions
  const tunisianRegions = [
    'Ariana', 'Béja', 'Ben Arous', 'Bizerte', 'Gabès', 'Gafsa', 'Jendouba',
    'Kairouan', 'Kasserine', 'Kébili', 'Kef', 'Mahdia', 'Manouba', 'Médenine',
    'Monastir', 'Nabeul', 'Sfax', 'Sidi Bouzid', 'Siliana', 'Sousse',
    'Tataouine', 'Tozeur', 'Tunis', 'Zaghouan'
  ];
  
  // Check if any region name appears in the address
  const lowerAddress = address.toLowerCase();
  for (const region of tunisianRegions) {
    if (lowerAddress.includes(region.toLowerCase())) {
      return region;
    }
  }
  
  return null;
}

module.exports = router;