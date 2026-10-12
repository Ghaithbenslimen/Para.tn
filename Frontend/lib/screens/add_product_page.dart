import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final ProductService _productService = ProductService();

  // Form controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _howToUseController = TextEditingController();

  // Updated categories as requested
  final List<String> _categories = [
    'Moisturizers',
    'Cleansers',
    'Eye creams',
    'Sheet masks',
    'Serums',
    'Sunscreens'
  ];

  // Skin types selection
  final List<String> _skinTypes = [
    'Normal',
    'Dry',
    'Oily',
    'Combination',
    'Sensitive'
  ];
  List<String> _selectedSkinTypes = [];

  String _selectedCategory = 'Moisturizers';
  String _selectedInterfaceAsiss = 'none';
  File? _imageFile;
  double _discountPercentage = 0;
  bool _hasDiscount = false;
  String? _token;

  // Interface Asiss options
  final List<String> _interfaceAssissOptions = [
    'none',
    'Acne',
    'Actinic Keratosis',
    'Basal Cell Carcinoma',
    'Eczema',
    'Rosacea'
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _howToUseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _submitProductForm() async {
    if (_productNameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _howToUseController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and add an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication token missing. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _productNameController.text,
      category: _selectedCategory,
      price: double.parse(_priceController.text),
      quantity: int.parse(_quantityController.text),
      description: _descriptionController.text,
      howToUse: _howToUseController.text,
      interfaceAsiss: _selectedInterfaceAsiss,
      hasDiscount: _hasDiscount,
      discountPercentage: _discountPercentage,
      imagePath: _imageFile!.path,
      skinTypes: _selectedSkinTypes, // Set selected skin types
    );

    try {
      bool success = await _productService.addProduct(newProduct, _token!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset the form
        _productNameController.clear();
        _priceController.clear();
        _quantityController.clear();
        _descriptionController.clear();
        _howToUseController.clear();
        setState(() {
          _selectedCategory = 'Moisturizers';
          _selectedInterfaceAsiss = 'none';
          _imageFile = null;
          _hasDiscount = false;
          _discountPercentage = 0;
          _selectedSkinTypes = []; // Reset skin types selection
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while adding the product.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double originalPrice = double.tryParse(_priceController.text) ?? 0;
    double discountedPrice = _hasDiscount
        ? originalPrice - (originalPrice * _discountPercentage / 100)
        : originalPrice;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Product',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fill in the details to add a new product to your inventory',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey[500],
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Product Image',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Product Name
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                ),
                SizedBox(height: 16),
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                // InterfaceAsiss Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedInterfaceAsiss,
                  decoration: InputDecoration(
                    labelText: 'IntelfaceAsiss soin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.healing),
                  ),
                  items: _interfaceAssissOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInterfaceAsiss = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                // Skin Types Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skin Types (Select all that apply)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _skinTypes.map((type) {
                        return FilterChip(
                          label: Text(type),
                          selected: _selectedSkinTypes.contains(type),
                          onSelected: (selected) {
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
                ),
                SizedBox(height: 16),
                // Price and Quantity
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price (\DT)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Discount Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasDiscount,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                _hasDiscount = value!;
                              });
                            },
                          ),
                          Text(
                            'Apply Discount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          if (_hasDiscount && originalPrice > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_discountPercentage.toInt()}% OFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_hasDiscount) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('0%'),
                            Expanded(
                              child: Slider(
                                value: _discountPercentage,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                activeColor: Colors.green,
                                inactiveColor: Colors.green.withOpacity(0.2),
                                label: '${_discountPercentage.toInt()}%',
                                onChanged: (value) {
                                  setState(() {
                                    _discountPercentage = value;
                                  });
                                },
                              ),
                            ),
                            Text('100%'),
                          ],
                        ),
                        if (originalPrice > 0) ...[
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Original Price:',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${originalPrice.toStringAsFixed(2)}\DT',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discounted Price:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${discountedPrice.toStringAsFixed(2)}\DT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Product Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 16),
                // How to Use
                TextFormField(
                  controller: _howToUseController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'How to Use',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 24),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitProductForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Add Product',
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
        ],
      ),
    );
  }
}
