import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../database/database.dart';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final double amount;
  final String orderCode;
  final String productName;
  final int quantity;
  final String qrContent;
  final DateTime expiresAt;

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.orderCode,
    required this.productName,
    required this.quantity,
    required this.qrContent,
    required this.expiresAt,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Duration _remaining;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = widget.expiresAt.difference(DateTime.now());
      if (newRemaining.isNegative || newRemaining.inSeconds == 0) {
        timer.cancel();
      }
      setState(() {
        _remaining = newRemaining.isNegative ? Duration.zero : newRemaining;
      });
    });
  }

  bool get _isExpired => _remaining.inSeconds <= 0;

  String _formatPrice(double price) {
    return 'Rp${price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleVerify() async {
    if (_isExpired) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu pembayaran sudah habis. Buat pesanan baru.'),
          ),
        );
      }
      return;
    }

    setState(() => _isVerifying = true);
    
    try {
      // Update order status to packing
      final database = await AppDatabase.getInstance();
      await database.orderDao.updateOrderStatus(widget.orderId, 'packing');
      
      await Future.delayed(const Duration(milliseconds: 900));
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil diverifikasi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to my orders
      context.goNamed('my_orders');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memverifikasi pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Scan to Pay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAmountCard(colorScheme),
              const SizedBox(height: 16),
              _buildQrCard(colorScheme),
              const SizedBox(height: 16),
              _buildGuide(colorScheme),
              const SizedBox(height: 24),
              _buildVerifyButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(widget.amount),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isExpired
                      ? Colors.red.shade50
                      : colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _isExpired ? Colors.red : colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isExpired
                          ? 'Expired'
                          : '${_formatRemaining(_remaining)} left',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isExpired ? Colors.red : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPill(colorScheme, 'Order', widget.orderCode),
              const SizedBox(width: 8),
              _buildPill(
                colorScheme,
                'Item',
                '${widget.productName} x${widget.quantity}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(ColorScheme colorScheme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QRIS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'Generasi otomatis',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: widget.qrContent,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isExpired
                ? 'QR kadaluarsa. Silakan buat pesanan baru.'
                : 'Tunjukkan atau simpan QR ini untuk membayar via QRIS dalam 30 menit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide(ColorScheme colorScheme) {
    final steps = [
      {
        'title': 'Simpan atau tampilkan QR',
        'desc': 'Biarkan kasir memindai atau unggah dari galeri e-wallet.',
        'icon': Icons.qr_code_2_outlined,
      },
      {
        'title': 'Buka e-wallet / m-banking',
        'desc': 'Pilih menu bayar dengan QRIS dan pindai kode.',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'Konfirmasi & bayar',
        'desc': 'Pastikan nominal sesuai lalu selesaikan pembayaran.',
        'icon': Icons.check_circle_outline,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara bayar via QRIS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(ColorScheme colorScheme) {
    return FilledButton(
      onPressed: _isVerifying ? null : _handleVerify,
      style: FilledButton.styleFrom(
        backgroundColor: _isExpired ? Colors.grey : colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isVerifying
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Verifikasi Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }
}
