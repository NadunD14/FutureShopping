import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:async/async.dart';
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

// Beacon distances stream (meters) keyed by mapped beacon id ('101','102')
final beaconDistancesProvider = StreamProvider<Map<String, double>>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return bleService.beaconDistancesStream;
});

// Derive closest shop category from beacon distances or active beacon
final closestShopCategoryProvider = StreamProvider<String?>((ref) async* {
  final distancesStream = ref.watch(beaconDistancesProvider.stream);
  final activeBeaconStream = ref.watch(activeBeaconProvider.stream);

  // Merge two streams in a simple loop by awaiting whichever emits first
  Map<String, double> lastDistances = const {};
  String? lastActive;

  await for (final _ in StreamGroup.merge([
    distancesStream.map((d) => 'd'),
    activeBeaconStream.map((a) => 'a'),
  ])) {
    // Update snapshots
    final d = await distancesStream.first;
    lastDistances = d;
    lastActive = await activeBeaconStream.first;

    String? shop;
    if (lastDistances.containsKey('101') || lastDistances.containsKey('102')) {
      final d1 = lastDistances['101'] ?? double.infinity;
      final d2 = lastDistances['102'] ?? double.infinity;
      if (d1 == double.infinity && d2 == double.infinity) {
        shop = null;
      } else if (d1 <= d2) {
        shop = 'Clothing';
      } else {
        shop = 'Electrical';
      }
    } else if (lastActive == '101' || lastActive == '102') {
      shop = lastActive == '101' ? 'Clothing' : 'Electrical';
    } else {
      shop = null;
    }
    yield shop;
  }
});

// Relative position between two beacons (0.0 near 101, 1.0 near 102)
final twoBeaconRelativePositionProvider = StreamProvider<double?>((ref) async* {
  final distancesStream = ref.watch(beaconDistancesProvider.stream);
  await for (final distances in distancesStream) {
    final d1 = distances['101'];
    final d2 = distances['102'];
    if (d1 == null && d2 == null) {
      yield null;
    } else if (d1 != null && d2 != null && d1.isFinite && d2.isFinite) {
      final sum = d1 + d2;
      if (sum <= 0) {
        yield 0.5;
      } else {
        // Inverse-distance weighting mapped to [0,1]
        final w1 = 1.0 / (d1 + 1e-6);
        final w2 = 1.0 / (d2 + 1e-6);
        final t = w2 / (w1 + w2); // 0 near 101, 1 near 102
        yield t.clamp(0.0, 1.0);
      }
    } else if (d1 != null) {
      yield 0.0;
    } else if (d2 != null) {
      yield 1.0;
    } else {
      yield null;
    }
  }
});

// Products for the closest shop category
final closestShopProductsProvider = FutureProvider<List<Product>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final shopCategoryAsync = ref.watch(closestShopCategoryProvider);
  final shopCategory = await shopCategoryAsync.maybeWhen(
    data: (v) => v,
    orElse: () => null,
  );
  if (shopCategory == null) return [];
  return firestoreService.getProductsByCategory(shopCategory);
});

// Current product provider based on active beacon (stream-based for responsiveness)
final currentProductProvider = StreamProvider<Product?>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final beaconStream = ref.watch(activeBeaconProvider.stream);

  await for (final beaconId in beaconStream) {
    if (beaconId == null) {
      yield null;
      continue;
    }
    try {
      final product = await firestoreService.getProduct(beaconId);
      yield product;
    } catch (_) {
      yield null;
    }
  }
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
