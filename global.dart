import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';

late Database db;  
String serverOn = "Yes"; // Use "No" for offline testing
int testMode = 0; // 0 for off, 1 for on
String lowAccuVal = "No"; // Use "Yes" if needed
late String getServerURL;
late String imgUrl;
double Latitude = 0.0;
double Longitude = 0.0;
dynamic androidkey = 0; // Can be int or String
String imageYes = "";
String salesmanId = '';

String? imageURIN;

double latitude = 0.0;
double longitude = 0.0;

String? deviceId;
int     androidKey = 0;
int uniLocType = 0;
int uniPopup = 0;
int currentSessionId = 0;
int backCount = 0;
int itmQtyPerCarton = 1;

int backKeyStatus = 1; // 1 - enabled, 0 - disabled

// Page stack placeholder
List<String> pageStack = [];
// System setting variables
String ss_price_change = "0";
String ss_discount_change = "0";
String ss_foc_change = "0";
String ss_class_change = "0";
String ss_max_period_credit = "0";
String ss_new_registration = "0";
String ss_sales_return = "0";
String ss_due_amount = "0";
String ss_new_item = "0";
String ss_location_on_order = "0";
String ss_validation_email = "0";
String ss_phone = "";
String ss_currency = "INR";
String ss_decimal_accuracy = "2";
String ss_multidevice_block = "0";
String ss_default_time_zone = "IST";
String ss_default_max_period = "30";
String ss_default_max_credit = "0";
String ss_trn_gst_required = "0";
String ss_reg_id_required = "0";
String ss_payment_type = "Cash";
String ss_direct_delivery = "0";

// Required global variables for First_Sync

String appUserId = "";
String ssDefaultTimeZone = "";
String dbLastUpdatedDate = "";
String loginVal = "0";
String ssUserPassword = "";
String ssUserDeviceId = "";

String getUrl() => "http://abu.billcrm.com/app_Salesman.aspx";
const String imageBaseUrl = "http://abu.billcrm.com/custimage/";

int checkInCount         = 0;
int newRegistrationCount = 0;
int creditDebitCount     = 0;
int newOrderCount        = 0;

late final PageController _pageController;
late final TextEditingController txtMaxCreditController;
late final TextEditingController txtMaxPeriodController;
late final TextEditingController defaultMaxCreditController;
late final TextEditingController defaultMaxPeriodController;

late String customerActionLabel;
late bool isUpdateButtonVisible;
late bool isRegisterButtonVisible;
late bool showCreditClassSection;
bool isImageExist = false;
String? imageURIUp;
String imageYesUp = "0";
String newCustomerLocation = 'Not Found';
String customerImagePath = 'assets/img/noimage.png';

// Controllers
final TextEditingController txtStoreNameController = TextEditingController();
final TextEditingController gstNumberController = TextEditingController();
final TextEditingController customerRegIdController = TextEditingController();
final TextEditingController streetNameController = TextEditingController();
final TextEditingController placeController = TextEditingController();
final TextEditingController phoneNumberController = TextEditingController();
final TextEditingController phoneNumber2Controller = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController customerNoteController = TextEditingController();

// Dropdown values
String selectedCustomerCategory = '0';
String selectedStateId = '0';
String selectedLocationId = '0';
String selectedCustomerType = '0';
List<DropdownMenuItem<String>> customerCategoryItems = [];
List<DropdownMenuItem<String>> stateItems            = [];
Future<Database> getDB() async => db;
List<DropdownMenuItem<String>> priceGroupDropdownItems = [];
String selectedPriceGroup = '0';
  final TextEditingController txtStoreName = TextEditingController();
  final TextEditingController textCustomerRegId = TextEditingController();
  final TextEditingController textGstTrnNumber = TextEditingController();
  final TextEditingController txtStreetName = TextEditingController();
  final TextEditingController txtPlace = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPhoneNumber = TextEditingController();
  final TextEditingController txtPhoneNumber2 = TextEditingController();
  final TextEditingController txtCustomerNote = TextEditingController();
  final TextEditingController txtMaxCredit = TextEditingController();
  final TextEditingController txtMaxPeriod = TextEditingController();

  String selectedState = '0';
  String selectedLocation = '0';
  String selectedClassType = '0';
bool _isLoading = true;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
int currentPage = 1;
int totalRows = 0;
int totalPages = 1;
int perPage = 15;

List<Map<String, dynamic>> customerList = [];
TextEditingController searchController = TextEditingController();
String mapTypeToLoad = 'normal';
String custId = '';
String custName = '';
List<Map<String, dynamic>> _customerList = [];
final userId = appUserId;
List<dynamic> locationList = [];
List<dynamic> categoryList = [];