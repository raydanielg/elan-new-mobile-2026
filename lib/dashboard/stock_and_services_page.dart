import 'package:flutter/material.dart';

import '../widgets/app_header.dart';
import 'stock_and_services/barcodes_section.dart';

class StockAndServicesPage extends StatefulWidget {
  const StockAndServicesPage({super.key});

  @override
  State<StockAndServicesPage> createState() => _StockAndServicesPageState();
}

class _StockAndServicesPageState extends State<StockAndServicesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0;

  DateTimeRange? _customRange;

  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _fromAccountController = TextEditingController(text: 'Cash');
  final TextEditingController _qtyController = TextEditingController(text: '0');
  final TextEditingController _bpController = TextEditingController(text: '2000.00');
  final TextEditingController _spController = TextEditingController(text: '2000.00');
  final TextEditingController _wpController = TextEditingController(text: '2000.00');
  final TextEditingController _expController = TextEditingController();

  String? _supplier;

  @override
  void dispose() {
    _productSearchController.dispose();
    _fromAccountController.dispose();
    _qtyController.dispose();
    _bpController.dispose();
    _spController.dispose();
    _wpController.dispose();
    _expController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: now,
    );
    if (picked == null) return;
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    final yyyy = picked.year.toString().padLeft(4, '0');
    setState(() => _expController.text = '$mm/$dd/$yyyy');
  }

  void _openRestockPanel() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final yyyy = d.year.toString().padLeft(4, '0');
    return '$mm/$dd/$yyyy';
  }

  Future<DateTimeRange?> _pickRange() {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customRange ?? DateTimeRange(start: now, end: now),
    );
  }

  Future<void> _openFilterSheet() {
    final primary = Theme.of(context).colorScheme.primary;

    Widget filterButton(String label, {VoidCallback? onTap}) {
      return SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: onTap ?? () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (ctx, a1, a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.92,
              height: MediaQuery.of(ctx).size.height * 0.72,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select filter to proceed',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF16A34A), width: 2),
                          ),
                          child: const Icon(Icons.arrow_downward, size: 14, color: Color(0xFF16A34A)),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        children: [
                          if (_customRange != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Text(
                                'Custom: ${_fmtDate(_customRange!.start)} - ${_fmtDate(_customRange!.end)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 3.3,
                              children: [
                                filterButton('Reset', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('Today', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('Yesterday', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('This Week', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('Last Week', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('This Month', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('Last Month', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('Last 3 Months', onTap: () => Navigator.of(ctx).maybePop()),
                                filterButton('This Year', onTap: () => Navigator.of(ctx).maybePop()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await _pickRange();
                                if (picked == null) return;
                                if (!mounted) return;
                                setState(() => _customRange = picked);
                                Navigator.of(ctx).maybePop();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Custom', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 4, color: primary.withValues(alpha: 0.08)),
                ],
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    Widget topIconAction({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 2),
                    color: Colors.white,
                  ),
                  child: Icon(icon, size: 18, color: primary),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? primary : const Color(0xFF111827),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: 64,
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget quickCircle({required String label, VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget statusRow({
      required String leftLabel,
      required Color leftColor,
      required String rightText,
      Color rightColor = const Color(0xFF6B7280),
      bool showDot = true,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: leftColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                leftLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (showDot)
                      const Text(
                        '•',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (showDot) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rightText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: rightColor,
                        ),
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

    Widget metric({required String title, required String value, required Color valueColor}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    Widget restockPanel() {
      InputDecoration inputDecoration({String? hintText}) {
        return InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primary, width: 1.4),
          ),
        );
      }

      Widget labelBox(String label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        );
      }

      Widget smallField({
        required TextEditingController controller,
        String? hint,
        TextAlign align = TextAlign.center,
        double width = 80,
        Widget? suffix,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
        return SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            textAlign: align,
            readOnly: readOnly,
            onTap: onTap,
            decoration: inputDecoration(hintText: hint).copyWith(suffixIcon: suffix),
          ),
        );
      }

      return Drawer(
        width: MediaQuery.of(context).size.width * 0.92,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Stocks',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  children: [
                    Row(
                      children: [
                        labelBox('Search'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _productSearchController,
                            decoration: inputDecoration(hintText: 'Product name...'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        labelBox('From account'),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _fromAccountController,
                            textAlign: TextAlign.center,
                            decoration: inputDecoration(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('DELL HP', style: TextStyle(fontWeight: FontWeight.w900)),
                              SizedBox(height: 6),
                              Text('995.00 Available', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        labelBox('Qty'),
                        const SizedBox(width: 8),
                        smallField(controller: _qtyController, width: 64),
                        const SizedBox(width: 10),
                        labelBox('BP'),
                        const SizedBox(width: 8),
                        smallField(controller: _bpController, width: 92),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        labelBox('SP'),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _spController, textAlign: TextAlign.center, decoration: inputDecoration())),
                        const SizedBox(width: 12),
                        labelBox('WP'),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _wpController, textAlign: TextAlign.center, decoration: inputDecoration())),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        labelBox('Exp'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _expController,
                            readOnly: true,
                            onTap: _pickExpiry,
                            decoration: inputDecoration(hintText: 'mm/dd/y').copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                onPressed: _pickExpiry,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        labelBox('Supplier'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _supplier,
                            decoration: inputDecoration().copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('-select-')),
                              DropdownMenuItem(value: 'Supplier A', child: Text('Supplier A')),
                              DropdownMenuItem(value: 'Supplier B', child: Text('Supplier B')),
                            ],
                            onChanged: (v) => setState(() => _supplier = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(height: 2, color: const Color(0xFF2563EB).withValues(alpha: 0.55)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('Save', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F2F2),
      endDrawer: restockPanel(),
      appBar: AppHeader(
        title: 'Stock and Services',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  topIconAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    selected: _selectedTabIndex == 0,
                    onTap: () {
                      setState(() => _selectedTabIndex = 0);
                    },
                  ),
                  topIconAction(
                    icon: Icons.add_box_outlined,
                    label: 'Restock',
                    selected: _selectedTabIndex == 1,
                    onTap: () {
                      setState(() => _selectedTabIndex = 1);
                      _openRestockPanel();
                    },
                  ),
                  topIconAction(
                    icon: Icons.qr_code_2_outlined,
                    label: 'Barcodes',
                    selected: _selectedTabIndex == 2,
                    onTap: () {
                      setState(() => _selectedTabIndex = 2);
                    },
                  ),
                  topIconAction(
                    icon: Icons.filter_list,
                    label: 'Filter',
                    selected: _selectedTabIndex == 3,
                    onTap: () {
                      setState(() => _selectedTabIndex = 3);
                      _openFilterSheet();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedTabIndex == 2)
              BarcodesSection(
                primary: primary,
                quickAction: (label) => quickCircle(label: label, onTap: () {}),
              )
            else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    quickCircle(label: 'Cat'),
                    quickCircle(label: 'Product'),
                    quickCircle(label: 'Import'),
                    quickCircle(label: 'Supplier'),
                    quickCircle(label: 'Transfer'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              statusRow(
                leftLabel: 'LOW',
                leftColor: const Color(0xFF0EA5E9),
                rightText: 'All OK',
                rightColor: const Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 8),
              statusRow(
                leftLabel: 'EXP',
                leftColor: const Color(0xFFF59E0B),
                rightText: 'no expiry alerts',
                rightColor: const Color(0xFF6B7280),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Category Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0xFF16A34A),
                        ),
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    metric(
                      title: 'Loss:',
                      value: '0.00',
                      valueColor: const Color(0xFFDC2626),
                    ),
                    metric(
                      title: 'S.Value:',
                      value: '1,990,000.00',
                      valueColor: const Color(0xFF16A34A),
                    ),
                    metric(
                      title: 'P.Estimate:',
                      value: '0.00',
                      valueColor: const Color(0xFF111827),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search here..',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Stock Summary by Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Uncategorized',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('• Stock Value: 1,990,000.00', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('• Profit Est: 0.00', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('Items: 1', style: TextStyle(fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('Sales: 0.00', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                        SizedBox(height: 4),
                        Text('Loss: 0.00', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.expand_more, color: primary),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
