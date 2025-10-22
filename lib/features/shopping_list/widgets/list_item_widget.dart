import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../screens/shopping_list_screen.dart';

/// Widget to display a single shopping list item
class ListItemWidget extends StatefulWidget {
  final ShoppingListItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;
  final Function(String) onNotesChanged;

  const ListItemWidget({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onQuantityChanged,
    required this.onNotesChanged,
  });

  @override
  State<ListItemWidget> createState() => _ListItemWidgetState();
}

class _ListItemWidgetState extends State<ListItemWidget> {
  late TextEditingController _notesController;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.paddingXS),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main item row
            Row(
              children: [
                // Checkbox
                Checkbox(
                  value: widget.item.isCompleted,
                  onChanged: (_) => widget.onToggle(),
                  activeColor: AppConstants.successColor,
                ),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item name
                      Text(
                        widget.item.name,
                        style: AppConstants.titleSmall.copyWith(
                          decoration: widget.item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: widget.item.isCompleted
                              ? AppConstants.textSecondaryColor
                              : AppConstants.textPrimaryColor,
                        ),
                      ),

                      // Quantity and price
                      const SizedBox(height: AppConstants.paddingXS),
                      Row(
                        children: [
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppConstants.textDisabledColor,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusS,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: widget.item.quantity > 1
                                      ? () {
                                          widget.onQuantityChanged(
                                            widget.item.quantity - 1,
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  iconSize: AppConstants.iconSizeS,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.item.quantity.toString(),
                                    style: AppConstants.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.onQuantityChanged(
                                      widget.item.quantity + 1,
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  iconSize: AppConstants.iconSizeS,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: AppConstants.paddingM),

                          // Estimated price
                          if (widget.item.estimatedPrice != null) ...[
                            Text(
                              AppConstants.formatPrice(
                                widget.item.estimatedPrice! *
                                    widget.item.quantity,
                              ),
                              style: AppConstants.priceStyleMedium.copyWith(
                                fontSize: 14,
                                decoration: widget.item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notes button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditingNotes = !_isEditingNotes;
                        });
                      },
                      icon: Icon(
                        widget.item.notes.isNotEmpty
                            ? Icons.note
                            : Icons.note_add_outlined,
                        color: widget.item.notes.isNotEmpty
                            ? AppConstants.primaryColor
                            : AppConstants.textSecondaryColor,
                      ),
                    ),

                    // Delete button
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Notes section
            if (_isEditingNotes || widget.item.notes.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingM),
              const Divider(),
              const SizedBox(height: AppConstants.paddingS),

              if (_isEditingNotes) ...[
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Add notes...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                  onSubmitted: _saveNotes,
                ),
                const SizedBox(height: AppConstants.paddingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _notesController.text = widget.item.notes;
                        setState(() {
                          _isEditingNotes = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    ElevatedButton(
                      onPressed: () => _saveNotes(_notesController.text),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ] else if (widget.item.notes.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: AppConstants.iconSizeS,
                      color: AppConstants.textSecondaryColor,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        widget.item.notes,
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Save notes
  void _saveNotes(String notes) {
    widget.onNotesChanged(notes.trim());
    setState(() {
      _isEditingNotes = false;
    });
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
            'Remove "${widget.item.name}" from your shopping list?',
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
                widget.onDelete();
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
