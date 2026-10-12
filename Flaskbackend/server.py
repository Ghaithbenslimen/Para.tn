from collections import defaultdict
from flask import Flask, request, jsonify
import numpy as np
import requests
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os
from flask_cors import CORS
from bson import ObjectId
from datetime import datetime
import json
import random
from pymongo import MongoClient, GEOSPHERE
import re

# === CONFIGURATION ===
MODEL_PATH = 'best_model.keras'
IMG_SIZE = (224, 224)
TEST_DIR = 'augmented_data/testing'  # Used to get class labels
MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "mydatabase"

# === INITIALIZE APP & LOAD MODEL ===
app = Flask(__name__)
CORS(app)

model = load_model(MODEL_PATH)

# Initialize database connection
client = None
db = None
try:
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    print("Connected to MongoDB")
except Exception as e:
    print(f"MongoDB connection failed: {str(e)}")

# Dynamically extract class labels from test directory
test_datagen = ImageDataGenerator(preprocessing_function=preprocess_input)
test_generator = test_datagen.flow_from_directory(
    directory=TEST_DIR,
    target_size=IMG_SIZE,
    batch_size=1,
    class_mode='categorical',
    shuffle=False
)
class_labels = list(test_generator.class_indices.keys())

# === HELPER: Preprocess and Predict ===
def model_predict(img_path):
    img = image.load_img(img_path, target_size=IMG_SIZE)
    img_array = image.img_to_array(img)
    img_array = preprocess_input(img_array)
    img_batch = np.expand_dims(img_array, axis=0)

    preds = model.predict(img_batch)
    pred_idx = np.argmax(preds)
    return {
        'predicted_class': class_labels[pred_idx],
        'confidence': float(preds[0][pred_idx]),
        'all_probs': {class_labels[i]: float(preds[0][i]) for i in range(len(class_labels))}
    }
    
# === Filtering Helpers ===
class JSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, ObjectId):
            return str(o)
        if isinstance(o, datetime):
            return o.isoformat()
        return json.JSONEncoder.default(self, o)

def serialize_document(doc):
    """Recursively serialize MongoDB document"""
    if isinstance(doc, list):
        return [serialize_document(item) for item in doc]
    elif isinstance(doc, dict):
        return {k: serialize_document(v) for k, v in doc.items()}
    elif isinstance(doc, ObjectId):
        return str(doc)
    elif isinstance(doc, datetime):
        return doc.isoformat()
    return doc

def get_parapharmacy_basic_info(parapharmacy_id):
    """Get only basic info (id and name) for a parapharmacy"""
    if db is None:
        return None
    
    try:
        parapharmacy = db.parapharmacies.find_one(
            {"_id": ObjectId(parapharmacy_id)},
            {"name": 1}  # Only return the name field
        )
        return {
            "id": str(parapharmacy["_id"]),
            "name": parapharmacy.get("name")
        } if parapharmacy else None
    except Exception as e:
        print(f"Error fetching parapharmacy: {str(e)}")
        return None

def get_parapharmacy_with_distance(parapharmacy_id, user_location=None):
    """Get parapharmacy info with distance from user if location is provided"""
    if db is None:
        return None
    
    try:
        parapharmacy = db.parapharmacies.find_one(
            {"_id": ObjectId(parapharmacy_id)},
            {"name": 1, "location": 1}  # Return name and location fields
        )
        
        if not parapharmacy:
            return None
            
        result = {
            "id": str(parapharmacy["_id"]),
            "name": parapharmacy.get("name")
        }
        
        # Calculate distance if both user and parapharmacy have locations
        if user_location and parapharmacy.get("location") and parapharmacy["location"].get("coordinates"):
            # Add distance in kilometers
            result["distance"] = calculate_distance(
                user_location["coordinates"],
                parapharmacy["location"]["coordinates"]
            )
            
        return result
    except Exception as e:
        print(f"Error fetching parapharmacy with distance: {str(e)}")
        return None

def calculate_distance(coords1, coords2):
    """Calculate distance between two coordinates in kilometers using Haversine formula"""
    from math import radians, sin, cos, sqrt, atan2
    
    # Extract longitude and latitude
    lon1, lat1 = coords1
    lon2, lat2 = coords2
    
    # Convert to radians
    lat1, lon1 = radians(lat1), radians(lon1)
    lat2, lon2 = radians(lat2), radians(lon2)
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    # Earth radius in kilometers
    radius = 6371
    
    # Calculate distance
    distance = radius * c
    
    return round(distance, 2)  # Round to 2 decimal places

def get_user_location(user_id):
    """Get user's location from database"""
    if db is None or not user_id:
        return None
        
    try:
        user = db.users.find_one(
            {"_id": ObjectId(user_id)},
            {"location": 1}
        )
        
        if user and user.get("location"):
            return user["location"]
        return None
    except Exception as e:
        print(f"Error fetching user location: {str(e)}")
        return None

def get_nearest_parapharmacies(user_location, max_distance=10, limit=10):
    """Get nearest parapharmacies to user location within max_distance (km)"""
    if db is None or not user_location:
        return []
        
    try:
        # Convert max_distance from kilometers to meters for MongoDB
        max_distance_meters = max_distance * 1000
        
        # Query for parapharmacies within the specified distance
        nearest_parapharmacies = list(db.parapharmacies.find({
            "location": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": user_location["coordinates"]
                    },
                    "$maxDistance": max_distance_meters
                }
            }
        }).limit(limit))
        
        # Add distance to each parapharmacy
        for para in nearest_parapharmacies:
            para["distance"] = calculate_distance(
                user_location["coordinates"],
                para["location"]["coordinates"]
            )
            
        return nearest_parapharmacies
    except Exception as e:
        print(f"Error finding nearest parapharmacies: {str(e)}")
        return []

def is_anomaly_match(product_anomaly, target_anomaly):
    """Check if a product anomaly matches a target anomaly with flexible matching"""
    # Convert both to lowercase for case-insensitive comparison
    product_anomaly_lower = product_anomaly.lower()
    target_anomaly_lower = target_anomaly.lower()
    
    # Direct match
    if product_anomaly_lower == target_anomaly_lower:
        return True
    
    # Check if target is contained in product anomaly
    if target_anomaly_lower in product_anomaly_lower:
        return True
    
    # Check for common variations
    if target_anomaly_lower == "acne" and ("acne" in product_anomaly_lower or 
                                          "pimple" in product_anomaly_lower or 
                                          "blemish" in product_anomaly_lower):
        return True
    
    if target_anomaly_lower == "redness" and ("redness" in product_anomaly_lower or 
                                             "rosacea" in product_anomaly_lower or 
                                             "irritation" in product_anomaly_lower):
        return True
    
    if target_anomaly_lower == "dry" and ("dry" in product_anomaly_lower or 
                                         "dehydrated" in product_anomaly_lower):
        return True
    
    if target_anomaly_lower == "oily" and ("oily" in product_anomaly_lower or 
                                          "sebum" in product_anomaly_lower):
        return True
    
    return False

def get_products_by_anomalies(products, anomalies, sort_by_price=False, sort_by_distance=False, user_location=None):
    """Get products grouped by parapharmacy and anomaly with optional distance sorting"""
    result = defaultdict(lambda: defaultdict(list))
    
    # Debug information
    print(f"Processing {len(products)} products for {len(anomalies)} anomalies")
    
    # Store all products by parapharmacy for fallback
    all_products_by_parapharmacy = defaultdict(list)
    
    for product in products:
        parapharmacy_id = product.get("parapharmacie")
        if not parapharmacy_id:
            continue
        
        # Store all products by parapharmacy for fallback
        all_products_by_parapharmacy[parapharmacy_id].append(product)
        
        # Get product anomalies
        product_anomalies = product.get("intelfaceassis", "none")
        if isinstance(product_anomalies, str):
            product_anomalies = [product_anomalies] if product_anomalies != "none" else []
        
        # Debug product anomalies
        print(f"Product {product.get('name', 'Unknown')} has anomalies: {product_anomalies}")
        
        # Check each requested anomaly
        for anomaly in anomalies:
            anomaly_name = anomaly.get("name", "")
            anomaly_percentage = anomaly.get("percentage", 0)
            
            # Skip low percentage anomalies
            if anomaly_percentage < 40:
                continue
            
            # Check if product matches this anomaly
            matched = False
            for product_anomaly in product_anomalies:
                if is_anomaly_match(product_anomaly, anomaly_name):
                    matched = True
                    break
            
            if matched:
                result[parapharmacy_id][anomaly_name].append(product)
    
    # Get parapharmacy info with distances if needed
    parapharmacies_info = {}
    all_parapharmacy_ids = set(result.keys()) | set(all_products_by_parapharmacy.keys())
    
    for parapharmacy_id in all_parapharmacy_ids:
        if sort_by_distance and user_location:
            para_info = get_parapharmacy_with_distance(parapharmacy_id, user_location)
        else:
            para_info = get_parapharmacy_basic_info(parapharmacy_id)
            
        if para_info:
            parapharmacies_info[parapharmacy_id] = para_info
    
    # Create final result list
    final_result = []
    
    # First try with matched anomalies
    for parapharmacy_id, anomalies_dict in result.items():
        parapharmacy_info = parapharmacies_info.get(parapharmacy_id, {})
        anomaly_products = []
        
        for anomaly_name, products_list in anomalies_dict.items():
            # Sort by price if requested
            if sort_by_price:
                products_list = sorted(products_list, key=lambda x: x.get("price", float('inf')))
            
            # Get top 3 products (or all if less than 3)
            selected_products = products_list[:3]
            anomaly_products.append({
                "anomaly": anomaly_name,
                "products": [
                    {k: v for k, v in p.items() if k != "parapharmacy"} 
                    for p in selected_products
                ]
            })
        
        if anomaly_products:  # Only add if there are matched products
            final_result.append({
                "parapharmacy_id": parapharmacy_id,
                "parapharmacy_name": parapharmacy_info.get("name", ""),
                "distance": parapharmacy_info.get("distance"),  # Include distance if available
                "anomaly_products": anomaly_products
            })
    
    # If no results, use fallback with all products
    if not final_result and all_products_by_parapharmacy:
        print("No specific matches found. Using fallback with all products.")
        
        # Use the first anomaly as default
        default_anomaly = anomalies[0].get("name", "general") if anomalies else "general"
        
        for parapharmacy_id, products_list in all_products_by_parapharmacy.items():
            parapharmacy_info = parapharmacies_info.get(parapharmacy_id, {})
            
            # Sort by price if requested
            if sort_by_price:
                products_list = sorted(products_list, key=lambda x: x.get("price", float('inf')))
            
            # Get top 3 products (or all if less than 3)
            selected_products = products_list[:3]
            
            final_result.append({
                "parapharmacy_id": parapharmacy_id,
                "parapharmacy_name": parapharmacy_info.get("name", ""),
                "distance": parapharmacy_info.get("distance"),
                "anomaly_products": [{
                    "anomaly": default_anomaly,
                    "products": [
                        {k: v for k, v in p.items() if k != "parapharmacy"} 
                        for p in selected_products
                    ]
                }]
            })
    
    # Sort by distance if requested
    if sort_by_distance and user_location:
        final_result.sort(key=lambda x: x.get("distance", float('inf')))
    
    return final_result

def get_all_products(skin_type=None, parapharmacy_ids=None):
    """Get all products from database with basic parapharmacy info"""
    if db is None:
        return []

    query = {}
    if skin_type:
        query["skinTypes"] = {"$in": [skin_type]}
        
    # Filter by parapharmacy IDs if provided
    if parapharmacy_ids:
        # Convert string IDs to ObjectId
        object_ids = [ObjectId(pid) for pid in parapharmacy_ids if ObjectId.is_valid(pid)]
        if object_ids:
            query["parapharmacie"] = {"$in": object_ids}

    try:
        products = list(db.products.find(query))
        enhanced_products = []
        for product in products:
            product = serialize_document(product)
            parapharmacy_id = product.get("parapharmacie")
            if parapharmacy_id:
                product["parapharmacy"] = get_parapharmacy_basic_info(parapharmacy_id)
            enhanced_products.append(product)
        return enhanced_products
    except Exception as e:
        print(f"Error fetching products: {str(e)}")
        return []

# === ROUTE: Home (optional) ===
@app.route('/')
def index():
    return "🔥 Flask Model Inference API is Running!"

# === ROUTE: Prediction ===
@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'})
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'})
    
    if file:
        file_path = os.path.join('temp_image.jpg')
        file.save(file_path)
        result = model_predict(file_path)
        os.remove(file_path)
        return jsonify(result)
    
@app.route('/recommend', methods=['POST'])
def recommend_random():
    """Route for random product recommendations"""
    if not request.is_json:
        return jsonify({'error': 'Request must be JSON'}), 400

    data = request.get_json()
    skin_type = data.get("skin_type")
    anomalies = data.get("anomalies")
    user_id = data.get("user_id")  # Optional user ID for location-based filtering
    max_distance = data.get("max_distance", 10)  # Default 10km radius

    if not skin_type or not anomalies:
        return jsonify({'error': 'Missing skin_type or anomalies'}), 400

    try:
        # Get user location if user_id is provided
        user_location = get_user_location(user_id) if user_id else None
        
        # If user has location and wants distance filtering
        if user_location and data.get("filter_by_distance", False):
            # Get nearest parapharmacies
            nearest_parapharmacies = get_nearest_parapharmacies(
                user_location, 
                max_distance=max_distance
            )
            
            # Extract parapharmacy IDs
            parapharmacy_ids = [str(para["_id"]) for para in nearest_parapharmacies]
            
            # Get products only from these parapharmacies
            products = get_all_products(skin_type, parapharmacy_ids)
            
            # Get recommendations sorted by distance
            recommendations = get_products_by_anomalies(
                products, 
                anomalies, 
                sort_by_price=False,
                sort_by_distance=True,
                user_location=user_location
            )
        else:
            # Regular recommendation flow without distance filtering
            products = get_all_products(skin_type)
            recommendations = get_products_by_anomalies(
                products, 
                anomalies, 
                sort_by_price=False
            )
        
        # Shuffle the products within each anomaly group
        for parapharmacy in recommendations:
            for anomaly_group in parapharmacy["anomaly_products"]:
                random.shuffle(anomaly_group["products"])

        return app.response_class(
            response=json.dumps({
                "recommendations": recommendations,
                "total": len(products),
                "distance_filtered": user_location is not None and data.get("filter_by_distance", False)
            }, cls=JSONEncoder),
            status=200,
            mimetype='application/json'
        )
    except Exception as e:
        print(f"Error in recommend_random: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/recommend/economy', methods=['POST'])
def recommend_economy():
    """Route for economic (lowest price) product recommendations"""
    if not request.is_json:
        return jsonify({'error': 'Request must be JSON'}), 400

    data = request.get_json()
    skin_type = data.get("skin_type")
    anomalies = data.get("anomalies")
    user_id = data.get("user_id")  # Optional user ID for location-based filtering
    max_distance = data.get("max_distance", 10)  # Default 10km radius

    if not skin_type or not anomalies:
        return jsonify({'error': 'Missing skin_type or anomalies'}), 400

    try:
        # Get user location if user_id is provided
        user_location = get_user_location(user_id) if user_id else None
        
        # If user has location and wants distance filtering
        if user_location and data.get("filter_by_distance", False):
            # Get nearest parapharmacies
            nearest_parapharmacies = get_nearest_parapharmacies(
                user_location, 
                max_distance=max_distance
            )
            
            # Extract parapharmacy IDs
            parapharmacy_ids = [str(para["_id"]) for para in nearest_parapharmacies]
            
            # Get products only from these parapharmacies
            products = get_all_products(skin_type, parapharmacy_ids)
            
            # Get recommendations sorted by price and distance
            recommendations = get_products_by_anomalies(
                products, 
                anomalies, 
                sort_by_price=True,
                sort_by_distance=True,
                user_location=user_location
            )
        else:
            # Regular economy recommendation flow without distance filtering
            products = get_all_products(skin_type)
            recommendations = get_products_by_anomalies(
                products, 
                anomalies, 
                sort_by_price=True
            )

        return app.response_class(
            response=json.dumps({
                "recommendations": recommendations,
                "total": len(products),
                "distance_filtered": user_location is not None and data.get("filter_by_distance", False)
            }, cls=JSONEncoder),
            status=200,
            mimetype='application/json'
        )
    except Exception as e:
        print(f"Error in recommend_economy: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/recommend/nearby', methods=['POST'])
def recommend_nearby():
    """Route for nearby parapharmacy product recommendations"""
    if not request.is_json:
        return jsonify({'error': 'Request must be JSON'}), 400

    data = request.get_json()
    print(f"Received data in recommend_nearby: {data}")  # Enhanced debug log
    
    skin_type = data.get("skin_type")
    anomalies = data.get("anomalies")
    user_id = data.get("user_id")
    
    # Handle max_distance more flexibly - accept either meters or kilometers
    max_distance = data.get("max_distance", 50000)
    print(f"Original max_distance value: {max_distance}")
    
    # If max_distance is very small, assume it's in kilometers and convert to meters
    if max_distance < 1000:
        max_distance = max_distance * 1000
        print(f"Converted max_distance to meters: {max_distance}")
    
    sort_by_price = data.get("sort_by_price", False)

    if not skin_type or not anomalies or not user_id:
        missing = []
        if not skin_type: missing.append("skin_type")
        if not anomalies: missing.append("anomalies")
        if not user_id: missing.append("user_id")
        print(f"Missing required parameters: {', '.join(missing)}")
        return jsonify({'error': f'Missing required parameters: {", ".join(missing)}'}), 400

    try:
        # Get user location
        user_location = get_user_location(user_id)
        print(f"User location for {user_id}: {user_location}")
        
        if not user_location:
            print(f"User location not available for user_id: {user_id}")
            return jsonify({'error': 'User location not available'}), 400
            
        # Get nearest parapharmacies
        nearest_parapharmacies = get_nearest_parapharmacies(
            user_location, 
            max_distance=max_distance
        )
        
        if not nearest_parapharmacies:
            return jsonify({
                'recommendations': [],
                'total': 0,
                'message': f'No parapharmacies found within {max_distance}km'
            }), 200
            
        # Extract parapharmacy IDs
        parapharmacy_ids = [str(para["_id"]) for para in nearest_parapharmacies]
        
        # Debug information
        print(f"Found {len(nearest_parapharmacies)} nearby parapharmacies")
        print(f"Parapharmacy IDs: {parapharmacy_ids}")
        
        # Get products from these parapharmacies
        products = get_all_products(skin_type, parapharmacy_ids)
        
        # Debug information
        print(f"Found {len(products)} products matching skin type '{skin_type}'")
        
        # Get recommendations sorted by distance (and optionally by price)
        recommendations = get_products_by_anomalies(
            products, 
            anomalies, 
            sort_by_price=sort_by_price,
            sort_by_distance=True,
            user_location=user_location
        )

        return app.response_class(
            response=json.dumps({
                "recommendations": recommendations,
                "total": len(products),
                "nearest_parapharmacies": len(nearest_parapharmacies),
                "max_distance": max_distance
            }, cls=JSONEncoder),
            status=200,
            mimetype='application/json'
        )
    except Exception as e:
        print(f"Error in recommend_nearby: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# === RUN FLASK APP ===
if __name__ == '__main__':
    app.run(debug=True)