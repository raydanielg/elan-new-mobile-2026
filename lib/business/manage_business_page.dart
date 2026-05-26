import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/api_service.dart';
import '../api/auth_api.dart';

class ManageBusinessPage extends StatefulWidget {
  const ManageBusinessPage({super.key});

  @override
  State<ManageBusinessPage> createState() => _ManageBusinessPageState();
}

class _ManageBusinessPageState extends State<ManageBusinessPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessName = TextEditingController();

  bool _loading = false;

  bool _typesLoading = false;
  String? _typesError;
  List<String> _businessTypes = const [];
  String? _selectedBusinessType;

  bool _categoriesLoading = false;
  String? _categoriesError;
  List<BusinessCategory> _categories = const [];
  BusinessCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
    _loadBusinessCategories();
  }

  @override
  void dispose() {
    _businessName.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessTypes() async {
    setState(() {
      _typesLoading = true;
      _typesError = null;
    });

    try {
      // Try API first (best effort). Different backends may expose shop types
      // through shop_settings or other config endpoints.
      final raw = await ApiService.instance.app.getData('shop_settings');
      final out = <String>[];

      if (raw is Map) {
        final st = raw['shop_type'];
        if (st is List) {
          for (final x in st) {
            final v = x?.toString().trim() ?? '';
            if (v.isNotEmpty) out.add(v);
          }
        }
      }

      final types = out.isNotEmpty
          ? out
          : const [
              'Both Product and Services',
              'Products Only',
              'Services Only',
            ];

      if (!mounted) return;
      setState(() {
        _businessTypes = types;
        _selectedBusinessType ??= types.isEmpty ? null : types.first;
        _typesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typesLoading = false;
        _typesError = e.toString();
        _businessTypes = const [
          'Both Product and Services',
          'Products Only',
          'Services Only',
        ];
        _selectedBusinessType ??= _businessTypes.first;
      });
    }
  }

  Future<void> _loadBusinessCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final cats = await ApiService.instance.auth.businessCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategory ??= cats.isEmpty ? null : cats.first;
        _categoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final type = _selectedBusinessType;
    final category = _selectedCategory;

    if (type == null || type.trim().isEmpty) return;
    if (category == null) return;

    setState(() => _loading = true);
    try {
      final normalizedType = type.trim();
      await ApiService.instance.auth.addShop(
        body: {
          'shop_name': _businessName.text.trim(),
          'shop_type': normalizedType,
          'lob_id': category.id,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      String msg = e.toString();
      if (e is ApiException) {
        final details = e.details;
        if (details is Map) {
          final m = details['message']?.toString();
          if (m != null && m.trim().isNotEmpty) {
            msg = m;
          }

          if (msg.startsWith('ApiException') && msg.contains('Invalid response')) {
            final body = details['body']?.toString();
            if (body != null && body.trim().isNotEmpty) {
              final cleaned = body.replaceAll(RegExp(r'\s+'), ' ').trim();
              msg = cleaned.length > 160 ? cleaned.substring(0, 160) : cleaned;
            }
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Manage Business'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a new business',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill business info below then save.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _businessName,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Business name',
                          prefixIcon: Icon(Icons.storefront_outlined),
                          filled: true,
                          fillColor: Color(0xFFF9FAFB),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Business type',
                          prefixIcon: const Icon(Icons.category_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedBusinessType,
                                  hint: const Text('Select business type'),
                                  items: _businessTypes
                                      .map(
                                        (t) => DropdownMenuItem<String>(
                                          value: t,
                                          child: Text(
                                            t,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (_loading || _typesLoading)
                                      ? null
                                      : (v) => setState(() => _selectedBusinessType = v),
                                ),
                              ),
                            ),
                            if (_typesLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_typesError != null)
                              IconButton(
                                onPressed: _loadBusinessTypes,
                                tooltip: 'Retry types',
                                icon: const Icon(Icons.refresh),
                              ),
                          ],
                        ),
                      ),
                      if (_typesError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _typesError!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFB91C1C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Business category',
                          prefixIcon: const Icon(Icons.work_outline),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<BusinessCategory>(
                                  isExpanded: true,
                                  value: _selectedCategory,
                                  hint: const Text('Select business category'),
                                  items: _categories
                                      .map(
                                        (c) => DropdownMenuItem<BusinessCategory>(
                                          value: c,
                                          child: Text(
                                            c.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (_loading || _categoriesLoading)
                                      ? null
                                      : (v) => setState(() => _selectedCategory = v),
                                ),
                              ),
                            ),
                            if (_categoriesLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_categoriesError != null)
                              IconButton(
                                onPressed: _loadBusinessCategories,
                                tooltip: 'Retry categories',
                                icon: const Icon(Icons.refresh),
                              ),
                          ],
                        ),
                      ),
                      if (_categoriesError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _categoriesError!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFB91C1C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save business',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
