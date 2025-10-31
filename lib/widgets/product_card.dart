import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class ProductCard extends StatefulWidget {
  final Product product; // Product from database
  final VoidCallback onBuyNow;
  final VoidCallback? onTap;
  final int? currentUserId; // Pass user ID from parent

  const ProductCard({
    super.key,
    required this.product,
    required this.onBuyNow,
    this.onTap,
    this.currentUserId,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isInWishlist = false;
  bool isLoading = false;
  late AppDatabase _database;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _initWishlist();
  }

  Future<void> _initWishlist() async {
    _database = await AppDatabase.getInstance();
    
    // Get user ID from widget or SharedPreferences
    if (widget.currentUserId != null) {
      _userId = widget.currentUserId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId');
    }
    
    // Check if product is in wishlist
    if (_userId != null) {
      final inWishlist = await _database.wishlistDao.isInWishlist(
        userId: _userId!,
        productId: widget.product.id,
      );
      if (mounted) {
        setState(() => isInWishlist = inWishlist);
      }
    }
  }

  Future<void> _toggleWishlist() async {
    if (_userId == null) {
      // Show login prompt
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login untuk menambahkan ke wishlist'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isInWishlist) {
        // Remove from wishlist
        await _database.wishlistDao.removeFromWishlist(
          userId: _userId!,
          productId: widget.product.id,
        );
        if (mounted) {
          setState(() {
            isInWishlist = false;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} dihapus dari wishlist'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Add to wishlist
        await _database.wishlistDao.addToWishlist(
          userId: _userId!,
          productId: widget.product.id,
        );
        if (mounted) {
          setState(() {
            isInWishlist = true;
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name} ditambahkan ke wishlist'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      surfaceTintColor: colorScheme.surfaceTint,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with favorite button
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product.imagePath.startsWith('http')
                          ? Image.network(
                              widget.product.imagePath,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.phone_android,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              widget.product.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.phone_android,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        onPressed: isLoading ? null : _toggleWishlist,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                              ),
                        iconSize: 18,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: isInWishlist ? Colors.red : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Product Name
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 2),
              
              // Product Model
              Text(
                widget.product.model,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Price
              Text(
                'Rp ${widget.product.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Buy Button - Full Width
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onBuyNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
