import 'package:flutter/material.dart';

import '../widgets/app_header.dart';

class FileCabinetPage extends StatefulWidget {
  const FileCabinetPage({super.key});

  @override
  State<FileCabinetPage> createState() => _FileCabinetPageState();
}

class _FileCabinetPageState extends State<FileCabinetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample file categories
  final List<_FileCategory> _categories = [
    _FileCategory('Invoices', Icons.receipt, Colors.blue, 12),
    _FileCategory('Receipts', Icons.receipt_long, Colors.green, 8),
    _FileCategory('Reports', Icons.bar_chart, Colors.purple, 5),
    _FileCategory('Contracts', Icons.description, Colors.orange, 3),
    _FileCategory('ID Documents', Icons.badge, Colors.red, 7),
    _FileCategory('Others', Icons.folder, Colors.grey, 15),
  ];

  final List<_FileItem> _recentFiles = [
    _FileItem('Invoice_001.pdf', 'Invoices', '2 MB', 'Today', Icons.picture_as_pdf, Colors.red),
    _FileItem('Receipt_2024.jpg', 'Receipts', '1.5 MB', 'Yesterday', Icons.image, Colors.green),
    _FileItem('Sales_Report_Q1.pdf', 'Reports', '3.2 MB', '2 days ago', Icons.picture_as_pdf, Colors.red),
    _FileItem('Contract_ABC.pdf', 'Contracts', '1.8 MB', '3 days ago', Icons.picture_as_pdf, Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload File',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gallery feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Document'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document upload coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'File Cabinet',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Categories', icon: Icon(Icons.folder)),
                Tab(text: 'Recent', icon: Icon(Icons.access_time)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildRecentTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${cat.name}...')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, color: cat.color, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cat.count} files',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cat.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFiles.length,
      itemBuilder: (context, i) {
        final file = _recentFiles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: file.color.withValues(alpha: 0.1),
              child: Icon(file.icon, color: file.color),
            ),
            title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${file.category} • ${file.size} • ${file.date}'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.download),
                          title: const Text('Download'),
                          onTap: () => Navigator.pop(ctx),
                        ),
                        ListTile(
                          leading: const Icon(Icons.share),
                          title: const Text('Share'),
                          onTap: () => Navigator.pop(ctx),
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FileCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int count;

  _FileCategory(this.name, this.icon, this.color, this.count);
}

class _FileItem {
  final String name;
  final String category;
  final String size;
  final String date;
  final IconData icon;
  final Color color;

  _FileItem(this.name, this.category, this.size, this.date, this.icon, this.color);
}
