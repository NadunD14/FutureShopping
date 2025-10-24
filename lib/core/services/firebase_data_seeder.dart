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

  /// Seed two shops with at least 10 items each:
  /// - Shop 101: Clothing
  /// - Shop 102: Electrical
  /// Existing data was cleared by the user, so we only add documents (no deletes).
  static Future<void> seedTwoShopsData() async {
    try {
      print('Seeding two shops (101: Clothing, 102: Electrical)...');

      // Clothing items (Shop 101)
      final clothing = <Product>[
        Product(
          id: 'C101-001',
          name: 'Classic White T-Shirt',
          price: 14.99,
          description: '100% cotton crew neck tee, breathable and soft.',
          imageUrl:
              'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=800',
          category: 'Clothing',
          brand: 'BasicWear',
          features: ['Cotton', 'Unisex', 'Machine Washable'],
        ),
        Product(
          id: 'C101-002',
          name: 'Slim Fit Jeans',
          price: 49.99,
          description: 'Stretch denim with slim fit cut for everyday comfort.',
          imageUrl:
              'https://images.unsplash.com/photo-1516826957135-700dedea698c?w=800',
          category: 'Clothing',
          brand: 'DenimCo',
          features: ['Stretch', '5 Pockets', 'Mid Rise'],
        ),
        Product(
          id: 'C101-003',
          name: 'Hooded Sweatshirt',
          price: 39.99,
          description: 'Fleece-lined hoodie with kangaroo pocket.',
          imageUrl:
              'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800',
          category: 'Clothing',
          brand: 'CozyFit',
          features: ['Fleece', 'Drawstring Hood', 'Ribbed Cuffs'],
        ),
        Product(
          id: 'C101-004',
          name: 'Athletic Sneakers',
          price: 69.99,
          description: 'Lightweight trainers for running and gym.',
          imageUrl:
              'https://images.unsplash.com/photo-1528701800489-20be3c2ea4b5?w=800',
          category: 'Clothing',
          brand: 'RunFast',
          features: ['Mesh Upper', 'Foam Midsole', 'Non-slip'],
        ),
        Product(
          id: 'C101-005',
          name: 'Casual Chinos',
          price: 44.99,
          description: 'Versatile chinos with tapered leg.',
          imageUrl:
              'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=800',
          category: 'Clothing',
          brand: 'SmartWear',
          features: ['Tapered', 'Breathable', '2 Side Pockets'],
        ),
        Product(
          id: 'C101-006',
          name: 'Denim Jacket',
          price: 59.99,
          description: 'Classic denim jacket with metal buttons.',
          imageUrl:
              'https://images.unsplash.com/photo-1520975618319-27b9c5f5f77b?w=800',
          category: 'Clothing',
          brand: 'DenimCo',
          features: ['Classic Fit', 'Chest Pockets', 'Durable'],
        ),
        Product(
          id: 'C101-007',
          name: 'Formal Shirt',
          price: 34.99,
          description: 'Slim-fit non-iron cotton shirt.',
          imageUrl:
              'https://images.unsplash.com/photo-1520975682134-148c8b3f83d1?w=800',
          category: 'Clothing',
          brand: 'OfficeLine',
          features: ['Non-Iron', 'Slim Fit', 'Button Cuffs'],
        ),
        Product(
          id: 'C101-008',
          name: 'Summer Dress',
          price: 39.99,
          description: 'Floral print A-line summer dress.',
          imageUrl:
              'https://images.unsplash.com/photo-1520975610246-6f8d0c49f1f5?w=800',
          category: 'Clothing',
          brand: 'SunStyle',
          features: ['A-Line', 'Lightweight', 'Floral Print'],
        ),
        Product(
          id: 'C101-009',
          name: 'Leather Belt',
          price: 19.99,
          description: 'Genuine leather belt with metal buckle.',
          imageUrl:
              'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
          category: 'Clothing',
          brand: 'Crafted',
          features: ['Genuine Leather', 'Adjustable', 'Durable Buckle'],
        ),
        Product(
          id: 'C101-010',
          name: 'Wool Beanie',
          price: 14.99,
          description: 'Warm knit beanie for cold days.',
          imageUrl:
              'https://images.unsplash.com/photo-1519683105970-3d4727e72436?w=800',
          category: 'Clothing',
          brand: 'CozyFit',
          features: ['Wool Blend', 'One Size', 'Ribbed Knit'],
        ),
      ];

      // Electrical items (Shop 102)
      final electrical = <Product>[
        Product(
          id: 'E102-001',
          name: 'LED Smart TV 55"',
          price: 499.99,
          description: '4K UHD Smart TV with HDR and streaming apps.',
          imageUrl:
              'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800',
          category: 'Electrical',
          brand: 'VisionTech',
          features: ['4K HDR', 'Smart Apps', '3x HDMI'],
        ),
        Product(
          id: 'E102-002',
          name: 'Bluetooth Speaker',
          price: 59.99,
          description: 'Portable wireless speaker with deep bass.',
          imageUrl:
              'https://images.unsplash.com/photo-1518441982128-6f6f1c4e4e51?w=800',
          category: 'Electrical',
          brand: 'SoundGo',
          features: ['Water Resistant', '12h Battery', 'Bluetooth 5.0'],
        ),
        Product(
          id: 'E102-003',
          name: 'Air Fryer 5L',
          price: 89.99,
          description: 'Oil-less cooking with multiple presets.',
          imageUrl:
              'https://images.unsplash.com/photo-1604908177306-1ec2a029634b?w=800',
          category: 'Electrical',
          brand: 'KitchenPro',
          features: ['Rapid Air', 'Non-stick Basket', 'Timer'],
        ),
        Product(
          id: 'E102-004',
          name: 'Robot Vacuum',
          price: 199.99,
          description: 'Auto vacuum with app control and scheduling.',
          imageUrl:
              'https://images.unsplash.com/photo-1583947215259-38e31be8751c?w=800',
          category: 'Electrical',
          brand: 'CleanBot',
          features: ['App Control', 'Edge Cleaning', 'Auto Dock'],
        ),
        Product(
          id: 'E102-005',
          name: 'Microwave Oven 30L',
          price: 129.99,
          description: 'Digital microwave with grill function.',
          imageUrl:
              'https://images.unsplash.com/photo-1601050690597-9d36a5e3f28d?w=800',
          category: 'Electrical',
          brand: 'CookMaster',
          features: ['Grill', 'Child Lock', 'Auto Menus'],
        ),
        Product(
          id: 'E102-006',
          name: 'Smartphone Charger 30W',
          price: 24.99,
          description: 'Fast USB-C charger with Power Delivery.',
          imageUrl:
              'https://images.unsplash.com/photo-1611175694988-dcec08f31ee9?w=800',
          category: 'Electrical',
          brand: 'ChargeUp',
          features: ['30W PD', 'Compact', 'Safety Protections'],
        ),
        Product(
          id: 'E102-007',
          name: 'Wireless Earbuds',
          price: 79.99,
          description: 'True wireless earbuds with noise isolation.',
          imageUrl:
              'https://images.unsplash.com/photo-1585386959984-a41552231604?w=800',
          category: 'Electrical',
          brand: 'AudioLite',
          features: ['Touch Controls', 'Charging Case', 'AAC'],
        ),
        Product(
          id: 'E102-008',
          name: 'Gaming Keyboard',
          price: 59.99,
          description: 'Mechanical keyboard with RGB lighting.',
          imageUrl:
              'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
          category: 'Electrical',
          brand: 'KeyPro',
          features: ['Mechanical', 'RGB', 'Anti-Ghosting'],
        ),
        Product(
          id: 'E102-009',
          name: 'Action Camera 4K',
          price: 149.99,
          description: 'Waterproof 4K action camera with stabilization.',
          imageUrl:
              'https://images.unsplash.com/photo-1508896694512-5d56c1d16846?w=800',
          category: 'Electrical',
          brand: 'AdventureCam',
          features: ['4K 60fps', 'Waterproof', 'Stabilization'],
        ),
        Product(
          id: 'E102-010',
          name: 'Smart Home Plug',
          price: 19.99,
          description: 'Wi‑Fi plug compatible with voice assistants.',
          imageUrl:
              'https://images.unsplash.com/photo-1517059224940-d4af9eec41e5?w=800',
          category: 'Electrical',
          brand: 'HomeLink',
          features: ['Wi‑Fi', 'Energy Monitor', 'Schedules'],
        ),
      ];

      // Write all products
      for (final p in [...clothing, ...electrical]) {
        await _firestore.collection('products').doc(p.id).set(p.toJson());
        print('Added product: ${p.name} (${p.id})');
      }

      print('Two shops seeding completed.');
    } catch (e) {
      print('Error seeding two shops: $e');
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
