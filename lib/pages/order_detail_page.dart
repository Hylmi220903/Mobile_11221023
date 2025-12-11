import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late AppDatabase _database;
  OrderWithDetails? _orderDetails;
  bool _isLoading = true;
  String? _buyerPhone;
  String? _buyerEmail;
  AddressesData? _buyerAddress;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await AppDatabase.getInstance();
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
    await _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final order = await _database.orderDao.getOrderById(widget.orderId);
      
      if (order != null) {
        // Get product details
        final product = await _database.productDao.getProductById(order.productId);
        
        // Get store details
        final store = await _database.storeDao.getStoreById(product!.storeId);
        
        // Get buyer details
        final buyer = await _database.userDao.getUserById(order.buyerId);
        
        // Get buyer's main address
        final buyerAddress = await _database.addressDao.getMainAddress(order.buyerId);
        
        if (mounted) {
          setState(() {
            _orderDetails = OrderWithDetails(
              order: order,
              product: product,
              storeName: store!.storeName,
              buyerName: buyer!.fullName,
            );
            _buyerPhone = buyer.phoneNumber;
            _buyerEmail = buyer.email;
            _buyerAddress = buyerAddress;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading order details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(double price) {
    return 'Rp${price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'payment':
        return 'Menunggu Pembayaran';
      case 'packing':
        return 'Sedang Dikemas';
      case 'delivery':
        return 'Dalam Pengiriman';
      case 'finished':
        return 'Selesai';
      case 'cancelled':
        return 'Pembayaran Dibatalkan';
      default:
        return status;
    }
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'payment':
        return Icons.payment;
      case 'packing':
        return Icons.inventory_2_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'finished':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetails == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Pesanan tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data pesanan tidak dapat dimuat',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final order = _orderDetails!.order;
    final product = _orderDetails!.product;
    final storeName = _orderDetails!.storeName;
    final buyerName = _orderDetails!.buyerName;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Status Section
          _buildStatusSection(order.status),

          const SizedBox(height: 8),

          // Product Information
          _buildSectionCard(
            title: 'Informasi Produk',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: product.imagePath.isNotEmpty
                            ? Image.network(
                                product.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.model,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kategori: ${product.category}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Jumlah', 'x${order.quantity}'),
                const SizedBox(height: 8),
                _buildInfoRow('Harga Satuan', _formatPrice(order.priceAtPurchase)),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Total Harga',
                  _formatPrice(order.priceAtPurchase * order.quantity),
                  isBold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Store Information
          _buildSectionCard(
            title: 'Informasi Toko',
            child: Column(
              children: [
                _buildInfoRow('Nama Toko', storeName, icon: Icons.store),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Buyer Information
          _buildSectionCard(
            title: 'Informasi Pembeli',
            child: Column(
              children: [
                _buildInfoRow('Nama', buyerName, icon: Icons.person),
                if (_buyerPhone != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('No. Telepon', _buyerPhone!, icon: Icons.phone),
                ],
                if (_buyerEmail != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Email', _buyerEmail!, icon: Icons.email),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Buyer Address
          if (_buyerAddress != null)
            _buildSectionCard(
              title: 'Alamat Pembeli',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _buyerAddress!.recipientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _buyerAddress!.phoneNumber,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_buyerAddress!.streetAddress}${_buyerAddress!.detailAddress != null ? ', ${_buyerAddress!.detailAddress}' : ''}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_buyerAddress!.district}, ${_buyerAddress!.city}, ${_buyerAddress!.province} ${_buyerAddress!.postalCode}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (_buyerAddress != null) const SizedBox(height: 8),

          // Shipping Information
          _buildSectionCard(
            title: 'Informasi Pengiriman',
            child: Column(
              children: [
                _buildInfoRow(
                  'Tipe Pengiriman',
                  order.shippingType,
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Payment Information
          _buildSectionCard(
            title: 'Informasi Pembayaran',
            child: Column(
              children: [
                _buildInfoRow(
                  'Metode Pembayaran',
                  'Transfer Bank', // Default, bisa disesuaikan
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Status Pembayaran',
                  order.paidAt != null ? 'Sudah Dibayar' : 'Belum Dibayar',
                  valueColor: order.paidAt != null ? Colors.green : Colors.orange,
                ),
                if (order.status == 'payment' && order.paymentDeadline != null) ...[
                  const SizedBox(height: 8),
                  _buildPaymentDeadline(order.paymentDeadline!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Order Timeline
          _buildSectionCard(
            title: 'Riwayat Pesanan',
            child: _buildTimeline(order),
          ),

          const SizedBox(height: 16),

          // Payment Button for unpaid orders (only show for buyer)
          if (order.status == 'payment' && 
              order.paymentDeadline != null && 
              _currentUserId != null && 
              _currentUserId == order.buyerId) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/payment', extra: {
                      'orderId': order.id,
                      'amount': order.priceAtPurchase * order.quantity,
                      'orderCode': 'ORD-${order.id}',
                      'productName': '${product.name} ${product.model}',
                      'quantity': order.quantity,
                      'qrContent': 'ORDER_${order.id}_${buyerName}_${order.priceAtPurchase * order.quantity}',
                      'expiresAt': order.paymentDeadline!,
                    });
                  },
                  icon: const Icon(Icons.qr_code, size: 24),
                  label: const Text(
                    'Bayar Sekarang dengan QR Code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0067b3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 32,
              color: _getStatusColor(status),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDeadline(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExpired 
            ? Colors.red.withValues(alpha: 0.1)
            : const Color(0xFF0067b3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: isExpired ? Colors.red : const Color(0xFF0067b3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isExpired
                  ? 'Batas waktu pembayaran telah habis'
                  : 'Selesaikan pembayaran dalam ${remaining.inMinutes} menit',
              style: TextStyle(
                fontSize: 13,
                color: isExpired ? Colors.red : const Color(0xFF0067b3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final timeline = <Map<String, dynamic>>[
      {
        'title': 'Pesanan Dibuat',
        'date': order.orderedAt,
        'completed': true,
      },
      if (order.status == 'cancelled')
        {
          'title': 'Pembayaran Dibatalkan',
          'date': order.orderedAt,
          'completed': true,
          'isCancelled': true,
        }
      else ...[
        if (order.paidAt != null)
          {
            'title': 'Pembayaran Dikonfirmasi',
            'date': order.paidAt,
            'completed': true,
          },
        if (order.status == 'packing' || order.status == 'delivery' || order.status == 'finished')
          {
            'title': 'Pesanan Sedang Dikemas',
            'date': order.paidAt,
            'completed': true,
          },
        if (order.deliveredAt != null)
          {
            'title': 'Pesanan Dikirim',
            'date': order.deliveredAt,
            'completed': true,
          },
        if (order.finishedAt != null)
          {
            'title': 'Pesanan Selesai',
            'date': order.finishedAt,
            'completed': true,
          },
      ],
    ];

    return Column(
      children: List.generate(timeline.length, (index) {
        final item = timeline[index];
        final isLast = index == timeline.length - 1;
        final isCancelled = item['isCancelled'] == true;
        final statusColor = isCancelled ? Colors.red : Colors.green;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: item['completed'] 
                        ? statusColor
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: item['completed']
                      ? Icon(
                          isCancelled ? Icons.close : Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: item['completed']
                        ? statusColor
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item['completed']
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (item['date'] != null)
                    Text(
                      _formatDateTime(item['date']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (!isLast) const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
