import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';

/// Service to populate Firebase with sample data for testing
class FirebaseDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed sample products for beacon testing
  static Future<void> seedSampleData() async {
    try {
      print('Starting to seed sample data...');

      // Check if data already exists
      final existingProducts =
          await _firestore.collection('products').limit(1).get();
      if (existingProducts.docs.isNotEmpty) {
        print('Sample data already exists, skipping seeding.');
        return;
      }

      print('No existing data found, proceeding with seeding...');

      // Sample products that correspond to beacon Minor IDs
      final sampleProducts = [
        Product(
          id: '101', // This matches beacon Minor ID 101
          name: 'Samsung Galaxy S24 Ultra',
          price: 1199.99,
          description:
              'Latest flagship smartphone with AI-powered camera, S Pen support, and titanium build.',
          imageUrl:
              'https://images.samsung.com/is/image/samsung/p6pim/us/galaxy-s24-ultra/SM-S928UZAAXAA-thumb.jpg',
          discount: 0.1, // 10% discount
          rating: 4.8,
          reviewCount: 256,
          category: 'Electronics',
          brand: 'Samsung',
          isAvailable: true,
          features: [
            '200MP Camera',
            '6.8" Dynamic AMOLED Display',
            'S Pen Included',
            '5000mAh Battery',
            '12GB RAM',
            '256GB Storage'
          ],
        ),
        Product(
          id: '102', // This matches beacon Minor ID 102
          name: 'Apple iPhone 15 Pro',
          price: 999.99,
          description:
              'Revolutionary iPhone with titanium design, A17 Pro chip, and Pro camera system.',
          imageUrl:
              'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309.jpg',
          discount: 0.05, // 5% discount
          rating: 4.9,
          reviewCount: 412,
          category: 'Electronics',
          brand: 'Apple',
          isAvailable: true,
          features: [
            'A17 Pro Chip',
            '6.1" Super Retina XDR',
            'Titanium Build',
            'USB-C',
            '128GB Storage',
            'Pro Camera System'
          ],
        ),
        Product(
          id: '103', // This matches beacon Minor ID 103
          name: 'Sony WH-1000XM5 Headphones',
          price: 399.99,
          description:
              'Industry-leading noise canceling headphones with exceptional sound quality.',
          imageUrl:
              'https://www.sony.com/image/5d02da5df2e8e1bb17e1ebeb8a916dd6.jpg',
          discount: 0.15, // 15% discount
          rating: 4.7,
          reviewCount: 189,
          category: 'Audio',
          brand: 'Sony',
          isAvailable: true,
          features: [
            'Active Noise Canceling',
            '30-hour Battery',
            'Quick Charge',
            'Multipoint Connection',
            'Touch Controls',
            'LDAC Support'
          ],
        ),
        Product(
          id: '104', // This matches beacon Minor ID 104
          name: 'Nintendo Switch OLED',
          price: 349.99,
          description:
              'Enhanced Nintendo Switch with vibrant OLED screen and improved audio.',
          imageUrl:
              'https://assets.nintendo.com/image/upload/f_auto/q_auto/c_fill,w_300/ncom/en_US/switch/site-design-update/switch-oled-front.png',
          discount: 0.0, // No discount
          rating: 4.6,
          reviewCount: 324,
          category: 'Gaming',
          brand: 'Nintendo',
          isAvailable: true,
          features: [
            '7" OLED Screen',
            'Enhanced Audio',
            'Wide Adjustable Stand',
            'Dock with LAN Port',
            '64GB Storage',
            'Joy-Con Controllers'
          ],
        ),
        Product(
          id: '105', // This matches beacon Minor ID 105
          name: 'Dell XPS 13 Laptop',
          price: 1299.99,
          description:
              'Ultra-portable laptop with stunning display and premium build quality.',
          imageUrl:
              'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/xps-notebooks/xps-13-9315/pdp/laptop-xps-13-9315-pdp-mod-1.psd',
          discount: 0.2, // 20% discount
          rating: 4.5,
          reviewCount: 156,
          category: 'Computers',
          brand: 'Dell',
          isAvailable: true,
          features: [
            '13.4" InfinityEdge Display',
            'Intel Core i7',
            '16GB RAM',
            '512GB SSD',
            'Windows 11',
            'All-day Battery'
          ],
        ),
      ];

      // Add products to Firestore
      for (final product in sampleProducts) {
        await _firestore
            .collection('products')
            .doc(product.id)
            .set(product.toJson());
        print('Added product: ${product.name} (ID: ${product.id})');
      }

      // Add sample reviews
      await _addSampleReviews();

      print('Sample data seeding completed successfully!');
    } catch (e) {
      print('Error seeding sample data: $e');
    }
  }

  /// Add sample reviews for products
  static Future<void> _addSampleReviews() async {
    final sampleReviews = [
      // Reviews for Samsung Galaxy S24 Ultra (101)
      Review(
        id: '',
        productId: '101',
        userId: 'user1',
        userName: 'TechReviewer123',
        rating: 5.0,
        comment:
            'Amazing camera quality! The 200MP camera is incredible. Photos are crisp and detailed even in low light.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        helpfulVotes: 12,
      ),
      Review(
        id: '',
        productId: '101',
        userId: 'user2',
        userName: 'GalaxyFan',
        rating: 4.0,
        comment:
            'Great phone, but expensive. Love the S Pen and display, but the price is quite high.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        helpfulVotes: 8,
      ),

      // Reviews for iPhone 15 Pro (102)
      Review(
        id: '',
        productId: '102',
        userId: 'user3',
        userName: 'AppleLover',
        rating: 5.0,
        comment:
            'Perfect upgrade from iPhone 12. The titanium build feels premium and the cameras are significantly better.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        helpfulVotes: 15,
      ),
      Review(
        id: '',
        productId: '102',
        userId: 'user4',
        userName: 'PhotoEnthusiast',
        rating: 5.0,
        comment:
            'Best mobile camera system. Portrait mode and night photography are outstanding.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        helpfulVotes: 9,
      ),

      // Reviews for Sony Headphones (103)
      Review(
        id: '',
        productId: '103',
        userId: 'user5',
        userName: 'AudioPhile',
        rating: 5.0,
        comment:
            'Noise canceling is phenomenal. These headphones block out all external noise. Perfect for flights.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        helpfulVotes: 20,
      ),
    ];

    for (final review in sampleReviews) {
      await _firestore.collection('reviews').add(review.toJson());
      print('Added review for product ${review.productId}');
    }
  }

  /// Clear all sample data (for testing)
  static Future<void> clearSampleData() async {
    try {
      // Delete products
      final productsSnapshot = await _firestore.collection('products').get();
      for (final doc in productsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete reviews
      final reviewsSnapshot = await _firestore.collection('reviews').get();
      for (final doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Sample data cleared successfully!');
    } catch (e) {
      print('Error clearing sample data: $e');
    }
  }
}
