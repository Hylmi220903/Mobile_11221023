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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ITKBarkas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.go('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'login') {
                context.go('/login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value - Coming Soon!')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'login',
                child: Row(children: [Icon(Icons.login), SizedBox(width: 8), Text('Login')]),
              ),
              const PopupMenuItem(
                value: 'My Products',
                child: Row(children: [Icon(Icons.inventory_2_outlined), SizedBox(width: 8), Text('My Products')]),
              ),
              const PopupMenuItem(
                value: 'My Orders',  
                child: Row(children: [Icon(Icons.receipt_long_outlined), SizedBox(width: 8), Text('My Orders')]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Sort: '),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    items: _sortOptions.map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSort = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _getSortedProducts().length,
              itemBuilder: (context, index) {
                final product = _getSortedProducts()[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                  onBuyNow: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Buying ${product.name}...')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
