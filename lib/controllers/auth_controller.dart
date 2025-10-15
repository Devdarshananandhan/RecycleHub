import 'package:get/get.dart';
import 'package:recyclehub/models/user_model.dart';
import 'package:recyclehub/services/storage_service.dart';

class AuthController extends GetxController {
  final StorageService _storageService = Get.put(StorageService());
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check if user is already logged in
    checkUserLoggedIn();
  }

  Future<void> checkUserLoggedIn() async {
    final userData = await _storageService.getUser();
    if (userData != null) {
      currentUser.value = userData;
    }
  }

  Future<void> login(String email, String password, Function onSuccess) async {
    try {
      isLoading.value = true;
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if user exists in local storage
      final user = await _storageService.getUserByEmail(email);
      
      if (user != null && user.password == password) {
        currentUser.value = user;
        await _storageService.saveUser(user);
        onSuccess();
      } else {
        Get.snackbar(
          'Error',
          'Invalid email or password',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String city,
    Function onSuccess,
  ) async {
    try {
      isLoading.value = true;
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if user already exists
      final existingUser = await _storageService.getUserByEmail(email);
      
      if (existingUser != null) {
        Get.snackbar(
          'Error',
          'Email already registered',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Create new user
      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        password: password,
        city: city,
        profileImage: '',
        rating: 0,
      );
      
      await _storageService.saveUser(newUser);
      currentUser.value = newUser;
      onSuccess();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Registration failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _storageService.removeUser();
    currentUser.value = null;
    Get.offAllNamed('/login');
  }
  
  bool isLoggedIn() {
    return currentUser.value != null;
  }
  
  Future<void> updateProfile({
    required String name,
    required String city,
    required String profileImage,
  }) async {
    if (currentUser.value == null) return;
    
    final updatedUser = currentUser.value!.copyWith(
      name: name,
      city: city,
      profileImage: profileImage,
    );
    
    await _storageService.saveUser(updatedUser);
    currentUser.value = updatedUser;
  }
}