import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../widgets/list_item_widget.dart';

/// Shopping list item model
class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.isCompleted = false,
    this.productId,
    this.estimatedPrice,
    this.notes = '',
  });

  final String id;
  final String name;
  final int quantity;
  final bool isCompleted;
  final String? productId;
  final double? estimatedPrice;
  final String notes;

  ShoppingListItem copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? isCompleted,
    String? productId,
    double? estimatedPrice,
    String? notes,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      productId: productId ?? this.productId,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      notes: notes ?? this.notes,
    );
  }
}

/// State notifier for shopping list
class ShoppingListNotifier extends StateNotifier<List<ShoppingListItem>> {
  ShoppingListNotifier() : super([]);

  /// Add item to shopping list
  void addItem(ShoppingListItem item) {
    state = [...state, item];
  }

  /// Remove item from shopping list
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Toggle item completion status
  void toggleItemCompletion(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
  }

  /// Update item quantity
  void updateItemQuantity(String id, int quantity) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  /// Update item notes
  void updateItemNotes(String id, String notes) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(notes: notes);
      }
      return item;
    }).toList();
  }

  /// Clear all completed items
  void clearCompleted() {
    state = state.where((item) => !item.isCompleted).toList();
  }

  /// Clear all items
  void clearAll() {
    state = [];
  }
}

/// Provider for shopping list
final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>((ref) {
  return ShoppingListNotifier();
});

/// Screen for managing shopping list
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shoppingList = ref.watch(shoppingListProvider);
    final completedItems =
        shoppingList.where((item) => item.isCompleted).toList();
    final pendingItems =
        shoppingList.where((item) => !item.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (shoppingList.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear_completed':
                    ref.read(shoppingListProvider.notifier).clearCompleted();
                    break;
                  case 'clear_all':
                    _showClearAllDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                if (completedItems.isNotEmpty)
                  const PopupMenuItem<String>(
                    value: 'clear_completed',
                    child: Text('Clear Completed'),
                  ),
                const PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Text('Clear All'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Add item section
          _buildAddItemSection(),

          // List summary
          if (shoppingList.isNotEmpty)
            _buildListSummary(pendingItems, completedItems),

          // Shopping list
          Expanded(
            child: shoppingList.isEmpty
                ? _buildEmptyState()
                : _buildShoppingList(pendingItems, completedItems),
          ),
        ],
      ),
    );
  }

  /// Build add item section
  Widget _buildAddItemSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppConstants.textDisabledColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add New Item', style: AppConstants.titleMedium),
          const SizedBox(height: AppConstants.paddingM),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemController,
                  decoration: const InputDecoration(
                    hintText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              ElevatedButton(onPressed: _addItem, child: const Icon(Icons.add)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build list summary
  Widget _buildListSummary(
    List<ShoppingListItem> pendingItems,
    List<ShoppingListItem> completedItems,
  ) {
    final totalItems = pendingItems.length + completedItems.length;
    final totalEstimatedPrice = pendingItems
        .where((item) => item.estimatedPrice != null)
        .fold(0.0, (sum, item) => sum + (item.estimatedPrice! * item.quantity));

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: const BoxDecoration(color: AppConstants.primaryLightColor),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Items: $totalItems',
                  style: AppConstants.titleSmall,
                ),
                Text(
                  'Pending: ${pendingItems.length}, Completed: ${completedItems.length}',
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (totalEstimatedPrice > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Estimated Total',
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                Text(
                  AppConstants.formatPrice(totalEstimatedPrice),
                  style: AppConstants.priceStyleMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: AppConstants.iconSizeXL * 2,
              color: AppConstants.textDisabledColor,
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              'Your Shopping List is Empty',
              style: AppConstants.titleLarge.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              'Add items to your shopping list to keep track of what you need to buy.',
              style: AppConstants.bodyMedium.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build shopping list
  Widget _buildShoppingList(
    List<ShoppingListItem> pendingItems,
    List<ShoppingListItem> completedItems,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      children: [
        // Pending items
        if (pendingItems.isNotEmpty) ...[
          Text(
            'To Buy (${pendingItems.length})',
            style: AppConstants.titleMedium.copyWith(
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          ...pendingItems.map(
            (item) => ListItemWidget(
              item: item,
              onToggle: () => ref
                  .read(shoppingListProvider.notifier)
                  .toggleItemCompletion(item.id),
              onDelete: () =>
                  ref.read(shoppingListProvider.notifier).removeItem(item.id),
              onQuantityChanged: (quantity) => ref
                  .read(shoppingListProvider.notifier)
                  .updateItemQuantity(item.id, quantity),
              onNotesChanged: (notes) => ref
                  .read(shoppingListProvider.notifier)
                  .updateItemNotes(item.id, notes),
            ),
          ),
        ],

        // Completed items
        if (completedItems.isNotEmpty) ...[
          if (pendingItems.isNotEmpty)
            const SizedBox(height: AppConstants.paddingL),
          Text(
            'Completed (${completedItems.length})',
            style: AppConstants.titleMedium.copyWith(
              color: AppConstants.successColor,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          ...completedItems.map(
            (item) => ListItemWidget(
              item: item,
              onToggle: () => ref
                  .read(shoppingListProvider.notifier)
                  .toggleItemCompletion(item.id),
              onDelete: () =>
                  ref.read(shoppingListProvider.notifier).removeItem(item.id),
              onQuantityChanged: (quantity) => ref
                  .read(shoppingListProvider.notifier)
                  .updateItemQuantity(item.id, quantity),
              onNotesChanged: (notes) => ref
                  .read(shoppingListProvider.notifier)
                  .updateItemNotes(item.id, notes),
            ),
          ),
        ],
      ],
    );
  }

  /// Add item to shopping list
  void _addItem() {
    final itemName = _itemController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityText) ?? 1;

    final newItem = ShoppingListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: itemName,
      quantity: quantity,
    );

    ref.read(shoppingListProvider.notifier).addItem(newItem);

    _itemController.clear();
    _quantityController.clear();
  }

  /// Show clear all confirmation dialog
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Items'),
          content: const Text(
            'Are you sure you want to remove all items from your shopping list?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(shoppingListProvider.notifier).clearAll();
                Navigator.of(context).pop();
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }
}
