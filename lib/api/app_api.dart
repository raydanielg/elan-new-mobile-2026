import 'dart:io';

import 'api_client.dart';
import 'api_response.dart';

class AppApi {
  AppApi({required this.client});

  final ApiClient client;

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint) {
    return client.getJson('/app/get/$endpoint');
  }

  Future<dynamic> getDashboardMenu() {
    return client.getRawJson('/app/get/dashboard');
  }

  Future<dynamic> getData(String endpoint) {
    return client.getRawJson('/app/get/getdata/$endpoint');
  }

  Future<ApiResponse<Map<String, dynamic>>> postData(
    String endpoint, {
    Object? body,
  }) {
    return client.postJson('/app/post/postdata/$endpoint', body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Object? body,
  }) {
    return client.postJson('/app/post/$endpoint', body: body);
  }

  Future<ApiResponse<Map<String, dynamic>>> postMap() {
    return client.postJson('/app/post/map');
  }

  // ==================== PRODUCTS API ====================

  /// Create new product with optional images
  Future<ApiResponse<Map<String, dynamic>>> createProduct({
    required Map<String, String> fields,
    List<File>? images,
  }) {
    return client.postMultipart(
      '/app/post/postdata/stock/register/create',
      fields: fields,
      files: images,
      fileKey: 'photos[]',
    );
  }

  /// Update existing product with optional images
  Future<ApiResponse<Map<String, dynamic>>> updateProduct({
    required String productId,
    required Map<String, String> fields,
    List<File>? images,
  }) {
    final updatedFields = {...fields, 'product_id': productId};
    return client.postMultipart(
      '/app/post/postdata/stock/products/update',
      fields: updatedFields,
      files: images,
      fileKey: 'photos[]',
    );
  }

  /// Delete product
  Future<ApiResponse<Map<String, dynamic>>> deleteProduct(String productId) {
    return client.postJson(
      '/app/post/postdata/stock/products/delete',
      body: {'product_id': productId},
    );
  }

  /// Get all products
  Future<dynamic> getProducts() {
    return client.getRawJson('/app/get/getdata/stock');
  }

  /// Get product categories
  Future<dynamic> getProductCategories() {
    return client.getRawJson('/app/get/getdata/category');
  }

  // ==================== SALES API ====================

  /// Get sales orders with proper JSON handling
  Future<dynamic> getSalesOrders() {
    return client.getRawJson('/app/get/getdata/sales_orders');
  }

  /// Get customers in sales context
  Future<dynamic> getCustomersInSales() {
    return client.getRawJson('/app/get/getdata/customersInSales');
  }

  /// Get staff in sales context
  Future<dynamic> getStaffInSales() {
    return client.getRawJson('/app/get/getdata/staffInSales');
  }

  /// Get waiters in sales context (for hotels)
  Future<dynamic> getWaitersInSales() {
    return client.getRawJson('/app/get/getdata/waitersInSales');
  }

  /// Get specific sale details
  Future<dynamic> getSaleRecord(String saleId) {
    return client.getRawJson('/app/get/sales/record?sale_id=$saleId');
  }

  /// Send email for a specific record
  Future<ApiResponse<Map<String, dynamic>>> sendEmail({
    required String type,
    required String recordId,
    required String email,
    String? subject,
    String? message,
  }) {
    return client.postJson(
      '/app/post/settings/email/send',
      body: {
        'type': type,
        'record_id': recordId,
        'email': email,
        if (subject != null) 'subject': subject,
        if (message != null) 'message': message,
      },
    );
  }

  /// Get payment modes/accounts
  Future<dynamic> getPaymentModes() {
    return client.getRawJson('/app/get/getdata/payment_mode');
  }

  /// Add payment to a sale/invoice/order
  Future<ApiResponse<Map<String, dynamic>>> addPayment({
    required String saleId,
    required double amount,
    required String date,
    required String toAccount,
  }) {
    return client.postJson(
      '/app/post/sales/add-payment',
      body: {
        'sale_id': saleId,
        'amount': amount,
        'date': date,
        'to_account': toAccount,
      },
    );
  }

  // ==================== RECEIPT API ====================

  /// Get receipt preview URL (for WebView or external browser)
  String getReceiptPreviewUrl(String saleId) {
    return '${client.config.baseUrl}/app/get/getdata/sales/receipt/preview?sale_id=$saleId';
  }

  /// Get receipt download URL
  String getReceiptDownloadUrl(String saleId) {
    return '${client.config.baseUrl}/app/get/getdata/sales/receipt/download?sale_id=$saleId';
  }

  /// Email receipt to customer
  Future<ApiResponse<Map<String, dynamic>>> emailReceipt({
    required String saleId,
    required String to,
  }) {
    return client.postJson(
      '/app/post/postdata/sales/receipt/email',
      body: {
        'sale_id': saleId,
        'to': to,
      },
    );
  }
}
