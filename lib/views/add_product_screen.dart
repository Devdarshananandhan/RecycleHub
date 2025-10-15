import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:recyclehub/controllers/product_controller.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:uuid/uuid.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'New';
  List<String> _imagePaths = [];
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Electronics', 'Furniture', 'Fashion', 'Books', 'Sports', 'Other'
  ];
  
  final List<String> _conditions = [
    'New', 'Like New', 'Good', 'Fair', 'Poor'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 5) {
      Get.snackbar(
        'Limit Reached', 
        'You can only upload up to 5 images',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
      
      // TODO: Implement AI-based tagging using TensorFlow Lite
      // This would analyze the image and suggest category, name, etc.
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imagePaths.isEmpty) {
        Get.snackbar(
          'Images Required', 
          'Please add at least one image of your product',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = _authController.currentUser.value!;
        
        // Calculate a mock sustainability score
        final sustainabilityScore = _calculateSustainabilityScore();
        
        await _productController.addProduct(
          _titleController.text,
          _descriptionController.text,
          double.parse(_priceController.text),
          _selectedCategory,
          _selectedCondition,
          _imagePaths,
          _calculateSustainabilityScore().toDouble(),
        );
        
        Get.back();
        Get.snackbar(
          'Success', 
          'Your product has been listed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
        );
      } catch (e) {
        Get.snackbar(
          'Error', 
          'Failed to add product: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Mock calculation for sustainability score
  int _calculateSustainabilityScore() {
    // In a real app, this would use more sophisticated logic
    // based on product category, condition, etc.
    int baseScore = 0;
    
    // Better condition = less manufacturing impact saved
    switch (_selectedCondition) {
      case 'New': baseScore = 1; break;
      case 'Like New': baseScore = 2; break;
      case 'Good': baseScore = 3; break;
      case 'Fair': baseScore = 4; break;
      case 'Poor': baseScore = 2; break; // Lower for poor condition as lifespan is shorter
    }
    
    // Different categories have different environmental impacts
    switch (_selectedCategory) {
      case 'Electronics': baseScore += 5; break; // High impact from manufacturing
      case 'Furniture': baseScore += 4; break;
      case 'Fashion': baseScore += 3; break;
      case 'Books': baseScore += 2; break;
      case 'Sports': baseScore += 3; break;
      default: baseScore += 2;
    }
    
    return baseScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker Section
                    Text(
                      'Product Images',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add Image Button
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 32),
                                  SizedBox(height: 4),
                                  Text('Add Image'),
                                ],
                              ),
                            ),
                          ),
                          // Selected Images
                          ..._imagePaths.asMap().entries.map((entry) {
                            final index = entry.key;
                            final path = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Product Details Form
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter product title',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your product',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        hintText: 'Enter price',
                      ),
                      keyboardType: TextInputType.number,
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
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
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
                    const SizedBox(height: 16),
                    
                    // Condition Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                      ),
                      items: _conditions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'List Product',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}