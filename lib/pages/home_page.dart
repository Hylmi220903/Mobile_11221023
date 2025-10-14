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
  String _selectedSort = 'By rating';
  final List<String> _sortOptions = [
    'By rating',
    'By name (A to Z)', 
    'By name (Z to A)',
    'By price (Lowest)',
    'By price (Highest)',
  ];

  List<Product> _getSortedProducts() {
    List<Product> sortedProducts = List.from(Product.sampleProducts);
    switch (_selectedSort) {
      case 'By name (A to Z)':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'By name (Z to A)':
        sortedProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'By price (Lowest)':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'By price (Highest)':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
          // Sort Section with M3 dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sort,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sort by:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSort = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62, // Adjusted for full-width button
              ),
              itemCount: _getSortedProducts().length,
              itemBuilder: (context, index) {
                final product = _getSortedProducts()[index];
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
