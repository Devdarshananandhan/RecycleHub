import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/controllers/product_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ProductController _productController = Get.find<ProductController>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _initControllers();
  }
  
  void _initControllers() {
    final user = _authController.currentUser.value;
    if (user != null) {
      _nameController.text = user.name;
      _cityController.text = user.city;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');
      
      // Create directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }
      
      // Generate a unique filename
      final fileName = 'profile_${_authController.currentUser.value!.id}${path.extension(image.path)}';
      final savedImage = File('${profileImagesDir.path}/$fileName');
      
      // Copy the image to the new location
      await File(image.path).copy(savedImage.path);
      
      // Update user profile
      await _authController.updateProfile(
        name: _authController.currentUser.value!.name,
        city: _authController.currentUser.value!.city,
        profileImage: savedImage.path,
      );
    }
  }
  
  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _cityController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Name and city cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }
    
    await _authController.updateProfile(
      name: _nameController.text,
      city: _cityController.text,
      profileImage: _authController.currentUser.value!.profileImage,
    );
    
    setState(() {
      _isEditing = false;
    });
    
    Get.snackbar(
      'Success',
      'Profile updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
    );
  }
  
  void _logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _authController.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Obx(() {
        final user = _authController.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.profileImage.isNotEmpty
                          ? FileImage(File(user.profileImage))
                          : null,
                      child: user.profileImage.isEmpty
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // User Info
              if (_isEditing) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Profile'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _initControllers();
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Name'),
                  subtitle: Text(user.name),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: const Text('City'),
                  subtitle: Text(user.city),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Rating'),
                  subtitle: Text('${user.rating}/5'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('My Orders'),
                  subtitle: const Text('View purchases and sales'),
                  onTap: () {
                    Get.toNamed('/orders');
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              
              // My Products Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Obx(() {
                final myProducts = _productController.products
                    .where((p) => p.sellerId == user.id)
                    .toList();
                
                if (myProducts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'You haven\'t listed any products yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myProducts.length,
                  itemBuilder: (context, index) {
                    final product = myProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: product.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(product.images[0]),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                        title: Text(product.title),
                        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                        trailing: Chip(
                          label: Text(
                            product.isSold ? 'Sold' : 'Active',
                            style: TextStyle(
                              color: product.isSold ? Colors.white : Colors.green[800],
                            ),
                          ),
                          backgroundColor: product.isSold ? Colors.grey : Colors.green[100],
                        ),
                        onTap: () {
                          // Navigate to product details
                          Get.toNamed('/product/${product.id}');
                        },
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}