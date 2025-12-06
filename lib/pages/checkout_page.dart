import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class CheckoutPage extends StatefulWidget {
  final Product product;
  final int quantity;
  final Store? store;

  const CheckoutPage({
    super.key,
    required this.product,
    required this.quantity,
    this.store,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late AppDatabase _database;
  Product? _product;
  Store? _store;
  AddressesData? _selectedAddress;
  List<AddressesData> _addresses = [];
  bool _isLoading = true;
  int? _userId;

  final _messageController = TextEditingController();

  // Delivery options
  String _selectedDelivery = 'reguler';
  final Map<String, Map<String, dynamic>> _deliveryOptions = {
    'reguler': {
      'name': 'Reguler',
      'price': 20000,
      'estimate': 'Garansi tiba 2-3 hari',
    },
    'cargo': {
      'name': 'Cargo',
      'price': 7000,
      'estimate': 'Garansi tiba 7-10 hari',
    },
    'instant': {
      'name': 'Instant',
      'price': 35000,
      'estimate': 'Garansi tiba 1 hari',
    },
  };

  // Payment method
  String _selectedPayment = 'qris';

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    _database = await AppDatabase.getInstance();

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    if (_userId != null) {
      await _loadData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    // Use product and store from widget
    setState(() {
      _product = widget.product;
      _store = widget.store;
    });

    // Load addresses
    final addresses = await _database.addressDao.getAddressesByUser(_userId!);
    setState(() {
      _addresses = addresses;
      // Select main address by default, or first address
      if (addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (a) => a.isMainAddress,
          orElse: () => addresses.first,
        );
      }
    });
  }

  String _formatPrice(double price) {
    return 'Rp${price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  double get _productTotal => (_product?.price ?? 0) * widget.quantity;
  double get _deliveryFee => (_deliveryOptions[_selectedDelivery]?['price'] ?? 0).toDouble();
  double get _grandTotal => _productTotal + _deliveryFee;

  String _buildFullAddress(AddressesData address) {
    final parts = <String>[];
    parts.add(address.streetAddress);
    if (address.detailAddress != null && address.detailAddress!.isNotEmpty) {
      parts.add(address.detailAddress!);
    }
    parts.add('${address.district}, ${address.city}');
    parts.add('${address.province} ${address.postalCode}');
    return parts.join(', ');
  }

  Future<void> _selectAddress() async {
    final result = await showModalBottomSheet<AddressesData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressSelectionSheet(
        addresses: _addresses,
        selectedAddress: _selectedAddress,
        onAddNew: () async {
          Navigator.pop(context);
          final added = await context.push('/add-address');
          if (added == true) {
            await _loadData();
          }
        },
      ),
    );

    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  void _handleCheckout() {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih alamat pengiriman'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implement order creation and payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan berhasil dibuat! Total: ${_formatPrice(_grandTotal)}'),
        backgroundColor: Colors.green,
      ),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Address Section
                  _buildAddressSection(colorScheme),

                  const SizedBox(height: 8),

                  // Store & Product Section
                  _buildProductSection(colorScheme),

                  const SizedBox(height: 8),

                  // Message for Seller
                  _buildMessageSection(colorScheme),

                  const SizedBox(height: 8),

                  // Delivery Options
                  _buildDeliverySection(colorScheme),

                  const SizedBox(height: 8),

                  // Payment Methods
                  _buildPaymentSection(colorScheme),

                  const SizedBox(height: 8),

                  // Order Summary
                  _buildOrderSummary(colorScheme),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Checkout Bar
          _buildBottomBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: _selectAddress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectedAddress != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedAddress!.recipientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(+62) ${_selectedAddress!.phoneNumber.replaceFirst(RegExp(r'^0'), '')}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildFullAddress(_selectedAddress!),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tambah Alamat Pengiriman',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Klik untuk menambahkan alamat',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _store?.storeName ?? 'Unknown Store',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Product Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: _product!.imagePath.startsWith('http')
                      ? Image.network(
                          _product!.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.phone_android,
                          size: 32,
                          color: Colors.grey,
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.name,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_product!.model.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _product!.model,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(_product!.price),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'x${widget.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Pesan untuk Penjual',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _messageController,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: 'Tinggalkan pesan',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Opsi Pengiriman',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delivery Options
          ..._deliveryOptions.entries.map((entry) {
            final key = entry.key;
            final option = entry.value;
            final isSelected = _selectedDelivery == key;

            return InkWell(
              onTap: () => setState(() => _selectedDelivery = key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null,
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: key,
                      groupValue: _selectedDelivery,
                      onChanged: (value) => setState(() => _selectedDelivery = value!),
                      activeColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                option['estimate'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatPrice(option['price'].toDouble()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(ColorScheme colorScheme) {
    final paymentMethods = [
      {'key': 'qris', 'name': 'QRIS', 'available': true},
      {'key': 'bank', 'name': 'Bank Transfer', 'available': false},
      {'key': 'gopay', 'name': 'Gopay', 'available': false},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 12),

          ...paymentMethods.map((method) {
            final isAvailable = method['available'] as bool;
            final isSelected = _selectedPayment == method['key'];

            return InkWell(
              onTap: isAvailable
                  ? () => setState(() => _selectedPayment = method['key'] as String)
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : isAvailable
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.05)
                      : !isAvailable
                          ? Colors.grey.shade100
                          : null,
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: method['key'] as String,
                      groupValue: _selectedPayment,
                      onChanged: isAvailable
                          ? (value) => setState(() => _selectedPayment = value!)
                          : null,
                      activeColor: colorScheme.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      method['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isAvailable ? null : Colors.grey.shade400,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ColorScheme colorScheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 12),

          _buildSummaryRow(
            'Total Produk (${widget.quantity} item)',
            _formatPrice(_productTotal),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Biaya Pengiriman',
            _formatPrice(_deliveryFee),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),

          _buildSummaryRow(
            'Total Pembayaran',
            _formatPrice(_grandTotal),
            isBold: true,
            priceColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? priceColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: priceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _formatPrice(_grandTotal),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _handleCheckout,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Buat Pesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Address Selection Bottom Sheet
class _AddressSelectionSheet extends StatelessWidget {
  final List<AddressesData> addresses;
  final AddressesData? selectedAddress;
  final VoidCallback onAddNew;

  const _AddressSelectionSheet({
    required this.addresses,
    required this.selectedAddress,
    required this.onAddNew,
  });

  String _buildFullAddress(AddressesData address) {
    final parts = <String>[];
    parts.add(address.streetAddress);
    if (address.detailAddress != null && address.detailAddress!.isNotEmpty) {
      parts.add(address.detailAddress!);
    }
    parts.add('${address.district}, ${address.city}');
    parts.add('${address.province} ${address.postalCode}');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Pilih Alamat Pengiriman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Address List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isSelected = selectedAddress?.id == address.id;

                return InkWell(
                  onTap: () => Navigator.pop(context, address),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : null,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<int>(
                          value: address.id,
                          groupValue: selectedAddress?.id,
                          onChanged: (_) => Navigator.pop(context, address),
                          activeColor: colorScheme.primary,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    address.recipientName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (address.isMainAddress) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: colorScheme.primary),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Utama',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.phoneNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _buildFullAddress(address),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add New Address Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alamat Baru'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
