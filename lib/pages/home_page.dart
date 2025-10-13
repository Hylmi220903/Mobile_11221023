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
      default: // By rating - keep original order
        break;
    }
    return sortedProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 2,
            title: const Text(
              'ITKBarkas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                onPressed: () => context.go('/cart'),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.black),
                onPressed: () => context.go('/profile'),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menu coming soon...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // Filters and Sorting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD3D3D3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Icon(Icons.tune),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD3D3D3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: DropdownButton<String>(
                            value: _selectedSort,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            items: _sortOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSort = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Products count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Products Result : ',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_getSortedProducts().length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Products Grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sortedProducts = _getSortedProducts();
                    // Calculate the number of columns based on screen width
                    int crossAxisCount;
                    double aspectRatio;
                    if (constraints.maxWidth > 900) {
                      crossAxisCount = 4;
                      aspectRatio = 0.65;
                    } else if (constraints.maxWidth > 600) {
                      crossAxisCount = 3;
                      aspectRatio = 0.64;
                    } else {
                      crossAxisCount = 2;
                      aspectRatio = 0.63;
                    }
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: sortedProducts.length,
                      itemBuilder: (context, index) {
                        final product = sortedProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.go('/product/${product.id}'),
                          onBuyNow: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Buying ${product.name}...'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Pagination
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: () {},
                    ),
                    Row(
                      children: [
                        for (var i = 1; i <= 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: i == 1 ? Colors.black : const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '$i',
                                style: TextStyle(
                                  color: i == 1 ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        const Text('....', style: TextStyle(color: Color(0xFF727272))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            '12',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}