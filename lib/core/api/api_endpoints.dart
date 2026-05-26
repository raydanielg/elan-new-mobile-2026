class ApiEndpoints {
  // Base API configuration
  static const String baseUrl = 'https://elanledgers.co.tz/api/v1';

  // ==========================================
  // 1. AUTHENTICATION ENDPOINTS (Auth.php)
  // ==========================================
  static const String authMap = '/app/auth/map'; // GET
  static const String authSignin = '/app/auth/signin'; // POST
  static const String authSignup = '/app/auth/signup'; // POST
  static const String authRegister = '/app/auth/register'; // POST
  static const String authResetSend = '/app/auth/reset/send'; // POST
  static const String authResetVerify = '/app/auth/reset/verify'; // POST
  static const String authCompleteProfile = '/app/auth/completeprofile'; // POST
  static const String authAddShop = '/app/auth/addshop'; // POST
  static const String authSwitchShop = '/app/auth/switchshop'; // POST
  static const String authSignout = '/app/auth/signout'; // GET|POST
  static const String authConstants = '/app/auth/constants'; // GET|POST

  // ==========================================
  // 2. GETTER / READ ENDPOINTS (Get.php)
  // ==========================================
  static const String getDashboard = '/app/get/dashboard'; // GET - Returns dashboard menu based on token session

  // Dynamic Helper-backed data GET endpoints: /app/get/getdata/{endpoint}
  static String getData(String endpoint) => '/app/get/getdata/$endpoint';

  // List of all mapped GET helper endpoints (getdata/{endpoint})
  static const List<String> helperGetEndpoints = [
    'filter_range',
    'stock_category',
    'payment_mode',
    'permissions',
    'shop_settings',
    'session_shop',
    'sidemenu',
    'dashboard_summary',
    'products',
    'product_history',
    'stock',
    'stockCategoryWise',
    'sellable_stock',
    'profit_summary',
    'salestable',
    'sales',
    'orders',
    'productsInOrder',
    'invoices',
    'sales_orders',
    'sales_summary',
    'invoice_summary',
    'order_summary',
    'expense_accounts',
    'expense_summary',
    'cashbookAccounts',
    'chatOfAccounts',
    'sourceOfFundAccounts',
    'cashflow',
    'expenses',
    'team',
    'waiters',
    'staffInSales',
    'waitersInSales',
    'shops',
    'users',
    'session_user',
    'reseller_summary',
    'reseller_invited_shops',
    'reseller_admin_list',
    'my_shops',
    'contact_category',
    'contacts',
    'customers',
    'suppliers',
    'oncredit_suppliers',
    'oncash_suppliers',
    'onorder_suppliers',
    'oncredit_customers',
    'customerInSales',
    'systeminfo',
    'suUsers',
    'suShops',
    'packages',
    'lobs',
    'purchase_history',
    'purchase_orders',
    'importHistory',
    'recycle_bin',
    'tms',
    'tellerCashManagement',
    'customerCashManagement',
    'customerAccountsSummary',
    'bankingCustomerAccounts',
    'totalStockReport',
    'totalSalesReport',
    'loanProducts',
    'loanApplications',
    'loans',
    'loanSchedules',
    'guarantors',
    'onlyguarantors',
  ];

  // Specific Controller-mapped GET endpoints (getdata/{endpoint})
  static const String customerCampaignUsers = '/app/get/getdata/customer/campaign-users';
  static const String customerMessageHistory = '/app/get/getdata/customer/message-history';
  static const String salesRecord = '/app/get/getdata/sales/record';
  static const String salesReceiptPreview = '/app/get/getdata/sales/receipt/preview';
  static const String salesReceiptDownload = '/app/get/getdata/sales/receipt/download';
  static const String salesCustomerStatementPreview = '/app/get/getdata/sales/customer-statement/preview';
  static const String salesCustomerStatementDownload = '/app/get/getdata/sales/customer-statement/download';
  static const String reportsExportPdf = '/app/get/getdata/reports/export/pdf';
  static const String reportsExportExcel = '/app/get/getdata/reports/export/excel';
  static const String stockPurchaseDocumentPreview = '/app/get/getdata/stock/purchase-document/preview';
  static const String stockPurchaseDocumentDownload = '/app/get/getdata/stock/purchase-document/download';
  static const String stockSupplierStatementPreview = '/app/get/getdata/stock/supplier-statement/preview';
  static const String stockSupplierStatementDownload = '/app/get/getdata/stock/supplier-statement/download';
  static const String stockInventory = '/app/get/getdata/stock/inventory';
  static const String stockLobCategories = '/app/get/getdata/stock/lob-categories';
  static const String stockRemoteShopProducts = '/app/get/getdata/stock/remote-shop-products';
  static const String settingsServerInfo = '/app/get/getdata/settings/serverinfo';

  // Dynamic Report Endpoints: /app/get/getreport/{report_function}
  static String getReport(String reportFunction) => '/app/get/getreport/$reportFunction';


  // ==========================================
  // 3. POST / MUTATION ENDPOINTS (Post.php)
  // ==========================================
  // Dynamic Poster write endpoints: /app/post/postdata/{endpoint}
  static String postData(String endpoint) => '/app/post/postdata/$endpoint';

  // Mapped POST Endpoints
  static const String postFilterSet = '/app/post/postdata/filter/set';
  static const String postReportFilterSet = '/app/post/postdata/report/filter/set';
  static const String postBankingCustomerTransaction = '/app/post/postdata/banking/customer-transaction';
  static const String postCashflowAddFund = '/app/post/postdata/cashflow/add-fund';
  static const String postCashflowAddExpense = '/app/post/postdata/cashflow/add-expense';
  static const String postCashflowDeleteExpenses = '/app/post/postdata/cashflow/delete-expenses';
  static const String postCustomerCreate = '/app/post/postdata/customer/create';
  static const String postCustomerDelete = '/app/post/postdata/customer/delete';
  static const String postCustomerImport = '/app/post/postdata/customer/import';
  static const String postCustomerCategoryCreate = '/app/post/postdata/customer/category/create';
  static const String postCustomerCategoryDelete = '/app/post/postdata/customer/category/delete';
  static const String postCustomerContactCreate = '/app/post/postdata/customer/contact/create';
  static const String postCustomerContactBulkCategorize = '/app/post/postdata/customer/contact/bulk-categorize';
  static const String postCustomerSmsSendBulk = '/app/post/postdata/customer/sms/send-bulk';
  static const String postHomePasswordChange = '/app/post/postdata/home/password/change';
  static const String postMicrofinanceLoanProductCreate = '/app/post/postdata/microfinance/loan-product/create';
  static const String postMicrofinanceGuarantorCreate = '/app/post/postdata/microfinance/guarantor/create';
  static const String postMicrofinanceImport = '/app/post/postdata/microfinance/import';
  static const String postMicrofinanceCategoryCreate = '/app/post/postdata/microfinance/category/create';
  static const String postMicrofinanceContactCreate = '/app/post/postdata/microfinance/contact/create';
  static const String postMicrofinanceSmsSendBulk = '/app/post/postdata/microfinance/sms/send-bulk';
  static const String postMicrofinanceLoanCreate = '/app/post/postdata/microfinance/loan/create';
  static const String postMicrofinanceLoanUpdate = '/app/post/postdata/microfinance/loan/update';
  static const String postResellerJoin = '/app/post/postdata/reseller/join';
  static const String postSalesAdd = '/app/post/postdata/sales/add';
  static const String postSalesUpdate = '/app/post/postdata/sales/update';
  static const String postSalesAddPayment = '/app/post/postdata/sales/add-payment';
  static const String postSalesDeleteRecord = '/app/post/postdata/sales/delete-record';
  static const String postSalesOrderStatusUpdate = '/app/post/postdata/sales/order-status/update';
  static const String postSalesReceiptEmail = '/app/post/postdata/sales/receipt/email';
  static const String postSalesCustomerStatementEmail = '/app/post/postdata/sales/customer-statement/email';
  static const String postSettingsAccountCreate = '/app/post/postdata/settings/account/create';
  static const String postSettingsRecordUpdate = '/app/post/postdata/settings/record/update';
  static const String postSettingsShopUpdate = '/app/post/postdata/settings/shop/update';
  static const String postSettingsProfileUpdate = '/app/post/postdata/settings/profile/update';
  static const String postSettingsRecordDelete = '/app/post/postdata/settings/record/delete';
  static const String postSettingsAccountDelete = '/app/post/postdata/settings/account/delete';
  static const String postSettingsShopReset = '/app/post/postdata/settings/shop/reset';
  static const String postSettingsSmsAccountVerify = '/app/post/postdata/settings/sms-account/verify';
  static const String postSettingsEmailSend = '/app/post/postdata/settings/email/send';
  static const String postStockRegisterCreate = '/app/post/postdata/stock/register/create';
  static const String postStockRegisterImport = '/app/post/postdata/stock/register/import';
  static const String postStockRestockCreate = '/app/post/postdata/stock/restock/create';
  static const String postStockRestockBalance = '/app/post/postdata/stock/restock/balance';
  static const String postStockProductUpdate = '/app/post/postdata/stock/product/update';
  static const String postStockProductDeleteBulk = '/app/post/postdata/stock/product/delete-bulk';
  static const String postStockProductCategoryBulk = '/app/post/postdata/stock/product/category-bulk';
  static const String postStockProductPhotoDelete = '/app/post/postdata/stock/product/photo-delete';
  static const String postStockCategoryCreate = '/app/post/postdata/stock/category/create';
  static const String postStockCategoryUpdate = '/app/post/postdata/stock/category/update';
  static const String postStockTransfer = '/app/post/postdata/stock/transfer';
  static const String postStockCopyInProducts = '/app/post/postdata/stock/copy-in-products';
  static const String postStockPurchaseDelete = '/app/post/postdata/stock/purchase/delete';
  static const String postStockPurchaseDocumentEmail = '/app/post/postdata/stock/purchase-document/email';
  static const String postSupplierAdd = '/app/post/postdata/supplier/add';
  static const String postSupplierDelete = '/app/post/postdata/supplier/delete';
  static const String postStockSupplierStatementEmail = '/app/post/postdata/stock/supplier-statement/email';
  static const String postSubscriptionPackageCreate = '/app/post/postdata/subscription/package/create';
  static const String postSubscriptionPackageUpdate = '/app/post/postdata/subscription/package/update';
  static const String postSubscriptionPaymentComplete = '/app/post/postdata/subscription/payment/complete';
  static const String postSuShopUpdate = '/app/post/postdata/su/shop/update';
  static const String postTeamWaiterCreate = '/app/post/postdata/team/waiter/create';
  static const String postTeamStaffAdd = '/app/post/postdata/team/staff/add';
  static const String postTeamNonstaffAdd = '/app/post/postdata/team/nonstaff/add';
  static const String postTeamMemberUpdate = '/app/post/postdata/team/member/update';
  static const String postTeamStatusUpdate = '/app/post/postdata/team/status/update';
  static const String postTeamPermissionUpdate = '/app/post/postdata/team/permission/update';
  static const String postUploadLogo = '/app/post/postdata/upload/logo';
}
