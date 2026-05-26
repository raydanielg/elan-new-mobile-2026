import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_service.dart';
import '../api/api_response.dart';

class UpdateProductPage extends StatefulWidget {
  const UpdateProductPage({
    super.key,
    required this.product,
    this.userId,
    this.shopId,
  });

  final Map<String, dynamic> product;
  final String? userId;
  final String? shopId;

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _wholesaleCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _reorderLevelCtrl;
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _descriptionCtrl;

  late String _type;
  String? _selectedCategoryId;
  late String _isTaxable;
  DateTime? _expiryDate;

  List<dynamic> _categories = [];
  final List<XFile> _newImages = [];
  List<String> _existingPhotos = [];

  bool _submitting = false;
  bool _loading = true;

  String? _userId;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _shopId = widget.shopId;
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p['product_name']?.toString() ?? p['name']?.toString() ?? '');
    _skuCtrl = TextEditingController(text: p['sku']?.toString() ?? p['barcode']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: p['selling_price']?.toString() ?? p['price']?.toString() ?? '');
    _costCtrl = TextEditingController(text: p['buying_price']?.toString() ?? p['bp']?.toString() ?? '');
    _stockCtrl = TextEditingController(text: p['qty']?.toString() ?? p['quantity']?.toString() ?? '');
    _wholesaleCtrl = TextEditingController(text: p['wholesale_price']?.toString() ?? p['wp']?.toString() ?? '');
    _discountCtrl = TextEditingController(text: p['discount']?.toString() ?? '');
    _reorderLevelCtrl = TextEditingController(text: p['reorder_level']?.toString() ?? p['reorder-level']?.toString() ?? '');
    _sizeCtrl = TextEditingController(text: p['size']?.toString() ?? '');
    _colorCtrl = TextEditingController(text: p['color']?.toString() ?? '');
    _descriptionCtrl = TextEditingController(text: p['description']?.toString() ?? '');

    _type = p['type']?.toString() ?? 'product';
    _selectedCategoryId = p['category_id']?.toString() ?? p['category']?.toString();
    _isTaxable = p['is_taxable']?.toString() ?? '0';
    
    if (p['expiry_date'] != null) {
      _expiryDate = DateTime.tryParse(p['expiry_date'].toString());
    }
    
    if (p['photos'] is List) {
      _existingPhotos = (p['photos'] as List).map((e) => e.toString()).toList();
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchContext(),
      _fetchCategories(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _fetchCategories() async {
    try {
      final raw = await ApiService.instance.app.getData('stock_category');
      List<dynamic> cats = [];
      if (raw is List) {
        cats = raw;
      } else if (raw is Map && raw['data'] is List) {
        cats = raw['data'] as List;
      }

      setState(() {
        _categories = cats;
        // Auto-select first category if none selected
        if (_selectedCategoryId == null && cats.isNotEmpty) {
          final firstId = cats.first['id']?.toString() ??
              cats.first['category_id']?.toString();
          if (firstId != null && firstId.isNotEmpty) {
            _selectedCategoryId = firstId;
          }
        }
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ERROR] Failed to fetch categories:');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _fetchCategories,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchContext() async {
    try {
      final sessionUserRaw = await ApiService.instance.app.getData('session_user');
      final sessionShopRaw = await ApiService.instance.app.getData('session_shop');
      if (!mounted) return;

      String? userId;
      String? shopId;

      if (sessionUserRaw is Map) {
        final data = (sessionUserRaw['data'] is Map)
            ? (sessionUserRaw['data'] as Map)
            : sessionUserRaw;
        userId = data['user_id']?.toString() ?? data['id']?.toString();
        userId = userId?.trim();
        if (userId != null && userId.isEmpty) userId = null;
      }

      if (sessionShopRaw is Map) {
        final data = (sessionShopRaw['data'] is Map)
            ? (sessionShopRaw['data'] as Map)
            : sessionShopRaw;
        shopId = data['shop_id']?.toString() ??
            data['id']?.toString() ??
            data['session_shop_id']?.toString();
        shopId = shopId?.trim();
        if (shopId != null && shopId.isEmpty) shopId = null;
      }

      setState(() {
        _userId ??= userId;
        _shopId ??= shopId;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ERROR] Failed to fetch context:');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }
      // ignore - user can still use the app
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() => _newImages.addAll(picked));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ERROR] Failed to pick images:');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _newImages.add(photo));
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[ERROR] Failed to take picture:');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotos.removeAt(index));
  }

  num? _parseNum(String s) {
    final v = s.trim();
    if (v.isEmpty) return null;
    return num.tryParse(v.replaceAll(',', ''));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    // Backend required fields: product_name, category_id, type
    final List<String> missingFields = [];

    if (_nameCtrl.text.trim().isEmpty) {
      missingFields.add('Product Name');
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      missingFields.add('Category');
    }

    if (_type.isEmpty) {
      missingFields.add('Type');
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill required fields: ${missingFields.join(', ')}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    // Declare variables here so they're accessible in catch block
    late final String productId;
    late final Map<String, String> fields;
    late final ApiResponse<Map<String, dynamic>> resp;

    try {
      productId = widget.product['product_id']?.toString() ??
          widget.product['id']?.toString() ??
          widget.product['stock_id']?.toString() ??
          '';

      fields = {
        'type': _type,
        'category_id': _selectedCategoryId ?? '',
        'product_name': _nameCtrl.text.trim(),
        'barcode': _skuCtrl.text.trim(),
        'quantity': _parseNum(_stockCtrl.text)?.toString() ?? '0',
        'bp': _parseNum(_costCtrl.text)?.toString() ?? '0',
        'sp': _parseNum(_priceCtrl.text)?.toString() ?? '0',
        'wholesale_price': _parseNum(_wholesaleCtrl.text)?.toString() ?? '0',
        'wp': _parseNum(_wholesaleCtrl.text)?.toString() ?? '0',
        'discount': _discountCtrl.text.trim(),
        'reorder_level': _parseNum(_reorderLevelCtrl.text)?.toString() ?? '0',
        'is_taxable': _isTaxable,
        'expiry_date': _expiryDate?.toIso8601String().split('T').first ?? '',
        'size': _sizeCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
      };

      // Backend gets shop_id and created_by from SESSION, not POST data

      // Use appropriate method based on whether we have images
      final hasImages = _newImages.isNotEmpty;

      try {
        if (hasImages) {
          // Use multipart when there are images
          resp = await ApiService.instance.app.updateProduct(
            productId: productId,
            fields: fields,
            images: _newImages.map((img) => File(img.path)).toList(),
          );
        } else {
          // Use regular JSON post when no images (more reliable)
          resp = await ApiService.instance.app.postData(
            'stock/products/update',
            body: {...fields, 'product_id': productId},
          );
        }
      } catch (e, stackTrace) {
        // If multipart fails (e.g., server error), try without images
        if (kDebugMode) {
          print('[FALLBACK] Multipart upload failed:');
          print('Error: $e');
          print('StackTrace: $stackTrace');
        }
        try {
          resp = await ApiService.instance.app.postData(
            'stock/products/update',
            body: {...fields, 'product_id': productId},
          );
          // Show warning that images weren't uploaded
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${resp.message ?? "Product updated"} (without images - server error)'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (fallbackError, fallbackStackTrace) {
          // Both attempts failed
          if (kDebugMode) {
            print('[FALLBACK] JSON endpoint also failed:');
            print('Error: $fallbackError');
            print('StackTrace: $fallbackStackTrace');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update product: ${fallbackError.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          setState(() => _submitting = false);
          return;
        }
      }

      if (!mounted) return;

      if (resp.status == true) {
        Navigator.of(context).pop(true);
        // Only show success if not already shown by fallback
        if (!hasImages || _newImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp.message ?? 'Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(resp.message ?? 'Update failed');
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      if (kDebugMode) {
        print('[ERROR] Product update failed:');
        print('Error: $e');
        print('StackTrace: $stackTrace');
      }

      // Extract user-friendly message from error
      String errorMsg = 'Failed to update product. Please try again.';
      if (e is Exception) {
        final errorStr = e.toString();
        if (errorStr.contains('HTML instead of JSON')) {
          errorMsg = 'Server error: Please check your connection or try again later.';
        } else if (errorStr.contains('Server returned empty')) {
          errorMsg = 'Server returned no response. Please try again.';
        } else if (errorStr.contains('Failed to connect')) {
          errorMsg = 'Network error: Please check your internet connection.';
        } else if (errorStr.contains('timeout')) {
          errorMsg = 'Request timed out. Please try again.';
        } else {
          // Try to extract message from ApiException
          final match = RegExp(r'message: (.+?)(?:,|$)').firstMatch(errorStr);
          if (match != null) {
            errorMsg = match.group(1)?.trim() ?? errorMsg;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Product'),
        actions: [
          if (_submitting)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SvgPicture.asset(
                'assets/onboarding/Spinner@1x-3.0s-136px-136px.svg',
                width: 24,
                height: 24,
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: SvgPicture.asset(
                'assets/onboarding/Spinner@1x-3.0s-136px-136px.svg',
                width: 60,
                height: 60,
              ),
            )
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 12),
                      _buildInventorySection(),
                      const SizedBox(height: 12),
                      _buildAdditionalSection(),
                      const SizedBox(height: 12),
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'Updating…' : 'Update Product',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return _Card(
      title: 'General Information',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Type',
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'product', child: Text('Product')),
                    DropdownMenuItem(value: 'service', child: Text('Service')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Category',
                  value: _selectedCategoryId,
                  items: _categories.map((c) {
                    final id = c['id']?.toString() ?? c['category_id']?.toString();
                    final name = c['name']?.toString() ?? c['category_name']?.toString() ?? 'General';
                    return DropdownMenuItem(value: id, child: Text(name));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  hint: 'Select category',
                  isLoading: _loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameCtrl,
            label: 'Item Name',
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _skuCtrl,
            label: 'Barcode / SKU',
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection() {
    return _Card(
      title: 'Pricing & Inventory',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _stockCtrl,
                  label: 'Qty',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _reorderLevelCtrl,
                  label: 'Reorder Level',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _costCtrl,
                  label: 'Buying Price',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _priceCtrl,
                  label: 'Selling Price',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _wholesaleCtrl,
                  label: 'Wholesale Price',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _discountCtrl,
                  label: 'Discount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Taxable (VAT)',
            value: _isTaxable,
            items: const [
              DropdownMenuItem(value: '0', child: Text('No')),
              DropdownMenuItem(value: '1', child: Text('Yes')),
            ],
            onChanged: (v) => setState(() => _isTaxable = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return _Card(
      title: 'Additional Details',
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) setState(() => _expiryDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              child: Text(_expiryDate == null ? 'Select Date' : _expiryDate!.toIso8601String().split('T').first),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _sizeCtrl,
                  label: 'Size',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _colorCtrl,
                  label: 'Color',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionCtrl,
            label: 'Description',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _Card(
      title: 'Product Photos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Existing and new photos',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_existingPhotos.isNotEmpty || _newImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing photos from server
                  ..._existingPhotos.asMap().entries.map((entry) {
                    return _buildPhotoThumbnail(
                      image: NetworkImage(entry.value),
                      onRemove: () => _removeExistingPhoto(entry.key),
                    );
                  }),
                  // New images picked locally
                  ..._newImages.asMap().entries.map((entry) {
                    return _buildPhotoThumbnail(
                      image: FileImage(File(entry.value.path)),
                      onRemove: () => _removeNewImage(entry.key),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail({required ImageProvider image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: image, fit: BoxFit.cover),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
        ),
        Positioned(
          right: 4,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
    String? hint,
    bool isLoading = false,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: items.any((item) => item.value == value) ? value : null,
      items: items.isEmpty
          ? [
              DropdownMenuItem(
                value: null,
                child: Text(
                  isLoading ? 'Loading...' : (hint ?? 'No options available'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ]
          : items,
      onChanged: items.isEmpty || isLoading ? null : onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: (val) {
        if (label == 'Category' && (val == null || val.toString().isEmpty)) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
