import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/ble_service.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/review_model.dart';

// Service providers
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService.instance;
});

// Active beacon stream provider
final activeBeaconProvider = StreamProvider<String?>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.activeBeaconStream;
});

// Current product provider based on active beacon
final currentProductProvider = FutureProvider<Product?>((ref) async {
  final activeBeaconAsync = ref.watch(activeBeaconProvider);

  return activeBeaconAsync.when(
    data: (beaconId) async {
      if (beaconId == null) return null;

      final firestoreService = ref.watch(firestoreServiceProvider);
      return await firestoreService.getProduct(beaconId);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Product by ID provider (for direct access)
final productByIdProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProduct(productId);
});

// Product reviews provider
final productReviewsProvider = FutureProvider.family<List<Review>, String>((
  ref,
  productId,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProductReviews(productId);
});

// All products provider (for browsing)
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getAllProducts();
});

// Products for comparison provider
final comparisonProductsProvider =
    FutureProvider.family<List<Product>, List<String>>((ref, productIds) async {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return await firestoreService.getProducts(productIds);
    });

// Search products provider
final searchProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  query,
) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.searchProducts(query);
});

// Products by category provider
final productsByCategoryProvider = FutureProvider.family<List<Product>, String>(
  (ref, category) async {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return await firestoreService.getProductsByCategory(category);
  },
);

// Bluetooth status provider
final bluetoothStatusProvider = FutureProvider<bool>((ref) async {
  final bleService = ref.watch(bleServiceProvider);
  return await bleService.isBluetoothEnabled();
});

// Provider for managing BLE scanning state
final bleScanningStateProvider =
    StateNotifierProvider<BleScanningStateNotifier, BleScanningState>((ref) {
      final bleService = ref.watch(bleServiceProvider);
      return BleScanningStateNotifier(bleService);
    });

// BLE scanning state
enum BleScanningState { stopped, starting, scanning, error }

// State notifier for BLE scanning
class BleScanningStateNotifier extends StateNotifier<BleScanningState> {
  final BleService _bleService;

  BleScanningStateNotifier(this._bleService) : super(BleScanningState.stopped);

  /// Start BLE scanning
  Future<void> startScanning() async {
    if (state == BleScanningState.scanning) return;

    state = BleScanningState.starting;

    try {
      await _bleService.startScanning();
      state = BleScanningState.scanning;
    } catch (e) {
      state = BleScanningState.error;
      print('Error starting BLE scan: $e');
    }
  }

  /// Stop BLE scanning
  Future<void> stopScanning() async {
    if (state == BleScanningState.stopped) return;

    try {
      await _bleService.stopScanning();
      state = BleScanningState.stopped;
    } catch (e) {
      state = BleScanningState.error;
      print('Error stopping BLE scan: $e');
    }
  }

  /// Simulate beacon detection for testing
  void simulateBeacon(String beaconId) {
    _bleService.simulateBeaconDetection(beaconId);
  }
}

// Provider for managing review form state
final reviewFormProvider =
    StateNotifierProvider<ReviewFormNotifier, ReviewFormState>((ref) {
      return ReviewFormNotifier();
    });

// Review form state
class ReviewFormState {
  const ReviewFormState({
    this.rating = 0.0,
    this.comment = '',
    this.isSubmitting = false,
    this.error = null,
    this.isSuccess = false,
  });

  final double rating;
  final String comment;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  ReviewFormState copyWith({
    double? rating,
    String? comment,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// State notifier for review form
class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier() : super(const ReviewFormState());

  void updateRating(double rating) {
    state = state.copyWith(rating: rating, error: null);
  }

  void updateComment(String comment) {
    state = state.copyWith(comment: comment, error: null);
  }

  Future<void> submitReview(
    String productId,
    String userId,
    String userName,
    WidgetRef ref,
  ) async {
    if (state.rating == 0) {
      state = state.copyWith(error: 'Please provide a rating');
      return;
    }

    if (state.comment.trim().isEmpty) {
      state = state.copyWith(error: 'Please provide a comment');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        userId: userId,
        userName: userName,
        rating: state.rating,
        comment: state.comment.trim(),
        createdAt: DateTime.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      final success = await firestoreService.addReview(review);

      if (success) {
        state = state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          rating: 0.0,
          comment: '',
        );

        // Refresh the reviews list
        ref.invalidate(productReviewsProvider(productId));
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Failed to submit review. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'An error occurred: $e',
      );
    }
  }

  void reset() {
    state = const ReviewFormState();
  }
}
