import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database.dart';
import '../widgets/product_card.dart';

class StoreCatalogPage extends StatefulWidget {
  final String storeId;

  const StoreCatalogPage({super.key, required this.storeId});

  @override
  State<StoreCatalogPage> createState() => _StoreCatalogPageState();
}

class _StoreCatalogPageState extends State<StoreCatalogPage> {
  late AppDatabase _database;
  Store? store;
  User? owner;
  List<Product> _allProducts = [];
  bool _isLoading = true;
  
  // Filter & Sort
  String _selectedSort = 'Default';
  final List<String> _sortOptions = [
    'Default',
    'By name (A to Z)',
    'By name (Z to A)',
    'By price (Lowest)',
    'By price (Highest)',
  ];
  
  Set<String> _selectedFilters = {};
  final List<String> _categories = [
    'Smartphone',
    'Laptop',
    'Tablet',
    'Accessories',
    'Wearables',
  ];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    _database = await AppDatabase.getInstance();
    await _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    
    try {
      final storeId = int.parse(widget.storeId);
      
      // Load store
      final loadedStore = await _database.storeDao.getStoreById(storeId);
      
      if (loadedStore != null) {
        // Load owner
        final loadedOwner = await _database.userDao.getUserById(loadedStore.ownerId);
        
        // Load products
        final products = await _database.productDao.getProductsByStore(storeId);
        
        setState(() {
          store = loadedStore;
          owner = loadedOwner;
          _allProducts = products;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading store: $e'),
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

  void _showFiltersBottomSheet() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Filter by Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _categories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: _selectedFilters.contains(category),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedFilters.add(category);
                          } else {
                            _selectedFilters.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedFilters.clear();
                    });
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 18,
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
              ),
              const Divider(height: 1),
              ..._sortOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _selectedSort,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredProducts = _getFilteredAndSortedProducts();
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text('Store Catalog'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : store == null
          ? const Center(
              child: Text('Store not found'),
            )
          : Column(
              children: [
                // Store Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Store Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Store Name
                      Text(
                        store!.storeName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Phone Number
                      if (owner != null)
                        InkWell(
                          onTap: () => _launchPhone(owner!.phoneNumber),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  owner!.phoneNumber,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Products Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_allProducts.length} products',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filter & Sort Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Filter Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showFiltersBottomSheet,
                          icon: Badge(
                            isLabelVisible: _selectedFilters.isNotEmpty,
                            label: Text(_selectedFilters.length.toString()),
                            child: const Icon(Icons.filter_list),
                          ),
                          label: const Text('Filter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Sort Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSortBottomSheet,
                          icon: const Icon(Icons.sort),
                          label: const Text('Sort'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Products Grid
                Expanded(
                  child: filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              context.push('/product/${product.id}');
                            },
                            onBuyNow: () {
                              context.push('/product/${product.id}');
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
