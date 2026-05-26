import '../api/api_service.dart';

/// Permission keys matching the backend permission files
class PermissionKeys {
  // Management
  static const String isManager = 'is_manager';
  static const String canDeleteRecord = 'can_delete_record';
  
  // Sales & Receipt
  static const String canMakeSales = 'can_make_sales';
  static const String canMakeInvoice = 'can_make_invoice';
  static const String canManageOrders = 'can_manage_orders';
  static const String canViewSales = 'can_view_sales';
  static const String canManageCustomers = 'can_manage_customers';
  static const String canPrintReceipt = 'can_print_receipt';
  static const String canEnableCommission = 'can_enable_commission';
  
  // Stock
  static const String canAddProduct = 'can_add_product';
  static const String canViewStockBalance = 'can_view_stock_balance';
  static const String canCountStock = 'can_count_stock';
  static const String canAddStockIn = 'can_add_stockin';
  static const String canViewSuppliers = 'can_view_suppliers';
  static const String canAddBadStock = 'can_add_bad_stock';
  static const String canViewProfitEstimate = 'can_view_profit_estimate';
  static const String canViewStockValue = 'can_view_stock_value';
  static const String canViewLoss = 'can_view_loss';
  
  // Profit, Expense & Cashflow
  static const String canViewProfit = 'can_view_profit';
  static const String canAddExpense = 'can_add_expense';
  static const String canViewCashIn = 'can_view_cashin';
  static const String canViewCashOut = 'can_view_cashout';
  static const String canManageCashflow = 'can_manage_cashflow';
  static const String canViewProfitReport = 'can_view_profit_report';
  
  // SMS & Email
  static const String canSendSms = 'can_send_sms';
  static const String canSetSenderId = 'can_set_senderid';
  static const String canAddContact = 'can_add_contact';
  static const String canSendEmail = 'can_send_email';
  
  // Other
  static const String canManageFileCabinet = 'can_manage_filecabinet';
  static const String canViewDashboardSummary = 'can_view_dashboard_summary';
  static const String canViewReports = 'can_view_reports';
  static const String canGiveDiscount = 'can_give_discount';
  static const String canEditEntry = 'can_edit_entry';
  static const String canDeleteEntry = 'can_delete_entry';
  static const String canBackdateEntry = 'can_backdate_entry';
  static const String canReturnStock = 'can_return_stock';
  static const String canGenerateBarcode = 'can_generate_barcode';
  static const String canPreviewReceipt = 'can_preview_receipt';
  
  // Restaurant/Hotel specific
  static const String isKitchenUser = 'is_kitchen_user';
  static const String canManageKitchenOrders = 'can_manage_kitchen_orders';
  
  // Microfinance specific
  static const String canManageUsers = 'can_manage_users';
  static const String canAssignRoles = 'can_assign_roles';
  static const String canViewAuditLogs = 'can_view_audit_logs';
  static const String canAddClient = 'can_add_client';
  static const String canApplyLoan = 'can_apply_loan';
  static const String canApproveLoan = 'can_approve_loan';
  static const String canDisburseLoan = 'can_disburse_loan';
  static const String canReceiveLoanPayment = 'can_receive_loan_payment';
}

/// Service to handle user permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _permissionSchema = {};
  bool _isManager = false;
  String? _businessType;

  /// Initialize permission service with user data
  Future<void> init() async {
    try {
      // Fetch session user data
      final userRes = await ApiService.instance.app.getData('session_user');
      if (userRes is Map) {
        _userData = Map<String, dynamic>.from(userRes);
      }

      // Fetch permission schema
      final permRes = await ApiService.instance.app.getData('permissions');
      if (permRes is List) {
        _permissionSchema = {for (var p in permRes) p['key']: p};
      }

      // Check if manager
      _isManager = _getPermissionValue(PermissionKeys.isManager) == '1';
      
      // Determine business type
      _businessType = _userData['business_type']?.toString() ?? 
                     _userData['shop_type']?.toString() ??
                     _userData['session_shop_type']?.toString();
    } catch (e) {
      // Silent fail - permissions will default to false
    }
  }

  /// Get raw user data
  Map<String, dynamic> get userData => _userData;
  
  /// Check if current user is manager
  bool get isManager => _isManager;
  
  /// Get business type
  String? get businessType => _businessType;
  
  /// Check if hotel/restaurant business
  bool get isHotel => _businessType?.toLowerCase() == 'hotel';
  
  /// Check if microfinance business
  bool get isMicrofinance => _businessType?.toLowerCase() == 'microfinance';

  /// Check if user has a specific permission
  bool hasPermission(String key) {
    // Manager has all permissions
    if (_isManager) return true;
    
    final value = _getPermissionValue(key);
    return value == '1' || value == true || value == 'true';
  }

  /// Get permission value
  dynamic _getPermissionValue(String key) {
    // First check in userData permissions
    final permissions = _userData['permissions'];
    if (permissions is Map && permissions.containsKey(key)) {
      return permissions[key];
    }
    
    // Check directly in userData
    if (_userData.containsKey(key)) {
      return _userData[key];
    }
    
    // Check in role data
    final role = _userData['role'];
    if (role is Map) {
      if (role.containsKey(key)) {
        return role[key];
      }
      final rolePerms = role['permissions'];
      if (rolePerms is Map && rolePerms.containsKey(key)) {
        return rolePerms[key];
      }
    }
    
    return null;
  }

  /// Get permission label from schema
  String? getPermissionLabel(String key) {
    return _permissionSchema[key]?['label']?.toString();
  }

  /// Get permission description from schema
  String? getPermissionDescription(String key) {
    return _permissionSchema[key]?['description']?.toString();
  }

  // ======== HELPER METHODS FOR COMMON PERMISSIONS ========
  
  bool get canMakeSales => hasPermission(PermissionKeys.canMakeSales);
  bool get canMakeInvoice => hasPermission(PermissionKeys.canMakeInvoice);
  bool get canManageOrders => hasPermission(PermissionKeys.canManageOrders);
  bool get canViewSales => hasPermission(PermissionKeys.canViewSales);
  bool get canManageCustomers => hasPermission(PermissionKeys.canManageCustomers);
  bool get canPrintReceipt => hasPermission(PermissionKeys.canPrintReceipt);
  
  bool get canAddProduct => hasPermission(PermissionKeys.canAddProduct);
  bool get canViewStockBalance => hasPermission(PermissionKeys.canViewStockBalance);
  bool get canViewSuppliers => hasPermission(PermissionKeys.canViewSuppliers);
  
  bool get canViewProfit => hasPermission(PermissionKeys.canViewProfit);
  bool get canAddExpense => hasPermission(PermissionKeys.canAddExpense);
  bool get canManageCashflow => hasPermission(PermissionKeys.canManageCashflow);
  
  bool get canSendEmail => hasPermission(PermissionKeys.canSendEmail);
  bool get canSendSms => hasPermission(PermissionKeys.canSendSms);
  
  bool get canEditEntry => hasPermission(PermissionKeys.canEditEntry);
  bool get canDeleteEntry => hasPermission(PermissionKeys.canDeleteEntry);
  bool get canGiveDiscount => hasPermission(PermissionKeys.canGiveDiscount);
  bool get canReturnStock => hasPermission(PermissionKeys.canReturnStock);
  bool get canGenerateBarcode => hasPermission(PermissionKeys.canGenerateBarcode);
  bool get canPreviewReceipt => hasPermission(PermissionKeys.canPreviewReceipt);
  
  bool get canViewReports => hasPermission(PermissionKeys.canViewReports);
  bool get canViewDashboard => hasPermission(PermissionKeys.canViewDashboardSummary);
  
  // Restaurant/Hotel
  bool get isKitchenUser => hasPermission(PermissionKeys.isKitchenUser);
  bool get canManageKitchen => hasPermission(PermissionKeys.canManageKitchenOrders);
  
  // Microfinance
  bool get canManageUsers => hasPermission(PermissionKeys.canManageUsers);
  bool get canAddClient => hasPermission(PermissionKeys.canAddClient);
  bool get canApplyLoan => hasPermission(PermissionKeys.canApplyLoan);
  bool get canApproveLoan => hasPermission(PermissionKeys.canApproveLoan);
  bool get canReceivePayment => hasPermission(PermissionKeys.canReceiveLoanPayment);

  /// Clear cached permissions
  void clear() {
    _userData = {};
    _permissionSchema = {};
    _isManager = false;
    _businessType = null;
  }
}

/// Global permission check helper
bool hasPermission(String key) {
  return PermissionService().hasPermission(key);
}
