# TODO List for RecycleHub App Fixes

This file tracks the progress of implementing the approved plan to fix the Buy Now button, missing products in My Orders, and payment/delivery processes for smooth operation.

## Steps:

1. [ ] Update `lib/controllers/order_controller.dart`: Replace the placeholder `getCurrentUserId()` method to return the actual current user's ID from `AuthController().currentUser.value?.id ?? ''`. This fixes buyer/seller role detection in order management and delivery tracking screens.

2. [ ] Edit `lib/views/checkout_screen.dart`: Change the product image from `Image.network` to `Image.file(File(widget.product.images[0]))` to properly load local file paths, ensuring the product displays correctly during checkout.

3. [ ] Edit `lib/models/order_model.dart`: Standardize enums by removing lowercase variants from `OrderStatus` and `DeliveryStatus` (keep only uppercase). Update `fromJson` to handle uppercase names consistently, and adjust any references in `copyWith` or other methods if needed. This prevents potential parsing inconsistencies in status displays.

4. [ ] Verify and test changes: Run `flutter clean && flutter pub get && flutter run` to rebuild. Test the full flow: Register/login as buyer/seller, add a product, use Buy Now to checkout (prefer COD for simplicity), verify order appears in My Orders with image, process payment, update delivery status, and confirm tracking buttons work based on user role.

## Notes:
- No new dependencies; Razorpay key remains placeholder (user to replace for real integration if needed).
- After each step, update this file by marking as [x] when complete.
- Optimal approach: Minimal changes for efficiency, focusing on local storage and simulation since no backend.
