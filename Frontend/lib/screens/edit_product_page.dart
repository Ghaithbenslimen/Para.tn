import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _howToUseController;
  late TextEditingController _discountPercentageController;

  String? _selectedCategory;
  String? _selectedInterfaceAsiss;
  bool _hasDiscount = false;
  File? _imageFile;
  String? _existingImagePath;
  bool _isLoading = false;
  String? _token;

  // Category options
  final List<String> _categories = [
    'Moisturizers',
    'Cleansers',
    'Eye creams',
    'Sheet masks',
    'Serums',
    'Sunscreens'
  ];

  // Interface Asiss options
  final List<String> _interfaceAsissOptions = [
    'none',
    'Acne',
    'Actinic Keratosis',
    'Basal Cell Carcinoma',
    'Eczema',
    'Rosacea'
  ];

  // Skin types options
  final List<String> _skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive'
  ];
  List<String> _selectedSkinTypes = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _getToken();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _quantityController =
        TextEditingController(text: widget.product.quantity.toString());
    _howToUseController = TextEditingController(text: widget.product.howToUse);
    _discountPercentageController = TextEditingController(
        text: widget.product.discountPercentage.toString());

    _selectedCategory = widget.product.category;
    _selectedInterfaceAsiss = widget.product.interfaceAsiss;
    _hasDiscount = widget.product.hasDiscount;
    _existingImagePath = widget.product.imagePath;

    // Initialize selected skin types from the product
    _selectedSkinTypes = List<String>.from(widget.product.skinTypes);
  }

  Future<void> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image for faster upload
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found. Please log in again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create updated product object
      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        category: _selectedCategory ?? '',
        interfaceAsiss: _selectedInterfaceAsiss ?? 'none',
        howToUse: _howToUseController.text,
        hasDiscount: _hasDiscount,
        discountPercentage: _hasDiscount
            ? double.parse(_discountPercentageController.text)
            : 0.0,
        imagePath: _existingImagePath ?? '',
        skinTypes: _selectedSkinTypes, // Include selected skin types
      );

      // Update product in the database
      final success = await _productService.updateProduct(
        updatedProduct,
        _token!,
        newImageFile: _imageFile,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving product: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    }
  }

  // Helper method to build product image that handles network vs local images
  Widget _buildProductImage() {
    if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
      if (_existingImagePath!.startsWith('http')) {
        return Image.network(
          _existingImagePath!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey, size: 50),
            );
          },
        );
      } else if (_existingImagePath!.startsWith('uploads') ||
          _existingImagePath!.contains('\\')) {
        final normalizedPath = _existingImagePath!.replaceAll('\\', '/');
        final fullImageUrl = '${_productService.baseUrl}/$normalizedPath';

        return Image.network(
          fullImageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading server image: $error');
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[200],
              child: Icon(Icons.image, color: Colors.grey, size: 50),
            );
          },
        );
      }
    }

    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, color: Colors.grey, size: 50),
          const SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinTypesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skin Types (Select all that apply)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _skinTypes.map((type) {
            final isSelected = _selectedSkinTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedSkinTypes.add(type);
                  } else {
                    _selectedSkinTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildProductImage(),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              icon: const Icon(Icons.photo_library,
                                  color: Colors.green),
                              label: const Text('Change Image',
                                  style: TextStyle(color: Colors.green)),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product details section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Product name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.inventory_2),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Interface Asiss dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedInterfaceAsiss,
                            decoration: InputDecoration(
                              labelText: 'Interface Asiss',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.medical_services),
                            ),
                            items: _interfaceAsissOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedInterfaceAsiss = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an interface asiss';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Skin Types selection section
                          _buildSkinTypesSelector(),
                          const SizedBox(height: 16),

                          // Price and quantity row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  decoration: InputDecoration(
                                    labelText: 'Price',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.attach_money),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a price';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.inventory),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a quantity';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Discount section
                          Row(
                            children: [
                              Checkbox(
                                value: _hasDiscount,
                                onChanged: (value) {
                                  setState(() {
                                    _hasDiscount = value ?? false;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              const Text('Has Discount'),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _discountPercentageController,
                                  decoration: InputDecoration(
                                    labelText: 'Discount %',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.percent),
                                  ),
                                  enabled: _hasDiscount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (value) {
                                    if (_hasDiscount) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter discount percentage';
                                      }
                                      final discount = double.tryParse(value);
                                      if (discount == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (discount <= 0 || discount >= 100) {
                                        return 'Discount must be between 0 and 100';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a product description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // How to use
                          TextFormField(
                            controller: _howToUseController,
                            decoration: InputDecoration(
                              labelText: 'How to Use',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter how to use instructions';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor:
                              Colors.green.withOpacity(0.6),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _howToUseController.dispose();
    _discountPercentageController.dispose();
    super.dispose();
  }
}
