import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

/// Service class to handle all Firestore operations
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _productsCollection =>
      _firestore.collection('products');
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');

  /// Fetch a single product by its ID (Minor ID from beacon)
  Future<Product?> getProduct(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is included
        return Product.fromJson(data);
      }

      print('Product with ID $id not found in Firestore');
      return null;
    } catch (e) {
      print('Error fetching product $id: $e');
      return null;
    }
  }

  /// Fetch multiple products for comparison
  Future<List<Product>> getProducts(List<String> ids) async {
    try {
      final products = <Product>[];

      for (final id in ids) {
        final product = await getProduct(id);
        if (product != null) {
          products.add(product);
        }
      }

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  /// Fetch all products (for browsing)
  Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _productsCollection.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching all products: $e');
      return [];
    }
  }

  /// Fetch reviews for a specific product
  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Review.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  /// Add a new review for a product
  Future<bool> addReview(Review review) async {
    try {
      await _reviewsCollection.add(review.toJson());
      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  /// Update helpful votes for a review
  Future<bool> updateReviewHelpfulVotes(String reviewId, int votes) async {
    try {
      await _reviewsCollection.doc(reviewId).update({'helpfulVotes': votes});
      return true;
    } catch (e) {
      print('Error updating review votes: $e');
      return false;
    }
  }

  /// Search products by name or category
  Future<List<Product>> searchProducts(String query) async {
    try {
      final querySnapshot = await _productsCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }
}
