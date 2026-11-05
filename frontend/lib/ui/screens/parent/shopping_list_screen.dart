import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/shopping_item.dart';
import '../../../core/services/shopping_list_service.dart';
import '../../../core/services/meals_data_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _service = ShoppingListService.instance;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shopping List (કરિયાણાની યાદી)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Fresh toddler ingredients & meal items',
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share / Copy List',
            onPressed: _shareList,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'import') _showImportMealsModal();
              if (val == 'clear_done') _service.clearCompleted();
              if (val == 'clear_all') _confirmClearAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Add From Today Meals'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_done',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: AppColors.statusGreen),
                    SizedBox(width: 8),
                    Text('Clear Purchased Items'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.statusRed),
                    SizedBox(width: 8),
                    Text('Reset / Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditItemModal(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: ValueListenableBuilder<List<ShoppingItem>>(
        valueListenable: _service.itemsNotifier,
        builder: (context, allItems, _) {
          final pending = allItems.where((i) => !i.isCompleted).toList();
          final completed = allItems.where((i) => i.isCompleted).toList();
          final totalCount = allItems.length;
          final completedCount = completed.length;
          final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

          // Apply category and search filter
          final filteredPending = pending.where(_filterMatches).toList();
          final filteredCompleted = completed.where(_filterMatches).toList();

          return Column(
            children: [
              // Top Progress & Stats Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shopping Progress',
                          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: progress == 1.0 && totalCount > 0
                                ? AppColors.statusGreenContainer
                                : AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$completedCount of $totalCount bought',
                            style: AppTypography.labelSmall.copyWith(
                              color: progress == 1.0 && totalCount > 0
                                  ? AppColors.statusGreen
                                  : AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0 && totalCount > 0
                              ? AppColors.statusGreen
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search ingredients, groceries, spices...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
              ),

              // Category Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _categoryPill('All'),
                    ...ShoppingCategoryConstants.allCategories.map(_categoryPill),
                  ],
                ),
              ),

              // Content List
              Expanded(
                child: allItems.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.shopping_basket_outlined,
                        title: 'Your Shopping List is Empty',
                        subtitle: 'Generate items from planned recipes or tap "+ Add Item" below.',
                        actionText: 'Import from Today\'s Meals',
                        onAction: _showImportMealsModal,
                      )
                    : (filteredPending.isEmpty && filteredCompleted.isEmpty)
                        ? _buildEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No Matching Groceries',
                            subtitle: 'Try a different search term or category filter.',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            children: [
                              // Remaining / Needed Items
                              if (filteredPending.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                                  child: Text(
                                    'TO BUY (${filteredPending.length})',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                ...filteredPending.map((item) => _buildItemTile(item)),
                              ],

                              // Completed / Purchased Items
                              if (filteredCompleted.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.statusGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PURCHASED (${filteredCompleted.length})',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.statusGreen,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => _service.clearCompleted(),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      ),
                                    ],
                                  ),
                                ),
                                ...filteredCompleted.map((item) => _buildItemTile(item)),
                              ],
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _filterMatches(ShoppingItem item) {
    if (_selectedCategory != 'All' && item.category != _selectedCategory) {
      return false;
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final inName = item.name.toLowerCase().contains(q);
      final inCat = item.category.toLowerCase().contains(q);
      final inSource = item.sourceMealTitle?.toLowerCase().contains(q) ?? false;
      return inName || inCat || inSource;
    }
    return true;
  }

  Widget _categoryPill(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          category,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCompleted ? AppColors.statusGreen.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: item.isCompleted,
          activeColor: AppColors.statusGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (_) => _service.toggleItem(item.id),
        ),
        title: Text(
          item.name,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.quantity,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '• ${item.category}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
              onPressed: () => _showAddEditItemModal(item: item),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () => _service.removeItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.download_rounded),
                label: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddEditItemModal({ShoppingItem? item}) {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final qtyCtrl = TextEditingController(text: item?.quantity ?? '1 portion');
    String selectedCat = item?.category ?? ShoppingCategoryConstants.vegetables;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit Shopping Item' : 'Add Custom Grocery Item',
                      style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Item Name (e.g., Organic Cow Ghee, Ragi Flour)',
                        prefixIcon: Icon(Icons.shopping_cart_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (e.g., 2 tbsp, 250g, 1 cup)',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Category',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ShoppingCategoryConstants.allCategories.map((cat) {
                        final isSel = selectedCat == cat;
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textPrimary)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setModalState(() => selectedCat = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final qty = qtyCtrl.text.trim();
                        if (name.isEmpty) return;

                        if (isEditing) {
                          _service.editItem(item.id, name, qty, selectedCat);
                        } else {
                          _service.addItem(name, qty, selectedCat);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Add to List'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showImportMealsModal() {
    final meals = MealsDataService.instance.allMeals;
    final Set<String> selectedMealIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Meals to Import',
                        style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (selectedMealIds.length == meals.length) {
                              selectedMealIds.clear();
                            } else {
                              selectedMealIds.addAll(meals.map((m) => m.id));
                            }
                          });
                        },
                        child: Text(
                          selectedMealIds.length == meals.length ? 'Deselect All' : 'Select All',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingredients will be extracted, categorized, and combined automatically.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, idx) {
                        final meal = meals[idx];
                        final isSel = selectedMealIds.contains(meal.id);
                        return CheckboxListTile(
                          value: isSel,
                          activeColor: AppColors.primary,
                          title: Text(meal.title, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('${meal.slotName} • ${meal.ingredients.length} ingredients', style: const TextStyle(fontSize: 11)),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedMealIds.add(meal.id);
                              } else {
                                selectedMealIds.remove(meal.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: selectedMealIds.isEmpty
                        ? null
                        : () async {
                            final chosen = meals.where((m) => selectedMealIds.contains(m.id)).toList();
                            final nav = Navigator.of(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            final count = await _service.generateFromMeals(chosen);
                            if (mounted) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Successfully imported $count ingredients from ${chosen.length} meals!'),
                                  backgroundColor: AppColors.statusGreen,
                                ),
                              );
                            }
                          },
                    child: Text('Generate List (${selectedMealIds.length} Meals)'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareList() {
    final text = _service.exportFormattedText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shopping list copied to clipboard! Ready to paste & share.'),
        backgroundColor: AppColors.statusGreen,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Shopping List?'),
        content: const Text('This will delete all items from your current shopping list. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () {
              Navigator.pop(ctx);
              _service.clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shopping list has been cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
