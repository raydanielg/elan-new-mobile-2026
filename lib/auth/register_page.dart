import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/api_service.dart';
import '../api/api_exception.dart';

class _Region {
  const _Region({required this.code, required this.name});

  final String code;
  final String name;
}

class _Country {
  const _Country({
    required this.name,
    required this.alpha2Code,
    required this.callingCode,
    required this.flagPngUrl,
  });

  final String name;
  final String alpha2Code;
  final String callingCode;
  final String flagPngUrl;

  String get callingCodeWithPlus => '+$callingCode';
}

class _FlagIcon extends StatelessWidget {
  const _FlagIcon({
    required this.pngUrl,
    required this.fallbackText,
  });

  final String pngUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (pngUrl.isEmpty) {
      return SizedBox(
        width: 18,
        height: 18,
        child: Center(
          child: Text(
            fallbackText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        pngUrl,
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              fallbackText,
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _region = TextEditingController();
  final _businessName = TextEditingController();
  final _password = TextEditingController();

  String _businessType = 'Both Product and Services';
  String _businessCategory = 'Select Business category';
  String? _selectedBusinessCategoryId;
  bool _agree = false;

  List<String> _businessCategoryNames = const ['Select Business category'];
  Map<String, String> _businessCategoryNameToId = const {};
  bool _businessCategoriesLoading = false;
  String? _businessCategoriesError;

  List<_Country> _countries = const [];
  _Country? _selectedCountry;
  bool _countriesLoading = false;
  String? _countriesError;

  List<_Region> _regions = const [];
  _Region? _selectedRegion;
  bool _regionsLoading = false;
  String? _regionsError;

  List<String> _regionNames = const ['Select Region'];
  Map<String, String> _regionNameToCode = const {};
  String _selectedRegionName = 'Select Region';

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
    _fetchRegions();
    _fetchBusinessCategories();
  }

  Future<void> _fetchBusinessCategories() async {
    setState(() {
      _businessCategoriesLoading = true;
      _businessCategoriesError = null;
    });

    try {
      final categories = await ApiService.instance.auth.businessCategories();
      if (!mounted) return;

      final items = <String>['Select Business category'];
      final nameToId = <String, String>{};
      for (final c in categories) {
        items.add(c.name);
        nameToId[c.name] = c.id.toString();
      }

      setState(() {
        _businessCategoryNames = items;
        _businessCategoryNameToId = nameToId;
        _businessCategoriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _businessCategoriesLoading = false;
        _businessCategoriesError = e.toString();
      });
    }
  }

  String _flagEmoji(String alpha2) {
    final code = alpha2.toUpperCase();
    if (code.length != 2) return '';
    final int first = code.codeUnitAt(0);
    final int second = code.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) return '';
    return String.fromCharCode(0x1F1E6 + (first - 65)) +
        String.fromCharCode(0x1F1E6 + (second - 65));
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _countriesLoading = true;
      _countriesError = null;
    });

    try {
      final res = await http.get(Uri.parse('https://www.apicountries.com/countries'));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Failed to load countries');
      }

      final raw = jsonDecode(res.body);
      if (raw is! List) {
        throw Exception('Invalid countries response');
      }

      final parsed = <_Country>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        final alpha2 = item['alpha2Code']?.toString() ?? '';

        String flagPngUrl = '';
        final flags = item['flags'];
        if (flags is Map) {
          flagPngUrl = flags['png']?.toString() ?? '';
        }

        final callingCodes = item['callingCodes'];
        String code = '';
        if (callingCodes is List && callingCodes.isNotEmpty) {
          code = callingCodes.first?.toString() ?? '';
        } else if (callingCodes != null) {
          code = callingCodes.toString();
        }

        if (name.isEmpty || alpha2.isEmpty || code.isEmpty) continue;
        parsed.add(
          _Country(
            name: name,
            alpha2Code: alpha2,
            callingCode: code,
            flagPngUrl: flagPngUrl,
          ),
        );
      }

      parsed.sort((a, b) => a.name.compareTo(b.name));

      _Country? defaultCountry;
      for (final c in parsed) {
        if (c.alpha2Code.toUpperCase() == 'TZ') {
          defaultCountry = c;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _countries = parsed;
        _selectedCountry = defaultCountry ?? (parsed.isNotEmpty ? parsed.first : null);
        _countriesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _countriesLoading = false;
        _countriesError = e.toString();
      });
    }
  }

  Future<void> _openCountryPicker() async {
    if (_countriesLoading) return;
    if (_countriesError != null) {
      await _fetchCountries();
      if (_countriesError != null) return;
    }
    if (_countries.isEmpty) return;

    final result = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final searchController = TextEditingController();
        var query = '';

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final filtered = _countries.where((c) {
                    final q = query.trim().toLowerCase();
                    if (q.isEmpty) return true;
                    return c.name.toLowerCase().contains(q) ||
                        c.callingCodeWithPlus.contains(q) ||
                        c.alpha2Code.toLowerCase().contains(q);
                  }).toList();

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Select country',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          controller: searchController,
                          onChanged: (v) => setModalState(() => query = v),
                          decoration: InputDecoration(
                            hintText: 'Search country or code',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF800000),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final isSelected =
                                _selectedCountry?.alpha2Code == c.alpha2Code;
                            return ListTile(
                              leading: _FlagIcon(
                                pngUrl: c.flagPngUrl,
                                fallbackText: _flagEmoji(c.alpha2Code),
                              ),
                              title: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle:
                                  Text('${c.alpha2Code}  ${c.callingCodeWithPlus}'),
                              trailing:
                                  isSelected ? const Icon(Icons.check) : null,
                              onTap: () => Navigator.of(context).pop(c),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == null) return;
    setState(() {
      _selectedCountry = result;
    });
  }

  Future<void> _fetchRegions() async {
    setState(() {
      _regionsLoading = true;
      _regionsError = null;
    });

    try {
      final allItems = <dynamic>[];

      Future<Map<String, dynamic>?> fetchPage(int page) async {
        final uri = Uri.parse('https://api.locations.co.tz/v1/regions')
            .replace(queryParameters: {
          'page': page.toString(),
          'limit': '100',
        });

        final res = await http.get(uri);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('Failed to load regions');
        }

        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          allItems.addAll(decoded);
          return null;
        }
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is List) {
            allItems.addAll(data);
          }
          return decoded;
        }
        if (decoded is Map) {
          final normalized = decoded.map((k, v) => MapEntry(k.toString(), v));
          final data = normalized['data'];
          if (data is List) {
            allItems.addAll(data);
          }
          return Map<String, dynamic>.from(normalized);
        }
        throw Exception('Invalid regions response');
      }

      final first = await fetchPage(1);

      final pagesRaw = first?['pagination'] is Map
          ? (first!['pagination'] as Map)['pages']
          : first?['pagination'] is Map<String, dynamic>
              ? (first!['pagination'] as Map<String, dynamic>)['pages']
              : null;
      final pages = int.tryParse(pagesRaw?.toString() ?? '') ?? 1;

      if (pages > 1) {
        for (var p = 2; p <= pages; p++) {
          await fetchPage(p);
        }
      }

      if (allItems.isEmpty) throw Exception('Invalid regions response');

      final parsed = <_Region>[];
      for (final item in allItems) {
        if (item is! Map) continue;
        final code = (item['regionCode'] ?? item['code'] ?? item['region_code'])
                ?.toString() ??
            '';
        final name = (item['regionName'] ?? item['name'] ?? item['region_name'])
                ?.toString() ??
            '';
        if (code.isEmpty || name.isEmpty) continue;
        parsed.add(_Region(code: code, name: name));
      }
      parsed.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _regions = parsed;
        final names = <String>['Select Region'];
        final nameToCode = <String, String>{};
        for (final r in parsed) {
          names.add(r.name);
          nameToCode[r.name] = r.code;
        }
        _regionNames = names;
        _regionNameToCode = nameToCode;
        _regionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _regionsLoading = false;
        _regionsError = e.toString();
      });
    }
  }

  Future<T?> _openSimplePicker<T>({
    required String title,
    required String hint,
    required List<T> items,
    required bool Function(T) isSelected,
    required String Function(T) titleText,
    required String Function(T) subtitleText,
    required Widget leading,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final searchController = TextEditingController();
        var query = '';

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final q = query.trim().toLowerCase();
                  final filtered = items.where((x) {
                    if (q.isEmpty) return true;
                    return titleText(x).toLowerCase().contains(q) ||
                        subtitleText(x).toLowerCase().contains(q);
                  }).toList();

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          controller: searchController,
                          onChanged: (v) => setModalState(() => query = v),
                          decoration: InputDecoration(
                            hintText: hint,
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF800000),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final x = filtered[index];
                            final selected = isSelected(x);
                            return ListTile(
                              leading: leading,
                              title: Text(
                                titleText(x),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(subtitleText(x)),
                              trailing:
                                  selected ? const Icon(Icons.check) : null,
                              onTap: () => Navigator.of(context).pop(x),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickRegion() async {
    if (_regionsLoading) return;
    if (_regionsError != null) {
      await _fetchRegions();
      if (_regionsError != null) return;
    }
    if (_regions.isEmpty) return;

    final picked = await _openSimplePicker<_Region>(
      title: 'Select region',
      hint: 'Search region',
      items: _regions,
      isSelected: (r) => _selectedRegion?.code == r.code,
      titleText: (r) => r.name,
      subtitleText: (r) => r.code,
      leading: const Icon(Icons.location_on_outlined),
    );

    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _selectedRegion = picked;
      _region.text = picked.name;
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _region.dispose();
    _businessName.dispose();
    super.dispose();
  }

  Widget _buildRegionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Region',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRegionName,
          onChanged: (_loading || _regionsLoading) ? null : (v) {
            if (v == null) return;
            if (v == 'Select Region') {
              setState(() {
                _selectedRegionName = v;
                _selectedRegion = null;
                _region.text = '';
              });
              return;
            }

            final code = _regionNameToCode[v];
            setState(() {
              _selectedRegionName = v;
              _region.text = v;
              _selectedRegion = _Region(code: code ?? '', name: v);
            });
          },
          validator: (v) {
            if (_regionsLoading) return 'Loading regions...';
            if (_regionsError != null) return 'Failed to load regions';
            if (v == null || v == 'Select Region') return 'Required';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.map_outlined, color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF800000),
                width: 1.5,
              ),
            ),
            suffixIcon: _regionsError != null
                ? IconButton(
                    onPressed: _regionsLoading ? null : _fetchRegions,
                    icon: const Icon(Icons.refresh),
                  )
                : null,
          ),
          items: _regionNames
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (!_agree) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms of Service & Privacy Policy'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final selected = _selectedCountry;

      final lobId = _selectedBusinessCategoryId;
      if (lobId == null || lobId.isEmpty) {
        throw Exception('Please select a Business category');
      }

      await ApiService.instance.auth.register(
        username: _fullName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        country: selected?.callingCode ?? '255',
        password: _password.text,
        iso: selected?.alpha2Code ?? 'TZ',
        region: _region.text.trim(),
        shopName: _businessName.text.trim(),
        shopType: _businessType,
        lobId: lobId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      String title = 'Error';
      String body = e.toString();

      if (e is ApiException) {
        title = 'ApiException${e.statusCode == null ? '' : ' (${e.statusCode})'}';
        final details = e.details;
        String detailsText = '';
        try {
          if (details is Map || details is List) {
            detailsText = const JsonEncoder.withIndent('  ').convert(details);
          } else if (details != null) {
            detailsText = details.toString();
          }
        } catch (_) {
          detailsText = details?.toString() ?? '';
        }

        body = [
          e.message,
          if (detailsText.isNotEmpty) detailsText,
        ].join('\n\n');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(title)),
      );

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: SelectableText(body),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryMaroon = Color(0xFF800000);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image covering full screen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/onboarding/abstract-wavy-lines-pattern-light-gray-white-background_1246797-2872.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 30),
                    // Welcome text
                    Row(
                      children: [
                        Text(
                          _selectedLanguage == 'English' ? 'Register' : 'Jisajili',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('📝', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      _selectedLanguage == 'English'
                          ? 'Create your Elanledgers account'
                          : 'Tengeneza akaunti yako ya Elanledgers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name
                          _buildTextField(
                            controller: _fullName,
                            label: _selectedLanguage == 'English'
                                ? 'Full Name'
                                : 'Jina Kamili',
                            hint: _selectedLanguage == 'English'
                                ? 'Enter your full name'
                                : 'Weka jina lako kamili',
                            icon: Icons.person_outline,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? (_selectedLanguage == 'English'
                                    ? 'This field is required'
                                    : 'Sehemu hii inahitajika')
                                : null,
                          ),
                          const SizedBox(height: 20),
                          // Email
                          _buildTextField(
                        controller: _email,
                        label: _selectedLanguage == 'English'
                            ? 'Email'
                            : 'Barua Pepe',
                        hint: _selectedLanguage == 'English'
                            ? 'example@email.com'
                            : 'mfano@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? (_selectedLanguage == 'English'
                                ? 'This field is required'
                                : 'Sehemu hii inahitajika')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Phone
                      _buildPhoneNumberField(theme),
                      const SizedBox(height: 20),
                      // Region
                      _buildRegionDropdown(),
                      const SizedBox(height: 20),
                      // Business Name
                      _buildTextField(
                        controller: _businessName,
                        label: _selectedLanguage == 'English'
                            ? 'Business Name'
                            : 'Jina la Biashara',
                        hint: _selectedLanguage == 'English'
                            ? 'Enter business name'
                            : 'Weka jina la biashara',
                        icon: Icons.home_work_outlined,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? (_selectedLanguage == 'English'
                                ? 'This field is required'
                                : 'Sehemu hii inahitajika')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Business Type
                      _buildDropdownField(
                        label: _selectedLanguage == 'English'
                            ? 'Business Type'
                            : 'Aina ya Biashara',
                        icon: Icons.storefront_outlined,
                        value: _businessType,
                        items: const [
                          'Both Product and Services',
                          'Products Only',
                          'Services Only',
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _businessType = v);
                        },
                      ),
                      const SizedBox(height: 20),
                      // Business Category
                      _buildDropdownField(
                        label: _selectedLanguage == 'English'
                            ? 'Business Category'
                            : 'Kategoria ya Biashara',
                        icon: Icons.category_outlined,
                        value: _businessCategory,
                        items: _businessCategoryNames,
                        onChanged: (v) {
                          if (v == null) return;
                          final id = _businessCategoryNameToId[v];
                          setState(() {
                            _businessCategory = v;
                            _selectedBusinessCategoryId = id;
                          });
                        },
                        validator: (v) {
                          if (_businessCategoriesLoading) {
                            return _selectedLanguage == 'English'
                                ? 'Loading categories...'
                                : 'Inapakia kategoria...';
                          }
                          if (_businessCategoriesError != null) {
                            return _selectedLanguage == 'English'
                                ? 'Failed to load categories'
                                : 'Imeshindwa kupakia kategoria';
                          }
                          if (v == null || v == 'Select Business category') {
                            return _selectedLanguage == 'English'
                                ? 'This field is required'
                                : 'Sehemu hii inahitajika';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password
                      _buildTextField(
                        controller: _password,
                        label: _selectedLanguage == 'English'
                            ? 'Password'
                            : 'Neno la Siri',
                        hint: _selectedLanguage == 'English'
                            ? 'Enter password'
                            : 'Weka neno la siri',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscure,
                        onToggleVisibility: () => setState(
                          () => _obscure = !_obscure,
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) {
                            return _selectedLanguage == 'English'
                                ? 'Password is required'
                                : 'Neno la siri linahitajika';
                          }
                          if ((v?.length ?? 0) < 6) {
                            return _selectedLanguage == 'English'
                                ? 'Password must be at least 6 characters'
                                : 'Neno la siri lazima liwe na angalau herufi 6';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Terms Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agree,
                              activeColor: primaryMaroon,
                              onChanged: _loading
                                  ? null
                                  : (v) => setState(
                                        () => _agree = v ?? false,
                                      ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedLanguage == 'English'
                                  ? 'I agree to Terms of Service & Privacy Policy'
                                  : 'Nakubaliana na Masharti ya Huduma & Sera ya Faragha',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Simple Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
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
                              : Text(
                                  _selectedLanguage == 'English'
                                      ? 'Sign Up'
                                      : 'Jisajili',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign In link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedLanguage == 'English'
                                ? "Already have an account? "
                                : "Tayari una akaunti? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              _selectedLanguage == 'English'
                                  ? 'Sign In'
                                  : 'Ingia',
                              style: const TextStyle(
                                color: primaryMaroon,
                                fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLocationSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled && !_loading ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Select $label' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xFF111827)
                          : Colors.grey[500],
                      fontWeight:
                          value.isEmpty ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField(ThemeData theme) {
    final items = _countries;
    final selected = _selectedCountry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: InkWell(
                onTap: _loading ? null : _openCountryPicker,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF800000),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _FlagIcon(
                        pngUrl: selected?.flagPngUrl ?? '',
                        fallbackText: _flagEmoji(selected?.alpha2Code ?? ''),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selected?.callingCodeWithPlus ?? '+255',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                decoration: InputDecoration(
                  hintText: '7xxxxxxxx',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF800000), width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_countriesError != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _countriesLoading ? null : _fetchCountries,
              child: const Text('Retry'),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF800000),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF800000),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF800000),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF800000),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
