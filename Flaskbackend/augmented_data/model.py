import os
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks, regularizers, backend as K
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import confusion_matrix, classification_report
from sklearn.utils.class_weight import compute_class_weight
import seaborn as sns
from datetime import datetime

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
# ======================
# DATA CONFIGURATION
# ======================
train_dir = 'train'
test_dir = 'testing'

# ======================
# DATA GENERATORS
# ======================
train_val_datagen = ImageDataGenerator(
    preprocessing_function=preprocess_input,
    validation_split=0.2
)

test_datagen = ImageDataGenerator(
    preprocessing_function=preprocess_input
)

# Compute class weights
class_weight_generator = train_val_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=32,
    class_mode='categorical',
    subset='training',
    shuffle=False
)
classes = class_weight_generator.classes
class_weights = compute_class_weight('balanced', classes=np.unique(classes), y=classes)
class_weights_dict = dict(enumerate(class_weights))

# Create data generators
train_generator = train_val_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=32,
    class_mode='categorical',
    subset='training'
)

validation_generator = train_val_datagen.flow_from_directory(
    train_dir,
    target_size=(224, 224),
    batch_size=32,
    class_mode='categorical',
    subset='validation'
)

test_generator = test_datagen.flow_from_directory(
    test_dir,
    target_size=(224, 224),
    batch_size=32,
    class_mode='categorical',
    shuffle=False  # Important for evaluation
)

# ======================
# MODEL ARCHITECTURE
# ======================
base_model = EfficientNetB0(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)

base_model.trainable = False

label_smoothing = 0.1
loss = tf.keras.losses.CategoricalCrossentropy(label_smoothing=label_smoothing)

model = models.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.BatchNormalization(),
    
    layers.Dense(256, kernel_regularizer=regularizers.L2(0.01)),
    layers.BatchNormalization(),
    layers.Activation('relu'),
    layers.Dropout(0.5),
    
    layers.Dense(128, kernel_regularizer=regularizers.L2(0.01)),
    layers.BatchNormalization(),
    layers.Activation('relu'),
    layers.Dropout(0.4),
    
    layers.Dense(len(train_generator.class_indices), activation='softmax')
])

# ======================
# TRAINING SETUP (WITH OPTIMIZATIONS)
# ======================
# Custom callback for learning rate tracking
class LRTracker(callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        lr = K.get_value(self.model.optimizer.learning_rate)
        print(f"\nCurrent learning rate: {lr:.2e}")

# Enhanced callbacks list
callbacks_list = [
    callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, 
                               min_lr=1e-6, verbose=1),
    callbacks.EarlyStopping(monitor='val_loss', patience=10, 
                           restore_best_weights=True, verbose=1),
    callbacks.ModelCheckpoint('best_model.keras', monitor='val_accuracy',
                            save_best_only=True, verbose=1),
    callbacks.TensorBoard(log_dir='./logs'),
    LRTracker()
]

# Compile with gradient clipping
model.compile(
    optimizer=optimizers.Adam(learning_rate=0.0001, clipnorm=1.0),
    loss=loss,
    metrics=['accuracy']
)

# ======================
# PHASE 1: INITIAL TRAINING
# ======================
print("\n=== PHASE 1: INITIAL TRAINING ===")
history1 = model.fit(
    train_generator,
    epochs=15,
    validation_data=validation_generator,
    class_weight=class_weights_dict,
    callbacks=callbacks_list
)

# ======================
# PHASE 2: FINE-TUNING WITH OPTIMIZED UNFREEZING
# ======================
print("\n=== PHASE 2: FINE-TUNING ===")
base_model.trainable = True

# Unfreeze top 20% of layers
unfreeze_start = int(len(base_model.layers) * 0.8)
for layer in base_model.layers[:unfreeze_start]:
    layer.trainable = False

# Recompile with lower LR and clipping
model.compile(
    optimizer=optimizers.Adam(learning_rate=1e-5, clipnorm=1.0),
    loss=loss,
    metrics=['accuracy']
)

history2 = model.fit(
    train_generator,
    epochs=15,
    validation_data=validation_generator,
    class_weight=class_weights_dict,
    callbacks=callbacks_list
)

# ======================
# TEST-TIME AUGMENTATION (TTA) - IMPROVED VERSION
# ======================
def predict_with_tta(model, generator, tta_steps=5):
    """Enhanced TTA implementation that processes the entire dataset"""
    tta_datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        rotation_range=10,
        width_shift_range=0.1,
        height_shift_range=0.1,
        zoom_range=0.1,
        horizontal_flip=True
    )
    
    all_preds = []
    all_labels = []
    
    # Reset generator to ensure we start from the beginning
    generator.reset()
    
    # Process all batches
    for i in range(len(generator)):
        batch_images, batch_labels = generator[i]
        batch_preds = []
        
        for img in batch_images:
            augmented_images = [img]
            # Generate augmented versions
            for _ in range(tta_steps-1):
                aug_img = tta_datagen.random_transform(img.numpy() if tf.is_tensor(img) else img)
                augmented_images.append(aug_img)
            
            # Predict and average
            batch_pred = np.mean(model.predict(np.array(augmented_images), verbose=0), axis=0)
            batch_preds.append(batch_pred)
        
        all_preds.extend(batch_preds)
        all_labels.extend(batch_labels)
        print(f"Processed batch {i+1}/{len(generator)}", end='\r')
    
    return np.array(all_preds), np.array(all_labels)

# ======================
# COMPREHENSIVE EVALUATION
# ======================
print("\n=== COMPREHENSIVE EVALUATION WITH TTA ===")
# First evaluate without TTA for comparison
test_generator.reset()
y_pred = model.predict(test_generator, verbose=1)
y_true = test_generator.classes
class_names = list(test_generator.class_indices.keys())

print("\nClassification Report (No TTA):")
print(classification_report(y_true, np.argmax(y_pred, axis=1), target_names=class_names))

# Now evaluate with TTA
tta_preds, tta_labels = predict_with_tta(model, test_generator)
y_pred_tta = np.argmax(tta_preds, axis=1)
y_true_tta = np.argmax(tta_labels, axis=1)

# Confusion matrix with TTA
plt.figure(figsize=(12, 10))
cm = confusion_matrix(y_true_tta, y_pred_tta)
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=class_names,
            yticklabels=class_names)
plt.xlabel('Predicted')
plt.ylabel('True')
plt.title('Confusion Matrix with TTA (Full Test Set)')
plt.tight_layout()
plt.savefig('confusion_matrix_tta_full.png')
plt.show()

print("\nClassification Report with TTA:")
print(classification_report(y_true_tta, y_pred_tta, target_names=class_names))

# ======================
# MODEL SAVING
# ======================
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
model.save(f'model_{timestamp}.keras')
print("\n=== MODEL SAVED WITH ALL OPTIMIZATIONS ===")