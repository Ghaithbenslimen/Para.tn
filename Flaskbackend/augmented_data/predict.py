import os
import numpy as np
import matplotlib.pyplot as plt
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications.efficientnet import preprocess_input

# === Configuration ===
model_path = 'best_model.keras'  # Update this if your model has a different name
test_data_dir = 'testing'  # Same structure as used for training
img_path = 'predict imgaes/A_0120_Rosacea_RDPHA0_Hv5FSij.max-600x600.jpg'  # Image to predict

IMG_SIZE = (224, 224)
BATCH_SIZE = 32

# === Step 1: Load the model ===
print("[INFO] Loading model...")
model = load_model(model_path)

# === Step 2: Build test generator to extract class labels dynamically ===
print("[INFO] Building test generator to extract class labels...")
test_datagen = ImageDataGenerator(preprocessing_function=preprocess_input)
test_generator = test_datagen.flow_from_directory(
    directory=test_data_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False
)
class_labels = list(test_generator.class_indices.keys())
print(f"[INFO] Class labels found: {class_labels}")

# === Step 3: Define prediction function ===
def predict_single_image(img_path, model, class_labels, img_size=(224, 224), show=True):
    # Load and preprocess the image
    img = image.load_img(img_path, target_size=img_size)
    img_array = image.img_to_array(img)
    img_array = preprocess_input(img_array)
    img_batch = np.expand_dims(img_array, axis=0)
    
    # Predict
    preds = model.predict(img_batch)
    pred_index = np.argmax(preds)
    pred_label = class_labels[pred_index]
    confidence = preds[0][pred_index]

    # Show image with prediction
    if show:
        plt.imshow(img)
        plt.axis('off')
        plt.title(f'Predicted: {pred_label} ({confidence:.2%})')
        plt.show()
    
    # Show full class probabilities
    print("\n--- Prediction Probabilities ---")
    for i, label in enumerate(class_labels):
        print(f"{label}: {preds[0][i]:.4f}")
    
    return pred_label, confidence

# === Step 4: Run the prediction ===
print(f"[INFO] Predicting image: {img_path}")
predicted_label, confidence = predict_single_image(img_path, model, class_labels)

print(f"\n✅ Final Prediction: {predicted_label} ({confidence:.2%})")
