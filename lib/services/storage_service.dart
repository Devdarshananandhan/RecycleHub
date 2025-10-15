import 'dart:convert';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclehub/models/user_model.dart';
import 'package:recyclehub/models/product_model.dart';

class StorageService extends GetxService {
  static const String userBox = 'userBox';
  static const String productsBox = 'productsBox';
  static const String currentUserKey = 'currentUser';
  
  Future<StorageService> init() async {
    await Hive.initFlutter();
    return this;
  }
  
  Future<Box> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    } else {
      return await Hive.openBox(boxName);
    }
  }
  
  // User related methods
  Future<void> saveUser(UserModel user) async {
    final box = await _openBox(userBox);
    await box.put(currentUserKey, jsonEncode(user.toJson()));
    await box.put('user_${user.email}', jsonEncode(user.toJson()));
  }
  
  Future<UserModel?> getUser() async {
    final box = await _openBox(userBox);
    final userData = box.get(currentUserKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  Future<UserModel?> getUserByEmail(String email) async {
    final box = await _openBox(userBox);
    final userData = box.get('user_$email');
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  Future<void> removeUser() async {
    final box = await _openBox(userBox);
    await box.delete(currentUserKey);
  }
  
  // Generic data methods
  Future<dynamic> getData(String key, {String boxName = 'dataBox'}) async {
    final box = await _openBox(boxName);
    return box.get(key);
  }
  
  Future<void> saveData(String key, dynamic value, {String boxName = 'dataBox'}) async {
    final box = await _openBox(boxName);
    await box.put(key, value);
  }
  
  Future<void> removeData(String key, {String boxName = 'dataBox'}) async {
    final box = await _openBox(boxName);
    await box.delete(key);
  }
  
  Future<List<String>> getAllKeys({String boxName = 'dataBox'}) async {
    final box = await _openBox(boxName);
    return box.keys.cast<String>().toList();
  }
  
  // Product related methods
  Future<void> saveProduct(ProductModel product) async {
    final box = await _openBox(productsBox);
    final products = await getAllProducts();
    products.add(product);
    await box.put('all_products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }
  
  Future<List<ProductModel>> getAllProducts() async {
    final box = await _openBox(productsBox);
    final productsData = box.get('all_products');
    if (productsData != null) {
      final List<dynamic> decodedData = jsonDecode(productsData);
      return decodedData.map((item) => ProductModel.fromJson(item)).toList();
    }
    return [];
  }
  
  Future<List<ProductModel>> getProductsByUser(String userId) async {
    final allProducts = await getAllProducts();
    return allProducts.where((product) => product.sellerId == userId).toList();
  }
  
  Future<ProductModel?> getProductById(String id) async {
    final allProducts = await getAllProducts();
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> updateProduct(ProductModel product) async {
    final box = await _openBox(productsBox);
    final products = await getAllProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    
    if (index != -1) {
      products[index] = product;
      await box.put('all_products', jsonEncode(products.map((p) => p.toJson()).toList()));
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    final box = await _openBox(productsBox);
    final products = await getAllProducts();
    products.removeWhere((product) => product.id == productId);
    await box.put('all_products', jsonEncode(products.map((p) => p.toJson()).toList()));
  }
}