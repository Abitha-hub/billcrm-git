import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:billcrm/global.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:billcrm/screens/login.dart';
import 'package:billcrm/screens/home.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class MyAppinit extends StatefulWidget {
  const MyAppinit({super.key});

  @override
  State<MyAppinit> createState() => MyAppState();
}

class MyAppState extends State<MyAppinit> {
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(
    10.014759150281261,
    76.51599743408147,
  );
  final Set<Marker> _markers = {};
  Marker? userMarker;
@override
void initState() {
  super.initState();
   _initDatabase();
  _initUserData();
    fetchAndSyncCustomers();
    listCustomers(1); 
}
Future<void> _initUserData() async {
  if (appUserId.isEmpty) {
    await loadUserFromDB(); // Load user from local DB
  }

  await get_Customers(); // Or any function depending on appUserId
}

static Future<void> _initDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = join(dir.path, 'Invoice_Me_sales_divit.db');
  debugPrint('DB path = $path');

db = await openDatabase(
  path,
  version: 1,
  onCreate: (Database dbInstance, int version) async {
    db = dbInstance;
    await createTables(db); // <-- your custom function to create tables
  },
);
  // Even if the DB already exists, make sure tables exist (idempotent)
  await createTables(db);
}

Future<void> get_Customers() async {
  if (appUserId.isEmpty) {
    await loadUserFromDB();
  }

  // Now use appUserId safely
  final result = await db.query(
    'tbl_customer',
    where: 'user_id = ?',
    whereArgs: [appUserId],
  );
  
}

  void enableBackKey() {
    backKeyStatus = 1;
  }

  void disableBackKey() {
    backKeyStatus = 0;
  }

  static String getUrl() {
    if (getServerURL.isEmpty) {
      developer.log('🚨 getUrl() called but getServerURL is EMPTY');
    } else {
      developer.log('📡 getUrl() called → $getServerURL');
    }
    return getServerURL;
  }

  String getUrlImage() {
    return imgUrl;
  }

  // Popup management
  int isPopupShown = 0;

  void popupLoaded() {
    isPopupShown = 1;
  }

  void popupClosed() {
    isPopupShown = 0;
  }

  Future<void> fetchAndSyncCustomers() async {
    await fetchMarkersFromServer(); // From seller.dart
    await listCustomers(1); // After data is inserted
  }

  // Firebase Messaging instance
  //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  /*
  Future<void> receivedEvent(String id) async {
    // Register for push notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token (androidKey equivalent)
    _firebaseMessaging.getToken().then((token) {
      if (token != null) {
        androidKey = token.hashCode; // or store token directly if you prefer
        print("FCM Token: $token");
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final msg = message.notification!.body ?? "No message";
        debugPrint("Push Notification: $msg");
        // You can show a dialog/snackbar here
      }
    });

    // Handle background or terminated message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});

    debugPrint("Received Event: $id");
  }
*/

  static Future<void> onDeviceReady(BuildContext ctx) async {
    await _initDatabase();
    await createTables(db);

    final cnt =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tbl_appuser'),
        ) ??
        0;

    debugPrint('tbl_appuser rows = $cnt');

    final List<Map<String, dynamic>> res = await db.query('tbl_appuser');
    debugPrint('rows -> $res');

    if (res.isNotEmpty) {
      final user = res.first;
      appUserId = user['user_id'];
      dbLastUpdatedDate = user['db_last_updated_date'];
      ssUserPassword = user['password'];
      ssUserDeviceId = user['imei'];
      loginVal = '1';

      await fetchAppSettings(db);
      await countOfflineContents(db);
    } else {
      debugPrint("User not found in tbl_appuser");
      if (serverOn == "Yes") {
        await getIMEI();
      }
    }
  }

static Future<void> createTables(Database db) async {
  await db.transaction((txn) async {
    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_appuser (
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        imei TEXT NOT NULL,
        db_last_updated_date TEXT
      )
    """);

    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_system_settings (
        ss_price_change TEXT NOT NULL,
        ss_discount_change TEXT NOT NULL,
        ss_foc_change TEXT NOT NULL,
        ss_class_change TEXT NOT NULL,
        ss_max_period_credit TEXT NOT NULL,
        ss_new_registration TEXT NOT NULL,
        ss_sales_return TEXT NOT NULL,
        ss_due_amount TEXT NOT NULL,
        ss_new_item TEXT NOT NULL,
        ss_location_on_order TEXT NOT NULL,
        ss_validation_email TEXT NOT NULL,
        ss_phone TEXT NOT NULL,
        ss_direct_delivery TEXT NOT NULL,
        ss_currency TEXT NOT NULL,
        ss_decimal_accuracy TEXT NOT NULL,
        ss_multidevice_block TEXT NOT NULL,
        ss_van_based_invoice_number TEXT NOT NULL,
        ss_default_time_zone TEXT NOT NULL,
        ss_default_max_period TEXT NOT NULL,
        ss_default_max_credit TEXT NOT NULL,
        ss_reg_id_required TEXT NOT NULL,
        ss_trn_gst_required TEXT NOT NULL,
        ss_payment_type TEXT NOT NULL,
        ss_last_updated_date TEXT NOT NULL
      )
    """);
    await txn.execute('DROP TABLE IF EXISTS tbl_customer');
    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_customer (
        cust_id TEXT NOT NULL,
        cust_name TEXT NOT NULL,
        cust_address TEXT NOT NULL,
        cust_city TEXT NOT NULL,
        cust_state TEXT NOT NULL,
        cust_country TEXT NOT NULL,
        cust_phone TEXT NOT NULL,
        cust_phone1 TEXT NOT NULL,
        cust_email TEXT NOT NULL,
        cust_amount TEXT NOT NULL,
        cust_joined_date TEXT NOT NULL,
        cust_type TEXT NOT NULL,
        max_creditamt TEXT NOT NULL,
        max_creditperiod TEXT NOT NULL,
        new_custtype TEXT NOT NULL,
        new_creditamt TEXT NOT NULL,
        new_creditperiod TEXT NOT NULL,
        cust_latitude TEXT NOT NULL,
        cust_longitude TEXT NOT NULL,
        cust_image TEXT NOT NULL,
        cust_note TEXT NOT NULL,
        cust_status TEXT NOT NULL,
        cust_followup_date TEXT NOT NULL,
        cust_reg_id TEXT NOT NULL,
        location_id TEXT NOT NULL,
        cust_cat_id TEXT NOT NULL,
        cust_tax_reg_id TEXT NOT NULL,
        cust_action_type TEXT NOT NULL,
        cust_sync_status TEXT NOT NULL,
        img_updated TEXT NOT NULL,
        is_new_registration TEXT NOT NULL
      )
    """);

    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_price_master (tpm_id TEXT NOT NULL, tpm_name TEXT NOT NULL)");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_item_pricelist (tip_id TEXT NOT NULL, itbs_id TEXT NOT NULL, tpm_id TEXT NOT NULL, tip_price TEXT NOT NULL)");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_customer_category (cust_cat_id TEXT NOT NULL, cust_cat_name TEXT NOT NULL)");

    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_itembranch_stock (
        itm_type TEXT NOT NULL,
        itm_qty_per_carton TEXT NOT NULL,
        brand_name TEXT NOT NULL,
        cat_name TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        tp_tax_percentage TEXT NOT NULL,
        tp_cess TEXT NOT NULL,
        itbs_id TEXT NOT NULL,
        itm_id TEXT NOT NULL,
        itm_brand_id TEXT NOT NULL,
        itm_category_id TEXT NOT NULL,
        itm_name TEXT NOT NULL,
        itbs_stock TEXT NOT NULL,
        itm_code TEXT NOT NULL,
        itm_mrp TEXT NOT NULL,
        itm_commision TEXT NOT NULL,
        itm_rating TEXT NOT NULL,
        itbs_available TEXT NOT NULL
      )
    """);

    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_location (location_id TEXT NOT NULL, location_name TEXT NOT NULL, state_id TEXT NOT NULL, state_name TEXT NOT NULL, country_id TEXT NOT NULL)");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_branch (branch_id TEXT NOT NULL, branch_name TEXT NOT NULL, branch_timezone TEXT NOT NULL, branch_tax_method TEXT NOT NULL, branch_tax_inclusive TEXT NOT NULL, branch_prefix TEXT NOT NULL, branch_serial TEXT NOT NULL, branch_suffix TEXT NOT NULL, branch_type TEXT NOT NULL)");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_offline_check_in (rt_id TEXT NOT NULL, rt_cust_id TEXT NOT NULL, rt_checkin_type TEXT NOT NULL, rt_datetime TEXT NOT NULL, rt_lat TEXT NOT NULL, rt_lon TEXT NOT NULL, rt_sync_status TEXT NOT NULL, is_new_registration TEXT NOT NULL)");

    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_item_cart (
        itbs_id TEXT NOT NULL,
        itm_code TEXT NOT NULL,
        itm_name TEXT NOT NULL,
        si_org_price TEXT NOT NULL,
        si_price TEXT NOT NULL,
        si_qty TEXT NOT NULL,
        si_total TEXT NOT NULL,
        si_discount_rate TEXT NOT NULL,
        si_discount_amount TEXT NOT NULL,
        si_net_amount TEXT NOT NULL,
        si_foc TEXT NOT NULL,
        si_approval_status TEXT NOT NULL,
        itm_commision TEXT NOT NULL,
        itm_commisionamt TEXT NOT NULL,
        si_itm_type TEXT NOT NULL,
        si_item_tax TEXT NOT NULL,
        si_item_cess TEXT NOT NULL,
        si_tax_excluded_total TEXT NOT NULL,
        si_tax_amount TEXT NOT NULL,
        itm_type TEXT NOT NULL,
        itbs_stock TEXT NOT NULL,
        brand_name TEXT NOT NULL,
        itm_qty_per_carton TEXT NOT NULL
      )
    """);

    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_edit_cart AS SELECT * FROM tbl_item_cart WHERE 0");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_sales_items AS SELECT * FROM tbl_item_cart WHERE 0");

    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_sales_master (
        sm_id TEXT NOT NULL,
        sessionId TEXT NOT NULL,
        sm_date TEXT NOT NULL,
        sm_cash_amt TEXT NOT NULL,
        sm_wallet_amt TEXT NOT NULL,
        sm_chq_amt TEXT NOT NULL,
        sm_chq_date TEXT NOT NULL,
        sm_bank TEXT NOT NULL,
        sm_chq_no TEXT NOT NULL,
        branch_tax_method TEXT NOT NULL,
        branch_tax_inclusive TEXT NOT NULL,
        branch TEXT NOT NULL,
        sm_userid TEXT NOT NULL,
        cust_id TEXT NOT NULL,
        sm_delivery_status TEXT NOT NULL,
        sm_specialnote TEXT NOT NULL,
        sm_latitude TEXT NOT NULL,
        sm_longitude TEXT NOT NULL,
        sm_order_type TEXT NOT NULL,
        sm_payment_type TEXT NOT NULL,
        sm_total TEXT NOT NULL,
        sm_discount_rate TEXT NOT NULL,
        sm_discount_amount TEXT NOT NULL,
        sm_netamount TEXT NOT NULL,
        total_paid TEXT NOT NULL,
        total_balance TEXT NOT NULL,
        sm_tax_amount TEXT NOT NULL,
        sm_action_type TEXT NOT NULL,
        sm_sync_status TEXT NOT NULL DEFAULT '0',
        sm_type TEXT NOT NULL,
        customer_status TEXT NOT NULL,
        sm_price_class TEXT NOT NULL,
        is_new_registration TEXT NOT NULL,
        invoice_no TEXT,
        prefix TEXT,
        serial TEXT,
        suffix TEXT
      )
    """);

    await txn.execute("""
      CREATE TABLE IF NOT EXISTS tbl_transactions (
        id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        action_ref_id TEXT NOT NULL,
        partner_id TEXT NOT NULL,
        partner_type TEXT NOT NULL,
        branch_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        narration TEXT NOT NULL,
        cash_amt TEXT NOT NULL,
        wallet_amt TEXT NOT NULL,
        card_amt TEXT NOT NULL,
        card_no TEXT NOT NULL,
        cheque_amt TEXT NOT NULL,
        cheque_no TEXT NOT NULL,
        cheque_date TEXT NOT NULL,
        cheque_bank TEXT NOT NULL,
        dr TEXT NOT NULL,
        cr TEXT NOT NULL,
        date TEXT NOT NULL,
        is_reconciliation TEXT NOT NULL,
        closing_balance TEXT NOT NULL,
        trans_sync_status TEXT NOT NULL,
        is_new_registration TEXT NOT NULL
      )
    """);

    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_return_cart (sm_id TEXT NOT NULL, itbs_id TEXT NOT NULL, itm_code TEXT NOT NULL, itm_name TEXT NOT NULL, si_price TEXT NOT NULL, si_discount_rate TEXT NOT NULL, sri_qty TEXT NOT NULL, sri_total TEXT NOT NULL, sri_type TEXT NOT NULL, sri_tax_percentage TEXT NOT NULL, sri_cess TEXT NOT NULL, sri_tax_amount TEXT NOT NULL)");

    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_mynotes (msg_id TEXT NOT NULL, msg_date TEXT NOT NULL, msg_subject TEXT NOT NULL, msg_body TEXT NOT NULL)");
    await txn.execute("CREATE TABLE IF NOT EXISTS tbl_print_info (company_name TEXT NOT NULL, comp_reg_id TEXT NOT NULL, phone_numbers TEXT NOT NULL, email TEXT NOT NULL, address_line1 TEXT NOT NULL, address_line2 TEXT NOT NULL, cust_id_enabled TEXT NOT NULL, cust_tax_enabled TEXT NOT NULL, sales_phno_enabled TEXT NOT NULL, sold_by_enabled TEXT NOT NULL, branch_name_enabled TEXT NOT NULL, comp_reg_enabled TEXT NOT NULL, is_gst_trn TEXT NOT NULL)");

    debugPrint("✅ All required tables have been created.");
  });
}

  static Future<void> fetchAppSettings(Database db) async {
    try {
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT * FROM tbl_system_settings",
      );

      if (result.isNotEmpty) {
        final row = result[0];
        // Set values (replace these with your actual variable assignments)
        ss_price_change = "0";
        ss_discount_change = "0";
        ss_foc_change = "0";
        ss_class_change = "0";
        ss_max_period_credit = "0";
        ss_new_registration = "0";

        ss_sales_return = row['ss_sales_return'] ?? "0";
        ss_due_amount = "0";
        ss_new_item = row['ss_new_item'] ?? "0";
        ss_location_on_order = row['ss_location_on_order'] ?? "0";
        ss_validation_email = row['ss_validation_email'] ?? "0";
        ss_phone = row['ss_phone'] ?? "";
        ss_currency = row['ss_currency'] ?? "INR";
        ss_decimal_accuracy = row['ss_decimal_accuracy'] ?? "2";
        ss_multidevice_block = row['ss_multidevice_block'] ?? "0";
        ss_default_time_zone = row['ss_default_time_zone'] ?? "IST";
        ss_default_max_period = row['ss_default_max_period'] ?? "30";
        ss_default_max_credit = row['ss_default_max_credit'] ?? "0";
        ss_trn_gst_required = row['ss_trn_gst_required'] ?? "0";
        ss_reg_id_required = row['ss_reg_id_required'] ?? "0";
        ss_payment_type = row['ss_payment_type'] ?? "Cash";
        ss_direct_delivery = row['ss_direct_delivery'] ?? "0";

        debugPrint("App settings fetched successfully.");
      } else {
        debugPrint("No system settings found in the table.");
      }
    } catch (e) {
      debugPrint("ERROR: fetchAppSettings failed - ${e.toString()}");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  /*
Future<void> showCustomersOnMap(String currentDivId) async {
  // 1. Set map type
  setState(() {
    late GoogleMapController mapController;
    mapTypeToLoad = (currentDivId == "divCustomerList") ? 1 : 2;
  });

  // 2. Navigate to map screen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CustomerMapPage()),
  );

  // 3. If server is online
  if (serverOn == "Yes") {
    stopWatchingLocation(); // optional cleanup
    userMarker = null;
    await navigateUserOnMap(); // fetch & show user's location
  }
}*/

  void stopWatchingLocation() {
    // Stop listening to position stream
  }

  Future<void> navigateUserOnMap() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);
      showCurrentPosition(latLng);
    } else {
      // Handle permission denied permanently
      debugPrint("Location permission denied.");
    }
  }

static Future<void> loadLocationAndCategoryData() async {
  final url = Uri.parse('${MyAppState.getUrl()}/First_Sync');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    "user_id": "7",
    "timezone": "Arabian Standard Time",
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final nestedString = outer['d'];
      final nestedJson = jsonDecode(nestedString);

      final List<dynamic> locations = nestedJson['dt_locationsData'];
      final List<dynamic> categories = nestedJson['dt_customer_catData'];
      final List<dynamic> classtype = nestedJson['dt_price_master'];

      await db.delete('tbl_location');
      await db.delete('tbl_customer_category');
      await db.delete('tbl_price_master');

      for (var loc in locations) {
        await db.insert('tbl_location', {
          'location_id': loc['location_id'],
          'location_name': loc['location_name'],
          'state_id': loc['state_id'],
          'state_name': loc['state_name'],
          'country_id': loc['country_id'],
        });
      }

      for (var cat in categories) {
        await db.insert('tbl_customer_category', {
          'cust_cat_id': cat['cust_cat_id'],
          'cust_cat_name': cat['cust_cat_name'],
        });
      }

      for (var pc in classtype) {
  await db.insert('tbl_price_master', {
    'tpm_id': pc['tpm_id'],
    'tpm_name': pc['tpm_name'],
  });
}


    } else {
      print('❌ Failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception in loadLocationAndCategoryData(): $e');
  }
}

  static Future<List<Map<String, dynamic>>> getCustomerCategories() async {
  return await db.rawQuery('SELECT cust_cat_id, cust_cat_name FROM tbl_customer_category ORDER BY cust_cat_name');
}

static Future<List<Map<String, dynamic>>> getStates() async {
  return await db.rawQuery('SELECT state_id, state_name FROM tbl_location GROUP BY state_id');
}

static Future<List<Map<String, dynamic>>> getLocationsByState(String stateId) async {
  return await db.rawQuery('SELECT location_id, location_name FROM tbl_location WHERE state_id = ?', [stateId]);
}

static Future<List<Map<String, dynamic>>> getPriceClassList() async {
  return await db.rawQuery('SELECT tpm_id, tpm_name FROM tbl_price_master');
}

static Future<void> saveCustomer(Map<String, dynamic> customerData) async {
  await db.insert('tbl_customer', {
    'cust_id': customerData['cust_id'],
    'cust_name': customerData['cust_name'],
    'cust_address': customerData['cust_address'],
    'cust_city': customerData['cust_city'],
    'cust_state': customerData['cust_state'],
    'cust_country': customerData['cust_country'],
    'cust_phone': customerData['cust_phone'],
    'cust_phone1': customerData['cust_phone1'],
    'cust_email': customerData['cust_email'],
    'cust_amount': '0.00',
    'cust_joined_date': DateTime.now().toIso8601String(),
    'cust_type': customerData['cust_type'],
    'max_creditamt': customerData['max_creditamt'],
    'max_creditperiod': customerData['max_creditperiod'],
    'new_custtype': '0',
    'new_creditamt': '0',
    'new_creditperiod': '0',
    'cust_latitude': customerData['cust_latitude'],
    'cust_longitude': customerData['cust_longitude'],
    'cust_image': customerData['cust_image'],
    'cust_note': customerData['cust_note'],
    'cust_status': '1',
    'cust_followup_date': '0',
    'cust_reg_id': customerData['cust_reg_id'],
    'location_id': customerData['location_id'],
    'cust_cat_id': customerData['cust_cat_id'],
    'cust_tax_reg_id': customerData['cust_tax_reg_id'],
    'cust_action_type': '1',
    'cust_sync_status': customerData['cust_sync_status'],
    'img_updated': '0',
    'is_new_registration': customerData['is_new_registration'],
  });
      developer.log(
      "Saving customer: ${jsonEncode(customerData)}",
      name: "AddCustomerScreen",
    );
}

  void showCurrentPosition(LatLng latLng) {
    final marker = Marker(
      markerId: const MarkerId('user'),
      position: latLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'You are here'),
    );

    setState(() {
      userMarker = marker;
    });
    GoogleMapController? mapController;
    mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

static Future<Set<Marker>> fetchMarkersFromServer() async {
  final url = Uri.parse('${getUrl()}/Get_Customers');
  final userId = appUserId;
  const mapTypeToLoad = "";

  debugPrint("📡 getUrl() called → $url");
  debugPrint("📨 Sending POST to $url");
  debugPrint("📨 userId = '$userId'");

  if (userId.isEmpty) {
    debugPrint("❌ ERROR: userId is empty. Cannot fetch markers.");
    return {};
  }

  try {
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'map_type': mapTypeToLoad}),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint("📥 Response status code: ${response.statusCode}");
    debugPrint("📥 Raw response body: ${response.body}");

    if (response.statusCode != 200) {
      debugPrint("❌ Server error: ${response.statusCode}");
      return {};
    }

    final decoded = jsonDecode(response.body);
    debugPrint("✅ Decoded 'd' content: ${decoded['d']}");

    if (!decoded.containsKey('d')) {
      debugPrint("❌ Malformed server response: ${response.body}");
      return {};
    }

    final data = jsonDecode(decoded['d']);
    final dataList = data['data'];

    if (dataList == null || dataList.isEmpty) {
      debugPrint("! No customer data found in 'data' key.");
      return {};
    }

    Set<Marker> loadedMarkers = {};

    for (var customer in dataList) {
      final lat = double.tryParse(customer['cust_latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(customer['cust_longitude'].toString()) ?? 0.0;
      final custName = customer['cust_name'];
      final custId = customer['cust_id'];
      debugPrint("📌 Inserting customer $custId - $custName at ($lat, $lng)");

await db.insert('tbl_customer', {
  'cust_id': custId,
  'cust_name': customer['cust_name'] ?? '',
  'cust_address': customer['cust_address'] ?? '',
  'cust_city': customer['cust_city'] ?? '',
  'cust_state': customer['cust_state'] ?? '',
  'cust_country': customer['cust_country'] ?? '',
  'cust_phone': customer['cust_phone'] ?? '',
  'cust_phone1': customer['cust_phone1'] ?? '',
  'cust_email': customer['cust_email'] ?? '',
  'cust_amount': customer['cust_amount'] ?? '',
  'cust_joined_date': customer['cust_joined_date'] ?? '',
  'cust_type': customer['cust_type'] ?? '',
  'max_creditamt': customer['max_creditamt'] ?? '',
  'max_creditperiod': customer['max_creditperiod'] ?? '',
  'new_custtype': customer['new_custtype'] ?? '',
  'new_creditamt': customer['new_creditamt'] ?? '',
  'new_creditperiod': customer['new_creditperiod'] ?? '',
  'cust_latitude': lat.toString(),
  'cust_longitude': lng.toString(),
  'cust_image': customer['cust_image'] ?? '',
  'cust_note': customer['cust_note'] ?? '',
  'cust_status': customer['cust_status'] ?? '',
  'cust_followup_date': customer['cust_followup_date'] ?? '',
  'cust_reg_id': customer['cust_reg_id'] ?? '',
  'location_id': customer['location_id'] ?? '',
  'cust_cat_id': customer['cust_cat_id'] ?? '',
  'cust_tax_reg_id': customer['cust_tax_reg_id'] ?? '',
  'cust_action_type': customer['cust_action_type'] ?? '',
  'cust_sync_status': customer['cust_sync_status'] ?? '',
  'img_updated': customer['img_updated'] ?? '',
  'is_new_registration': '0',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final marker = Marker(
        markerId: MarkerId(custId.toString()),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: 'Customer: $custName',
          snippet: 'Tap to view',
          onTap: () {
            debugPrint('📍 Tapped customer ID: $custId');
          },
        ),
      );

      loadedMarkers.add(marker);
    }

    debugPrint("✅ Loaded ${loadedMarkers.length} markers from server.");
    return loadedMarkers;
  } catch (e) {
    debugPrint('❌ Exception while loading markers: $e');
    return {};
  }
}
static Future<List<Map<String, dynamic>>> getCustomersFromDB() async {
  final dbClient = db;
  final result = await dbClient.query('tbl_customer');
  return result;
}

  /// Counts all offline / unsynced records and updates [offlineTotalCount].
  static Future<void> countOfflineContents(Database db) async {
    ValueNotifier<int> offlineTotalCount = ValueNotifier<int>(0);
    // 1. Un-synced check-ins
    checkInCount =
        Sqflite.firstIntValue(
          await db.rawQuery('''SELECT COUNT(*) FROM tbl_offline_check_in rt
       JOIN tbl_customer cu ON cu.cust_id = rt.rt_cust_id
       WHERE rt_sync_status = '0' '''),
        ) ??
        0;

    // 2. Un-synced new customer registrations
    newRegistrationCount =
        Sqflite.firstIntValue(
          await db.rawQuery('''SELECT COUNT(*) FROM tbl_customer
       WHERE cust_sync_status = '0' '''),
        ) ??
        0;

    // 3. Un-synced credit/debit notes
    creditDebitCount =
        Sqflite.firstIntValue(
          await db.rawQuery('''SELECT COUNT(*) FROM tbl_transactions
       WHERE trans_sync_status = '0' '''),
        ) ??
        0;

    // 4. Un-synced sales orders
    newOrderCount =
        Sqflite.firstIntValue(
          await db.rawQuery('''SELECT COUNT(*) FROM tbl_sales_master sm
       JOIN tbl_customer cu ON cu.cust_id = sm.cust_id
       WHERE sm_sync_status = '0' '''),
        ) ??
        0;

    // 5. Broadcast the total so the UI can react
    final int total =
        checkInCount + newRegistrationCount + creditDebitCount + newOrderCount;
    offlineTotalCount.value = total; // <-- updates any ListenableBuilder
    // Debug log (optional)
    // ignore: avoid_print
    print(
      'Offline counts – check-in:$checkInCount '
      'newReg:$newRegistrationCount creditDebit:$creditDebitCount '
      'orders:$newOrderCount  TOTAL:$total',
    );
    ValueListenableBuilder<int>(
      valueListenable: offlineTotalCount,
      builder: (context, value, _) {
        return Text(value == 0 ? '' : '($value)');
      },
    );
  }

  Future<void> firstSync(BuildContext context, Database db) async {
    developer.log('📦 Starting firstSync()');
    overlay(
      context,
      "Loading data for the first time! This may take some time to complete",
    );
    disableBackKey();

    try {
      final url = Uri.parse("${getUrl()}/First_Sync");
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "user_id": appUserId,
              "timezone": ssDefaultTimeZone,
            }),
          )
          .timeout(Duration(seconds: 60));

      closeOverlay();
      enableBackKey();

      if (response.body.isEmpty || response.body == '""') {
        validationAlert(context, "Unable to load data! Please try again");
        return;
      }

      final data = json.decode(response.body);
      if (data == "ERROR") {
        validationAlert(context, "Invalid login details!");
        return;
      }

      final obj = json.decode(data);
      dbLastUpdatedDate = obj['sync_time'];

      // Clear all existing data
      await db.transaction((txn) async {
        await txn.delete('tbl_price_master');
        await txn.delete('tbl_item_pricelist');
        await txn.delete('tbl_customer_category');
        await txn.delete('tbl_branch');
        await txn.delete('tbl_location');
        await txn.delete('tbl_itembranch_stock');
        await txn.delete('tbl_customer');
        await txn.delete('tbl_print_info');
      });

      // Insert new data
      Batch batch = db.batch();

      for (var row in obj['dt_price_master']) {
        batch.insert('tbl_price_master', {
          'tpm_id': row['tpm_id'],
          'tpm_name': row['tpm_name'],
        });
      }

      for (var row in obj['dt_item_price']) {
        batch.insert('tbl_item_pricelist', {
          'tip_id': row['tip_id'],
          'itbs_id': row['itbs_id'],
          'tpm_id': row['tpm_id'],
          'tip_price': row['tip_price'],
        });
      }

      for (var row in obj['dt_customer_catData']) {
        batch.insert('tbl_customer_category', {
          'cust_cat_id': row['cust_cat_id'],
          'cust_cat_name': row['cust_cat_name'],
        });
      }

      for (var row in obj['dt_branchData']) {
        batch.insert('tbl_branch', row);
      }

      for (var row in obj['dt_locationsData']) {
        batch.insert('tbl_location', row);
      }

      for (var row in obj['dt_item_branchstockData']) {
        batch.insert('tbl_itembranch_stock', row);
      }

      for (var row in obj['dt_customersData']) {
        row['cust_action_type'] = '0';
        row['cust_sync_status'] = '1';
        row['img_updated'] = '0';
        row['is_new_registration'] = '0';
        batch.insert('tbl_customer', row);
      }

      for (var row in obj['dt_printData']) {
        batch.insert('tbl_print_info', row);
      }

      await batch.commit(noResult: true);
      await db.rawUpdate("UPDATE tbl_appuser SET db_last_updated_date = ?", [
        obj['sync_time'],
      ]);
    } catch (e) {
      closeOverlayImmediately();
      enableBackKey();

      await db.transaction((txn) async {
        //await txn.delete('tbl_appuser');
        //await txn.delete('tbl_system_settings');
        await txn.delete('tbl_transactions');
        await txn.delete('tbl_sales_master');
        await txn.delete('tbl_sales_items');
        await txn.delete('tbl_item_cart');
        await txn.delete('tbl_offline_check_in');
        await txn.delete('tbl_customer');
        await txn.delete('tbl_itembranch_stock');
        await txn.delete('tbl_location');
        await txn.delete('tbl_branch');
        await txn.delete('tbl_customer_category');
      });

      loginVal = '0';
      _showPage(context, LoginPage());
      validationAlert(
        context,
        "Unable to sync app data! Please re-login to app!",
      );
    }
  }

  void closeOverlay() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_dialogContext != null) {
        Navigator.of(_dialogContext!).pop();
        _dialogContext = null;
      }
    });
  }

  void closeOverlayImmediately() {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop();
      _dialogContext = null;
    }
  }

  void validationAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Text(
              '❗ $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );

Future.delayed(Duration(seconds: 2), () {
  if (mounted) {
    Navigator.of(context).pop();
  }
});

  }

  static void _showPage(BuildContext ctx, Widget page) {
    Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  BuildContext? _dialogContext;

  void overlay(BuildContext context, String message) {
    _dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void ajaxErrorAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Text(
              "⚠️ No Internet Access! Please Try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  void successAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Text(
              '✅ $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.green),
            ),
          ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context).pop();
    });
  }

  Future<bool> showConfirmDialog(BuildContext context, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ).then((value) => value ?? false); // return false if null
  }

  /*void fixQuotes(TextEditingController controller) {
  controller.text = controller.text.replaceAll(RegExp(r"['\"]"), '');
}*/

  static Future<void> getIMEI() async {
    if (serverOn == "Yes") {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      deviceId =
          androidInfo.serialNumber ?? "000000"; // deprecated in newer APIs
    } else {
      deviceId = "1234";
    }
  }
  /*
static Future<void> getAndroidId() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    String? token = await messaging.getToken();
    if (token != null) {
      androidKey = token.hashCode;
      print("Android Push Token: $token");
    }
  } catch (e) {
    print("Push Notification Error: $e");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final msg = message.notification!.body ?? "No message";
      print("Notification Received: $msg");
      // Show alert/snackbar if needed
    }
  });
}*/

  Future<void> ensureDeviceIdentifiers() async {
    // Already good? → nothing to do
    if (deviceId != null && androidKey != 0) return;

    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      deviceId = android.id; // Settings.Secure.ANDROID_ID
      androidKey = deviceId.hashCode;
    } catch (_) {
      // Very rare: device_info failed (e.g. on desktop build). Fallback to a random UUID.
      deviceId = const Uuid().v4();
      androidKey = deviceId.hashCode;
    }
  }

  String getSessionId(String salesmanId) {
    DateTime now = DateTime.now();
    String year = now.year.toString();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');

    final sessionId = "$year$month$day$hour$minute$second$salesmanId";
    return sessionId;
  }
  
Future<void> loginUserFunction(
  BuildContext context,
  String username,
  String password,
) async {
  print('▶ loginUser entered');
  print('➡ Calling URL: ${getUrl()}/Login_user');
  await ensureDeviceIdentifiers();
  print('  • deviceId=$deviceId  androidKey=$androidKey');

  if (username.isEmpty) {
    validationAlert(context, 'Please enter the username');
    return;
  }
  if (password.isEmpty) {
    validationAlert(context, 'Please enter the password');
    return;
  }
  

  final postObj = {
    'logindata': {
      'user_name': username,
      'user_password': password,
      'device_id': 'unknown',
      'android_id': '',
    },
  };
  print('  • payload → $postObj');
  overlay(context, 'Logging you in');
  disableBackKey();

  try {
    await Future.delayed(Duration(seconds: 1));
    final fullUrl = '${getUrl()}/Login_user';
    final response = await http
        .post(
          Uri.parse(fullUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(postObj),
        )
        .timeout(const Duration(seconds: 25));
    print("🔁 Status: ${response.statusCode}");
  print("📦 Raw Response: ${response.body}");

try {
  final decoded = jsonDecode(response.body);
    final data = jsonDecode(decoded["d"]);
    
  print("✅ login_data: ${data['login_data']}");
  print("✅ settings_data: ${data['settings_data']}");
} catch (e) {
  print("❌ JSON decode failed: $e");
  
  validationAlert(context, "Invalid server response. Please try again later.");
  return;
}

    closeOverlayImmediately();
    enableBackKey();

    print('🔁 Response.body: ${response.body}'); // ✅ added for debugging

    final Map<String, dynamic> body = jsonDecode(response.body);
    final String rawData = body['d'];

    if (rawData == '') {
      validationAlert(context, 'Unable to login! Please try again.');
      return;
    }
    if (rawData == 'BLOCKED') {
      validationAlert(context, 'This device is not authorized! Contact Admin.');
      return;
    }
    if (rawData == 'NOTEXIST') {
      validationAlert(context, 'Invalid login details!');
      return;
    }

    // 🔥 Decode the nested JSON string from API
    final Map<String, dynamic> parsedData = jsonDecode(rawData);
    final Map<String, dynamic> user = parsedData['login_data'][0];
    final Map<String, dynamic> settings = parsedData['settings_data'][0];

    print('✅ Login Successful!');
    print('👤 User ID: ${user['user_id']}');
    print('🧑 Name: ${user['name']}');
    print('⚙️ Settings: $settings');

    await db.transaction((txn) async {
      await txn.delete('tbl_appuser');
      await txn.delete('tbl_system_settings');

      await txn.insert('tbl_appuser', {
        'user_id': user['user_id'].toString(),
        'name': user['name'],
        'password': user['password'].toString(),
        'imei': deviceId,
        'db_last_updated_date': '0',
      });
      debugPrint('✅ Inserted into tbl_appuser');

      await txn.insert('tbl_system_settings', {
        'ss_price_change': settings['ss_price_change'],
        'ss_discount_change': settings['ss_discount_change'],
        'ss_foc_change': settings['ss_foc_change'],
        'ss_class_change': settings['ss_class_change'],
        'ss_max_period_credit': settings['ss_max_period_credit'],
        'ss_new_registration': settings['ss_new_registration'],
        'ss_sales_return': settings['ss_sales_return'],
        'ss_due_amount': settings['ss_due_amount'],
        'ss_payment_type': settings['ss_payment_type'],
        'ss_new_item': settings['ss_new_item'],
        'ss_location_on_order': settings['ss_location_on_order'],
        'ss_validation_email': settings['ss_validation_email'],
        'ss_phone': settings['ss_phone'],
        'ss_direct_delivery': settings['ss_direct_delivery'],
        'ss_currency': settings['ss_currency'],
        'ss_decimal_accuracy': settings['ss_decimal_accuracy'],
        'ss_multidevice_block': settings['ss_multidevice_block'],
        'ss_van_based_invoice_number': settings['ss_van_based_invoice_number'],
        'ss_default_time_zone': settings['ss_default_time_zone'],
        'ss_default_max_period': settings['ss_default_max_period'],
        'ss_default_max_credit': settings['ss_default_max_credit'],
        'ss_reg_id_required': settings['ss_reg_id_required'],
        'ss_trn_gst_required': settings['ss_trn_gst_required'],
        'ss_last_updated_date': settings['ss_last_updated_date'],
      });
      debugPrint('✅ Inserted into tbl_system_settings');

      final rows = await txn.query('tbl_appuser');
      debugPrint('📦 tbl_appuser rows: ${rows.length}');
      debugPrint('📦 Row data: $rows');
    });

    // Cache globals
    appUserId = user['user_id'].toString();
    ssUserPassword = user['password'].toString();
    ssUserDeviceId = deviceId!;
    dbLastUpdatedDate = '0';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    debugPrint("✅ Login flag saved: ${prefs.getBool('isLoggedIn')}");

    await fetchAppSettings(db);
    await firstSync(context, db);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePageMenu()),
      (_) => false,
    );
  } catch (e, st) {
    developer.log('❌ loginUserFunction failed: $e', stackTrace: st);
    closeOverlayImmediately();
    enableBackKey();

    if (e is SocketException) {
      validationAlert(context, "No internet connection. Please try again.");
    } else {
      ajaxErrorAlert(context);
    }
  }
}


Future<void> loadUserFromDB() async {
  List<Map<String, dynamic>> rows = await db.query('tbl_appuser');
  if (rows.isNotEmpty) {
    appUserId = rows.first['user_id'].toString();
    debugPrint('🔁 Loaded user from db: $appUserId');
  } else {
    debugPrint('⚠️ No user in tbl_appuser');
  }
}

  Future<void> logoutUser(BuildContext context) async {
    await db.transaction((txn) async {
      final checkInData = await txn.query(
        'tbl_offline_check_in',
        where: "rt_sync_status='0'",
      );
      final custData = await txn.query(
        'tbl_customer',
        where: "cust_sync_status='0'",
      );
      final transData = await txn.query(
        'tbl_transactions',
        where: "trans_sync_status='0'",
      );
      final salesMaster = await txn.query(
        'tbl_sales_master',
        where: "sm_sync_status='0'",
      );

      if (checkInData.isEmpty &&
          custData.isEmpty &&
          transData.isEmpty &&
          salesMaster.isEmpty) {
        final result = await showConfirmDialog(
          context,
          'Are you sure to logout?',
        );
        if (result) {
          await db.transaction((txn) async {
            await txn.delete('tbl_appuser');
            await txn.delete('tbl_system_settings');
            await txn.delete('tbl_transactions');
            await txn.delete('tbl_sales_master');
            await txn.delete('tbl_sales_items');
            await txn.delete('tbl_item_cart');
            await txn.delete('tbl_offline_check_in');
            await txn.delete('tbl_customer');
            await txn.delete('tbl_itembranch_stock');
            await txn.delete('tbl_location');
            await txn.delete('tbl_branch');
            await txn.delete('tbl_customer_category');
            await txn.delete('tbl_price_master');
            await txn.delete('tbl_item_pricelist');
          });

          _showPage(context, LoginPage());
        }
      } else {
        //showOfflineContents();
        validationAlert(
          context,
          "Please sync the offline contents & try again!",
        );
      }
    });
  }

  Future<void> showCustomerRegistrationPage() async {
    final PageController pageController = PageController();
    pageController.jumpToPage(1); // Replace with actual index

    setState(() {
      customerActionLabel = 'CUSTOMER REGISTRATION\nPlease fill the details';
      isUpdateButtonVisible = false;
      isRegisterButtonVisible = true;

      // Show credit‑class section.
      showCreditClassSection = true;

      // Pre‑fill credit/period fields with default values.
      txtMaxCreditController.text = defaultMaxCreditController.text;
      txtMaxPeriodController.text = defaultMaxPeriodController.text;

      // Clear any previous data in the form.
      clearRegistrationFields();
    });

    // 3️⃣  Fetch or generate a new session ID.
    getSessionId(salesmanId);

    // 4️⃣  Load dropdowns / combos.
    await _loadStatesLocationsToCombo();
    await _loadPriceGroups('selCusType');
  }

  Future<void> listCustomers(int page) async {
    disableBackKey();
    final lowerBound = (page - 1) * perPage;

    String search = searchController.text.trim();
    String whereClause = '';
    List<dynamic> args = [];

    if (search.isNotEmpty) {
      whereClause = '''
      WHERE cust_name LIKE ? OR
            cust_address LIKE ? OR
            cust_city LIKE ? OR
            cust_id LIKE ?
    ''';
      String likeQuery = '%$search%';
      args = [likeQuery, likeQuery, likeQuery, likeQuery];
    }

    // Count total rows
    final countRes = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tbl_customer $whereClause',
      args,
    );

    totalRows = Sqflite.firstIntValue(countRes) ?? 0;
    totalPages = (totalRows / perPage).ceil();
    setState(() {}); // To update label count etc.

    // Fetch paginated customer list
    final result = await db.rawQuery('''
    SELECT cust_id, cust_name, cust_address, cust_city,
           cust_reg_id, cust_tax_reg_id, is_new_registration
    FROM tbl_customer
    $whereClause
    ORDER BY cust_name ASC
    LIMIT $perPage OFFSET $lowerBound
    ''', args);

    customerList = result;
    currentPage = page;
    setState(() {}); // To rebuild UI
    enableBackKey();
  }

  void clearRegistrationFields() {
    isImageExist = false;
    imageURIN = null;
    imageURIUp = null;
    imageYes = "0";
    imageYesUp = "0";

    txtStoreNameController.text = '';
    gstNumberController.text = '';
    customerRegIdController.text = '';
    selectedCustomerCategory = '0';

    streetNameController.text = '';
    placeController.text = '';
    phoneNumberController.text = '';
    phoneNumber2Controller.text = '';
    selectedStateId = '0';
    selectedLocationId = '0';

    emailController.text = '';
    selectedCustomerType = '0';
    txtMaxCreditController.text = '';
    txtMaxPeriodController.text = '';
    customerNoteController.text = '';
    newCustomerLocation = 'Not Found';

    customerImagePath = 'assets/img/noimage.png';

    Latitude = 0.0;
    Longitude = 0.0;
  }

  Future<void> _loadStatesLocationsToCombo() async {
    try {
      final database = db; // From global.dart

      final List<Map<String, dynamic>> catRows = await database.rawQuery(
        'SELECT cust_cat_id, cust_cat_name FROM tbl_customer_category ORDER BY cust_cat_name',
      );

      final List<Map<String, dynamic>> stateRows = await database.rawQuery(
        'SELECT state_id, state_name FROM tbl_location GROUP BY state_id',
      );

      if (!mounted) return;
      setState(() {
        customerCategoryItems = [
          const DropdownMenuItem(value: '0', child: Text('choose category')),
          ...catRows.map(
            (e) => DropdownMenuItem(
              value: e['cust_cat_id'].toString(),
              child: Text(e['cust_cat_name'].toString()),
            ),
          ),
        ];

        stateItems = [
          const DropdownMenuItem(value: '0', child: Text('Select State')),
          ...stateRows.map(
            (e) => DropdownMenuItem(
              value: e['state_id'].toString(),
              child: Text(e['state_name'].toString()),
            ),
          ),
        ];

        selectedCustomerCategory = '0';
        selectedStateId = '0';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('ERROR: $e')));
    }
  }

  Future<void> _loadPriceGroups(String dropdownId) async {
    try {
      final database = db; // from global.dart
      final List<Map<String, dynamic>> result = await database.rawQuery(
        'SELECT tpm_id, tpm_name FROM tbl_price_master',
      );

      List<DropdownMenuItem<String>> priceGroupItems = [
        const DropdownMenuItem(value: '0', child: Text('choose class type')),
        ...result.map(
          (row) => DropdownMenuItem(
            value: row['tpm_id'].toString(),
            child: Text(row['tpm_name'].toString()),
          ),
        ),
      ];

      if (!mounted) return;

      setState(() {
        if (dropdownId == 'selCusType') {
          priceGroupDropdownItems = priceGroupItems;
          selectedPriceGroup = '0';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Error loading price groups: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Me',
      home: Scaffold(
        appBar: AppBar(title: Text('Invoice Me')),
        body: Center(child: Text('Welcome to Invoice Me App')),
      ),
    );
  }
}
