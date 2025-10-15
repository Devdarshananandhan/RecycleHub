import 'package:get/get.dart';
import 'package:recyclehub/models/product_model.dart';
import 'package:recyclehub/services/storage_service.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:uuid/uuid.dart';

class ProductController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final AuthController _authController = Get.find<AuthController>();
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }
  
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final allProducts = await _storageService.getAllProducts();
      products.value = allProducts;
      filteredProducts.value = allProducts;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load products: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  void searchProducts(String query) {
    if (query.isEmpty) {
      filteredProducts.value = products;
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    filteredProducts.value = products.where((product) {
      return product.title.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery) ||
          product.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  ProductModel? getProductById(String productId) {
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  void filterByCategory(String category) {
    if (category.isEmpty) {
      filteredProducts.value = products;
      return;
    }
    
    filteredProducts.value = products.where((product) {
      return product.category == category;
    }).toList();
  }
  
  Future<void> addProduct(
    String title,
    String description,
    double price,
    String category,
    String condition,
    List<String> imagePaths,
    double sustainabilityScore,
  ) async {
    try {
      isLoading.value = true;
      
      final user = _authController.currentUser.value;
      if (user == null) {
        Get.snackbar(
          'Error',
          'You must be logged in to add a product',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      final newProduct = ProductModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        location: user.city,
        images: imagePaths,
        sellerId: user.id,
        sellerName: user.name,
        createdAt: DateTime.now(),
        sustainabilityScore: sustainabilityScore,
      );
      
      await _storageService.saveProduct(newProduct);
      await fetchProducts();
      
      Get.back();
      Get.snackbar(
        'Success',
        'Product added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateProduct(ProductModel product) async {
    try {
      isLoading.value = true;
      await _storageService.updateProduct(product);
      await fetchProducts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      await _storageService.deleteProduct(productId);
      await fetchProducts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<List<ProductModel>> getUserProducts() async {
    final user = _authController.currentUser.value;
    if (user == null) {
      return [];
    }
    
    return await _storageService.getProductsByUser(user.id);
  }
}