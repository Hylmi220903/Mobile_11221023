import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/product_card.dart';
import '../widgets/main_layout.dart';
import '../database/database.dart';
import '../database/seed_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppDatabase _database;
  List<Product> _allProducts = []; // Product from database
  bool _isLoading = true;
  int? _currentUserId;

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

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    // Don't close singleton instance
    super.dispose();
  }

  Future<void> _initDatabase() async {
    _database = await AppDatabase.getInstance();
    
    // Get current user ID
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
    
    // Seed initial data (Admin Apple user, store, and products)
    await seedInitialData(_database);
    
    // Load products from database
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await _database.getAllProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Product> _getFilteredAndSortedProducts() {
    List<Product> products = List.from(_allProducts);
    
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

  Future<void> _addToCart(Product product) async {
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first to add items to cart'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
      return;
    }

    try {
      await _database.addToCart(
        userId: _currentUserId!,
        productId: product.id,
        quantity: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} to cart'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    setState(() {
      _currentUserId = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    }
  }

  void _showFiltersBottomSheet() {
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
    
    return MainLayout(
      currentIndex: 0,
      child: Scaffold(
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
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(_allProducts, _addToCart),
                );
              },
              tooltip: 'Search',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'login') {
                  context.go('/login');
                } else if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => _currentUserId == null
                  ? [
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
                    ]
                  : [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
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
                      onPressed: _showFiltersBottomSheet,
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
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
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
                        onBuyNow: () => _addToCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

// Search Delegate
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final Function(Product) onAddToCart;

  ProductSearchDelegate(this.products, this.onAddToCart);

  @override
  String get searchFieldLabel => 'Search products...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = products.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.model.toLowerCase().contains(query.toLowerCase()) ||
      product.description.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductCard(
          product: product,
          onTap: () {
            close(context, null);
            context.go('/product/${product.id}');
          },
          onBuyNow: () {
            onAddToCart(product);
          },
        );
      },
    );
  }
}
