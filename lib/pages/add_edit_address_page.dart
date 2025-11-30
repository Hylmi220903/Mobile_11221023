import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class AddEditAddressPage extends StatefulWidget {
  final int? addressId;

  const AddEditAddressPage({super.key, this.addressId});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _detailAddressController = TextEditingController();

  bool _isMainAddress = false;
  bool _isStoreAddress = false;
  bool _isLoading = false;
  bool _isEditing = false;
  int? _userId;

  late AppDatabase _database;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.addressId != null;
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await AppDatabase.getInstance();
    await _loadUserData();
    if (_isEditing) {
      await _loadAddressData();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });

      // Auto-fill recipient name and phone from user data
      if (!_isEditing) {
        final user = await _database.userDao.getUserById(userId);
        if (user != null && mounted) {
          _recipientNameController.text = user.fullName;
          _phoneController.text = user.phoneNumber;
        }
      }
    }
  }

  Future<void> _loadAddressData() async {
    if (widget.addressId == null) return;

    final address = await _database.addressDao.getAddressById(widget.addressId!);
    
    if (address != null && mounted) {
      setState(() {
        _recipientNameController.text = address.recipientName;
        _phoneController.text = address.phoneNumber;
        _provinceController.text = address.province;
        _cityController.text = address.city;
        _districtController.text = address.district;
        _postalCodeController.text = address.postalCode;
        _streetAddressController.text = address.streetAddress;
        _detailAddressController.text = address.detailAddress ?? '';
        _isMainAddress = address.isMainAddress;
        _isStoreAddress = address.isStoreAddress;
      });
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _streetAddressController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _database.addressDao.updateAddress(
          addressId: widget.addressId!,
          userId: _userId!,
          recipientName: _recipientNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          streetAddress: _streetAddressController.text.trim(),
          detailAddress: _detailAddressController.text.trim().isEmpty
              ? null
              : _detailAddressController.text.trim(),
          isMainAddress: _isMainAddress,
          isStoreAddress: _isStoreAddress,
        );
      } else {
        await _database.addressDao.addAddress(
          userId: _userId!,
          recipientName: _recipientNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          province: _provinceController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          streetAddress: _streetAddressController.text.trim(),
          detailAddress: _detailAddressController.text.trim().isEmpty
              ? null
              : _detailAddressController.text.trim(),
          isMainAddress: _isMainAddress,
          isStoreAddress: _isStoreAddress,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Alamat berhasil diperbarui' : 'Alamat berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Form Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    const Text(
                      'Alamat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recipient Name
                    _buildTextField(
                      controller: _recipientNameController,
                      hint: 'Nama Lengkap',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama penerima tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Nomor Telepon',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        if (value.length < 10) {
                          return 'Nomor telepon minimal 10 digit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Province, City, District, Postal Code (Clickable style but text input)
                    _buildTextField(
                      controller: _provinceController,
                      hint: 'Provinsi',
                      suffixIcon: const Icon(Icons.chevron_right, color: Colors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Provinsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _cityController,
                      hint: 'Kota/Kabupaten',
                      suffixIcon: const Icon(Icons.chevron_right, color: Colors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kota tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _districtController,
                      hint: 'Kecamatan',
                      suffixIcon: const Icon(Icons.chevron_right, color: Colors.grey),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kecamatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _postalCodeController,
                      hint: 'Kode Pos',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kode pos tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Street Address
                    _buildTextField(
                      controller: _streetAddressController,
                      hint: 'Nama Jalan, Gedung, No. Rumah',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat jalan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Detail Address (optional)
                    _buildTextField(
                      controller: _detailAddressController,
                      hint: 'Detail Lainnya (Cth: Blok / Unit No., Patokan)',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Toggle Options
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  // Set as Main Address
                  SwitchListTile(
                    title: const Text(
                      'Atur sebagai Alamat Utama',
                      style: TextStyle(fontSize: 15),
                    ),
                    value: _isMainAddress,
                    onChanged: (value) {
                      setState(() {
                        _isMainAddress = value;
                      });
                    },
                    activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primary;
                      }
                      return null;
                    }),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  
                  Divider(height: 1, color: Colors.grey.shade200),
                  
                  // Set as Store Address
                  SwitchListTile(
                    title: const Text(
                      'Atur sebagai Alamat Toko',
                      style: TextStyle(fontSize: 15),
                    ),
                    value: _isStoreAddress,
                    onChanged: (value) {
                      setState(() {
                        _isStoreAddress = value;
                      });
                    },
                    activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primary;
                      }
                      return null;
                    }),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Simpan Perubahan' : 'Simpan Alamat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
