import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class GlobalFilterWidget extends StatefulWidget {
  const GlobalFilterWidget({
    super.key,
    this.onFilterChanged,
    this.showAsAppBar = false,
  });

  final VoidCallback? onFilterChanged;
  final bool showAsAppBar;

  @override
  State<GlobalFilterWidget> createState() => _GlobalFilterWidgetState();
}

class _GlobalFilterWidgetState extends State<GlobalFilterWidget> {
  bool _isApplying = false;

  String get _currentFilterTitle => ApiService.instance.tokenStore.globalFilterTitle;
  bool get _hasActiveFilter => ApiService.instance.tokenStore.hasActiveFilter;

  Future<void> _applyFilter(String filter, {DateTime? from, DateTime? to, String? title}) async {
    setState(() => _isApplying = true);
    
    try {
      final body = <String, String>{'filter': filter};
      if (from != null) body['from'] = DateFormat('yyyy-MM-dd').format(from);
      if (to != null) body['to'] = DateFormat('yyyy-MM-dd').format(to);
      
      await ApiService.instance.app.postData('filter/set', body: body);
      
      // Save to global state
      await ApiService.instance.tokenStore.setGlobalFilter(
        type: filter,
        from: from != null ? DateFormat('yyyy-MM-dd').format(from) : null,
        to: to != null ? DateFormat('yyyy-MM-dd').format(to) : null,
        title: title ?? _getFilterTitle(filter, from, to),
      );
      
      widget.onFilterChanged?.call();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter applied: ${ApiService.instance.tokenStore.globalFilterTitle}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  String _getFilterTitle(String filter, DateTime? from, DateTime? to) {
    switch (filter) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'thisweek':
        return 'This Week';
      case 'last_week':
        return 'Last Week';
      case 'thismonth':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'custom':
        if (from != null && to != null) {
          return '${DateFormat('dd/MM').format(from)} - ${DateFormat('dd/MM').format(to)}';
        }
        return 'Custom Range';
      case 'reset':
        return 'All Time';
      default:
        return 'All Time';
    }
  }

  Future<DateTimeRange?> _pickRange() async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _showFilterSheet() {
    final primary = Theme.of(context).colorScheme.primary;
    
    Widget filterButton(String label, String filterKey, {bool isActive = false}) {
      final active = isActive || (filterKey == 'reset' && !_hasActiveFilter);
      return SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: _isApplying ? null : () async {
            if (filterKey == 'custom') {
              final picked = await _pickRange();
              if (picked == null) return;
              await _applyFilter('custom', from: picked.start, to: picked.end);
              return;
            }
            await _applyFilter(filterKey, title: label);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: active ? primary.withOpacity(0.1) : null,
            side: BorderSide(
              color: active ? primary : Colors.grey.shade300,
              width: active ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isApplying && isActive
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primary))
              : Text(
                  label,
                  style: TextStyle(
                    color: active ? primary : Colors.black87,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Header
                Row(
                  children: [
                    Icon(Icons.filter_list, color: primary, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Global Filter',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                    ),
                    if (_hasActiveFilter)
                      TextButton.icon(
                        onPressed: _isApplying ? null : () => _applyFilter('reset', title: 'All Time'),
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                // Current filter indicator
                if (_hasActiveFilter) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Filter',
                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _currentFilterTitle,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                const Text(
                  'Quick Filters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                // Filter buttons grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: [
                    filterButton('All Time', 'reset', isActive: !_hasActiveFilter),
                    filterButton('Today', 'today', isActive: _currentFilterTitle == 'Today'),
                    filterButton('Yesterday', 'yesterday', isActive: _currentFilterTitle == 'Yesterday'),
                    filterButton('This Week', 'thisweek', isActive: _currentFilterTitle == 'This Week'),
                    filterButton('Last Week', 'last_week', isActive: _currentFilterTitle == 'Last Week'),
                    filterButton('This Month', 'thismonth', isActive: _currentFilterTitle == 'This Month'),
                    filterButton('Last Month', 'last_month', isActive: _currentFilterTitle == 'Last Month'),
                    filterButton('Custom Range', 'custom', isActive: _currentFilterTitle.contains('-')),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    
    if (widget.showAsAppBar) {
      return AppBar(
        title: const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasActiveFilter)
            TextButton.icon(
              onPressed: _isApplying ? null : () => _applyFilter('reset', title: 'All Time'),
              icon: const Icon(Icons.clear, color: Colors.white, size: 18),
              label: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: _isApplying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.filter_list),
            onPressed: _isApplying ? null : _showFilterSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: primary.withOpacity(0.9),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Current: $_currentFilterTitle',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Compact chip version for embedding in other pages
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hasActiveFilter ? primary.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hasActiveFilter ? primary.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: _hasActiveFilter ? primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _currentFilterTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _hasActiveFilter ? FontWeight.bold : FontWeight.w600,
                    color: _hasActiveFilter ? primary : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_hasActiveFilter) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _isApplying ? null : () => _applyFilter('reset', title: 'All Time'),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Global helper function to apply filter from anywhere
Future<void> applyGlobalFilter({
  required String type,
  String? from,
  String? to,
  String? title,
}) async {
  final body = <String, String>{'filter': type};
  if (from != null) body['from'] = from;
  if (to != null) body['to'] = to;
  
  await ApiService.instance.app.postData('filter/set', body: body);
  
  await ApiService.instance.tokenStore.setGlobalFilter(
    type: type,
    from: from,
    to: to,
    title: title,
  );
}

// Global helper to reset filter
Future<void> resetGlobalFilter() async {
  await ApiService.instance.app.postData('filter/set', body: {'filter': 'reset'});
  await ApiService.instance.tokenStore.resetGlobalFilter();
}
