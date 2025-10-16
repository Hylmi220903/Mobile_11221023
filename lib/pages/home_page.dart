import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sorting options
  String _selectedSort = 'By rating';
  final List<String> _sortOptions = [
    'By rating',
    'By name (A to Z)', 
    'By name (Z to A)',
    'By price (Lowest)',
    'By price (Highest)',
  ];

  // Filter categories
  final List<String> _categories = [
    'Smartphone',
    'Laptop',
    'GPU',
    'CPU',
    'Headset',
    'Motherboard',
    'RAM',
    'PC Casing',
    'Fans',
    'Internal Memory',
  ];

  // Selected filters
  final Set<String> _selectedFilters = {};

  List<Product> _getFilteredAndSortedProducts() {
    List<Product> products = List.from(Product.sampleProducts);
    
    // Apply filters
    if (_selectedFilters.isNotEmpty) {
      products = products.where((product) => 
        _selectedFilters.contains(product.category)
      ).toList();
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'By name (A to Z)':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'By name (Z to A)':
        products.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'By price (Lowest)':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'By price (Highest)':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    
    return products;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Filters',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Select product categories',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedFilters.contains(category);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  _selectedFilters.add(category);
                                } else {
                                  _selectedFilters.remove(category);
                                }
                              });
                            },
                            title: Text(category),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                _selectedFilters.clear();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredProducts = _getFilteredAndSortedProducts();
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'ITKBarkas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go('/cart'),
            tooltip: 'Cart',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            tooltip: 'Profile',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'login') {
                context.go('/login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$value - Coming Soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 12),
                    Text('Login'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'My Products',
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined),
                    SizedBox(width: 12),
                    Text('My Products'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'My Orders',  
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined),
                    SizedBox(width: 12),
                    Text('My Orders'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Sort Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Filters Button
                Expanded(
                  child: SizedBox(
                    height: 48, // Fixed height untuk konsistensi
                    child: OutlinedButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list, size: 20),
                      label: Text(
                        _selectedFilters.isEmpty 
                          ? 'Filters' 
                          : 'Filters (${_selectedFilters.length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Sort Dropdown
                Expanded(
                  child: Container(
                    height: 48, // Fixed height yang sama
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSort,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        items: _sortOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSort = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Selected Filters Chips
          if (_selectedFilters.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFilters.map((filter) {
                  return Chip(
                    label: Text(filter),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedFilters.remove(filter);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          
          // Product Grid or Empty Message
          Expanded(
            child: filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Product is empty',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No products found in selected categories',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                      onBuyNow: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Adding ${product.name} to cart...'),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
