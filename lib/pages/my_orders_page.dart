import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../widgets/main_layout.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  int? _currentUserId;
  bool _isLoading = true;
  late AppDatabase _database;
  List<OrderWithDetails> _allBuyerOrders = [];
  List<OrderWithDetails> _allSellerOrders = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await AppDatabase.getInstance();
    await _checkAuth();
  } 

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null && mounted) {
      setState(() {
        _currentUserId = userId;
      });
      await _loadOrders();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    if (_currentUserId == null) return;
    
    try {
      // Check and cancel expired payment orders
      await _cancelExpiredOrders();
      
      final buyerOrders = await _database.orderDao.getBuyerOrders(_currentUserId!);
      final sellerOrders = await _database.orderDao.getSellerOrders(_currentUserId!);
      
      if (mounted) {
        setState(() {
          _allBuyerOrders = buyerOrders;
          _allSellerOrders = sellerOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelExpiredOrders() async {
    try {
      final expiredOrders = await _database.orderDao.getExpiredPaymentOrders();
      
      for (var order in expiredOrders) {
        await _database.orderDao.updateOrderStatus(order.id, 'cancelled');
      }
      
      if (expiredOrders.isNotEmpty) {
        print('Cancelled ${expiredOrders.length} expired orders');
      }
    } catch (e) {
      print('Error cancelling expired orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _currentUserId == null
                ? _buildLoginPrompt()
                : DefaultTabController(
                    length: 6,
                    child: Column(
                      children: [
                        _buildTabBar(context),
                        const Divider(height: 1),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildMyProductTab(),
                              _buildOrderList('payment'),
                              _buildOrderList('packing'),
                              _buildOrderList('delivery'),
                              _buildOrderList('finished'),
                              _buildOrderList('cancelled'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Please Login First',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You need to login to view your orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067b3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TabBar(
      isScrollable: true,
      labelColor: colorScheme.primary,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorColor: colorScheme.primary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      tabs: const [
        Tab(text: 'My Product'),
        Tab(text: 'Payment'),
        Tab(text: 'Packing'),
        Tab(text: 'Delivery'),
        Tab(text: 'Finished'),
        Tab(text: 'Cancelled'),
      ],
    );
  }

  Widget _buildMyProductTab() {
    final onPayment = _allSellerOrders.where((o) => o.order.status == 'payment').toList();
    final needDeliver = _allSellerOrders.where((o) => o.order.status == 'packing').toList();
    final done = _allSellerOrders.where((o) => o.order.status == 'finished').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDropdownSection('On Payment', onPayment, Icons.payment),
          const SizedBox(height: 8),
          _buildDropdownSection('Need to deliver', needDeliver, Icons.local_shipping_outlined),
          const SizedBox(height: 8),
          _buildDropdownSection('Done Order', done, Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(String title, List<OrderWithDetails> orders, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF0067b3)),
          title: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0067b3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${orders.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0067b3),
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Belum ada pesanan di status ini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: orders.map((order) => _OrderCard(
                        orderDetails: order,
                        isSellerView: true,
                      )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _allBuyerOrders.where((o) => o.order.status == status).toList();
    
    return filtered.isEmpty
        ? _buildEmptyState('Belum ada pesanan')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _OrderCard(
                orderDetails: filtered[index],
                isSellerView: false,
              );
            },
          );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderWithDetails orderDetails;
  final bool isSellerView;

  const _OrderCard({
    required this.orderDetails,
    required this.isSellerView,
  });

  String _formatPrice(double price) {
    return 'Rp${price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final order = orderDetails.order;
    final product = orderDetails.product;
    final storeName = orderDetails.storeName;

    return InkWell(
      onTap: () => context.push('/order-history/${order.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _StatusChip(
                status: order.status,
                isSellerView: isSellerView,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Product info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: product.imagePath.isNotEmpty
                      ? Image.network(
                          product.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.name} ${product.model}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'x${order.quantity}  •  ${_formatPrice(order.priceAtPurchase)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: _getStatusColor(order.status),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.shippingType,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Payment timer and button for payment status (only for buyer)
          if (order.status == 'payment' && 
              order.paymentDeadline != null && 
              !isSellerView) ...[
            const SizedBox(height: 10),
            _PaymentTimer(expiresAt: order.paymentDeadline!),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to payment page with QR code
                  context.push('/cart/payment', extra: {
                    'orderId': order.id,
                    'amount': order.priceAtPurchase * order.quantity,
                    'orderCode': 'ORD-${order.id}',
                    'productName': '${product.name} ${product.model}',
                    'quantity': order.quantity,
                    'qrContent': 'ORDER_${order.id}_${order.buyerId}_${order.priceAtPurchase * order.quantity}',
                    'expiresAt': order.paymentDeadline!,
                  });
                },
                icon: const Icon(Icons.qr_code, size: 20),
                label: const Text('Bayar Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0067b3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'payment':
        return const Color(0xFF0067b3);
      case 'packing':
        return Colors.orange;
      case 'delivery':
        return Colors.blue;
      case 'finished':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _PaymentTimer extends StatefulWidget {
  final DateTime expiresAt;

  const _PaymentTimer({required this.expiresAt});

  @override
  State<_PaymentTimer> createState() => _PaymentTimerState();
}

class _PaymentTimerState extends State<_PaymentTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = widget.expiresAt.difference(DateTime.now());
    if (left.isNegative) {
      _timer?.cancel();
    }
    setState(() {
      _remaining = left.isNegative ? Duration.zero : left;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.inSeconds <= 0;
    final colorScheme = Theme.of(context).colorScheme;
    final minutes = (_remaining.inSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: isExpired ? Colors.red : colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          isExpired ? 'Waktu habis' : '$minutes:$seconds sebelum kadaluarsa',
          style: TextStyle(
            color: isExpired ? Colors.red : colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isSellerView;

  const _StatusChip({
    required this.status,
    required this.isSellerView,
  });

  String _getLabel() {
    if (isSellerView) {
      switch (status) {
        case 'payment':
          return 'On Payment';
        case 'packing':
          return 'Need to deliver';
        case 'finished':
          return 'Done Order';
        case 'cancelled':
          return 'Cancelled';
        default:
          return status;
      }
    } else {
      switch (status) {
        case 'payment':
          return 'Waiting Payment';
        case 'packing':
          return 'Packing';
        case 'delivery':
          return 'On Delivery';
        case 'finished':
          return 'Finished';
        case 'cancelled':
          return 'Payment Cancelled';
        default:
          return status;
      }
    }
  }

  Color _getColor() {
    switch (status) {
      case 'payment':
        return const Color(0xFF0067b3);
      case 'packing':
        return Colors.orange;
      case 'delivery':
        return Colors.blue;
      case 'finished':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
