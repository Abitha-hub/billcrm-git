import 'package:flutter/material.dart';
import 'package:billcrm/seller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:billcrm/global.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AddNewCustomerPage extends StatefulWidget {
  const AddNewCustomerPage({super.key});

  @override
  State<AddNewCustomerPage> createState() => _AddNewCustomerPageState();
}

class _AddNewCustomerPageState extends State<AddNewCustomerPage> {
  // Controllers
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
  final TextEditingController txtCoordinates = TextEditingController();


  String selectedCustomerCategory = '0';
  String selectedState = '0';
  String selectedLocation = '0';
  String selectedClassType = '0';
  File? _selectedImage;

  List<DropdownMenuItem<String>> customerCategoryItems = [];
  List<DropdownMenuItem<String>> stateItems = [];
  List<DropdownMenuItem<String>> locationItems = [];
  List<DropdownMenuItem<String>> classTypeItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _debugPrintTableData(); // call test method after widget is built
  });
/*
    customerCategoryItems = [
      const DropdownMenuItem(value: '0', child: Text('Choose Category')),
      const DropdownMenuItem(value: '1', child: Text('Bakery')),
      const DropdownMenuItem(value: '2', child: Text('Catering Company')),
      const DropdownMenuItem(value: '3', child: Text('Flour Mill')),
      const DropdownMenuItem(value: '4', child: Text('General')),
      const DropdownMenuItem(value: '5', child: Text('Grocery')),
      const DropdownMenuItem(value: '6', child: Text('Hotel')),
      const DropdownMenuItem(value: '7', child: Text('Hyper Market')),
      const DropdownMenuItem(value: '8', child: Text('Restaurant')),
      const DropdownMenuItem(value: '9', child: Text('Roastery')),
      const DropdownMenuItem(value: '10', child: Text('Ship Chandlers')),
      const DropdownMenuItem(value: '11', child: Text('Super Market')),
      const DropdownMenuItem(value: '12', child: Text('Wholesale')),
    ];

    stateItems = [
      const DropdownMenuItem(value: '0', child: Text('Select State')),
      const DropdownMenuItem(value: 'UK', child: Text('UK')),
    ];
    locationItems = [
      const DropdownMenuItem(value: '0', child: Text('Select Location')),
      const DropdownMenuItem(value: '1', child: Text('Cardif')),
      const DropdownMenuItem(value: '2', child: Text('Bristol')),
    ];
    */
    classTypeItems = [
      const DropdownMenuItem(value: '0', child: Text('Choose Class Type')),
      const DropdownMenuItem(value: '1', child: Text('Whole Sale')),
      const DropdownMenuItem(value: '2', child: Text('Retailer Price')),
    ];

    _loadStatesLocationsToCombo();
  }

Future<void> _loadStatesLocationsToCombo() async {
  try {
    final catRows = await MyAppState.getCustomerCategories();
    final stateRows = await MyAppState.getStates();

    if (!mounted) return;
    setState(() {
      customerCategoryItems = [
        const DropdownMenuItem(value: '0', child: Text('Select Category')),
        ...catRows.map((e) => DropdownMenuItem(
              value: e['cust_cat_id'].toString(),
              child: Text(e['cust_cat_name'].toString()),
            )),
      ];

      stateItems = [
        const DropdownMenuItem(value: '0', child: Text('Select State')),
        ...stateRows.map((e) => DropdownMenuItem(
              value: e['state_id'].toString(),
              child: Text(e['state_name'].toString()),
            )),
      ];

      // optional init: load all locations regardless of state
      locationItems = const [
        DropdownMenuItem(value: '0', child: Text('Select Location'))
      ];
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ERROR: $e')),
    );
  }
}

Future<void> _debugPrintTableData() async {
  MyAppState.loadLocationAndCategoryData();
();
  try {
    print('Fetching Customer Categories...');
    final catRows = await MyAppState.getCustomerCategories();
    if (catRows.isEmpty) {
      print('No customer categories found.');
    } else {
      for (var row in catRows) {
        print('Category: ${row['cust_cat_id']} - ${row['cust_cat_name']}');
      }
    }

    print('Fetching States...');
    final stateRows = await MyAppState.getStates();
    if (stateRows.isEmpty) {
      print('No states found.');
    } else {
      for (var row in stateRows) {
        print('State: ${row['state_id']} - ${row['state_name']}');
      }

      // Test locations for first state
      final firstStateId = stateRows.first['state_id'].toString();
      print('Fetching Locations for state_id = $firstStateId...');
      final locationRows = await MyAppState.getLocationsByState(firstStateId);
      if (locationRows.isEmpty) {
        print('No locations found for state $firstStateId');
      } else {
        for (var row in locationRows) {
          print('Location: ${row['location_id']} - ${row['location_name']}');
        }
      }
    }
  } catch (e) {
    print('Error while printing table data: $e');
  }
}

Future<void> pickImage() async {
  final statuses = await [Permission.camera, Permission.photos].request();

  if (statuses[Permission.camera]!.isPermanentlyDenied ||
      statuses[Permission.photos]!.isPermanentlyDenied) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Camera or gallery access is permanently denied. Please enable it from settings."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => _pickImageAndClose(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => _pickImageAndClose(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _pickImageAndClose(ImageSource source) async {
  Navigator.pop(context);
  final file = await ImagePicker().pickImage(source: source);
  if (file != null) {
    setState(() {
      _selectedImage = File(file.path); // Replace default noimage with this
    });
  }
}

Future<void> fetchLocation() async {
  // Show loading popup
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text("Fetching location..."),
        ],
      ),
    ),
  );

  try {
    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      Navigator.pop(context); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Reverse geocode
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks.first;

    if (!mounted) return;
setState(() {
  txtStreetName.text = place.street ?? '';
  txtPlace.text = place.locality ?? place.subAdministrativeArea ?? '';
  txtCoordinates.text = 'Lat: ${position.latitude}, Lng: ${position.longitude}';
});

    // Optionally print for debug
    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    print('Street: ${place.street}, Place: ${place.locality}');

  } catch (e) {
    print("Error getting location: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  } finally {
    // Close the dialog
    if (mounted) Navigator.pop(context, true);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Add New Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
  alignment: Alignment.bottomCenter,
  children: [
    _selectedImage != null
        ? Image.file(
            _selectedImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.asset(
            'assets/img/noimage.png',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
    Positioned(
      bottom: 8,
      child: GestureDetector(
        onTap: pickImage,
        child: Image.asset(
          'assets/img/Capture-icon.png',
          height: 40,
          width: 40,
        ),
      ),
    ),
  ],
),

            const SizedBox(height: 10),
            const Text(
              'CUSTOMER REGISTRATION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 35, 141, 247),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Please fill the details',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
  children: [
    Expanded(
      child: TextField(
        controller: txtCoordinates,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Location',
          hintText: 'Not Found',
          border: OutlineInputBorder(),
        ),
      ),
    ),
    const SizedBox(width: 8),
    ElevatedButton.icon(
      onPressed: () {
        fetchLocation(); // this remains the same
      },
      icon: const Icon(Icons.my_location),
      label: const Text('Get Location'),
    ),
  ],
),
            const SizedBox(height: 10),

            _buildTextField(txtStoreName, 'Customer/Store Name'),
            _buildDropdown('Customer Category', selectedCustomerCategory, customerCategoryItems,
                (value) { setState(() { selectedCustomerCategory = value;
                });
                MyAppState.getCustomerCategories();
                }),
            _buildTextField(textCustomerRegId, 'Registration ID (optional)'),
            _buildTextField(textGstTrnNumber, 'TRN/GST No. (optional)'),
            _buildTextField(txtStreetName, 'Street Name'),
            _buildTextField(txtPlace, 'Place'),
_buildDropdown('State/Province', selectedState, stateItems, (value) async {
  setState(() {
    selectedState = value;
    selectedLocation = '0';
    locationItems = const [
      DropdownMenuItem(value: '0', child: Text('Select Location')),
    ];
  });

  final locationRows = await MyAppState.getLocationsByState(value);

  setState(() {
    locationItems = [
      const DropdownMenuItem(value: '0', child: Text('Select Location')),
      ...locationRows.map((e) => DropdownMenuItem(
            value: e['location_id'].toString(),
            child: Text(e['location_name'].toString()),
          )),
    ];
  });
}),
_buildDropdown('Location', selectedLocation, locationItems, (value) {
  setState(() {
    selectedLocation = value;
  });
}),
            _buildTextField(txtEmail, 'Email Address'),
            _buildTextField(txtPhoneNumber, 'Phone Number', isNumber: true),
            _buildTextField(txtPhoneNumber2, 'Alternative Phone No.', isNumber: true),
            _buildTextArea(txtCustomerNote, 'Comments / Note'),
            _buildDropdown('Class Type', selectedClassType, classTypeItems,
                (value) => setState(() => selectedClassType = value)),
            _buildTextField(txtMaxCredit, 'Max. Credit Amount', isNumber: true),
            _buildTextField(txtMaxPeriod, 'Max. Credit Period Days', isNumber: true),
            const SizedBox(height: 20),

            ElevatedButton(
onPressed: () async {
  final now = DateTime.now();
  final sessionId = '${userId}_${now.microsecondsSinceEpoch}';
  String latitude = '', longitude = '';
  String imagePath = _selectedImage?.path ?? '';

  if (txtCoordinates.text.contains('Lat:')) {
    final parts = txtCoordinates.text.split(',');
    latitude = parts[0].split(':').last.trim();
    longitude = parts[1].split(':').last.trim();
  }

  final customerData = {
    'cust_name': txtStoreName.text.trim(),
    'cust_type': selectedClassType,
    'cust_address': txtStreetName.text.trim(),
    'cust_city': txtPlace.text.trim(),
    'cust_state': selectedState,
    'cust_country': '1',
    'cust_phone': txtPhoneNumber.text.trim(),
    'cust_phone1': txtPhoneNumber2.text.trim(),
    'cust_email': txtEmail.text.trim(),
    'cust_latitude': latitude,
    'cust_longitude': longitude,
    'cust_image': imagePath,
    'cust_note': txtCustomerNote.text.trim(),
    'max_creditamt': txtMaxCredit.text.trim(),
    'max_creditperiod': txtMaxPeriod.text.trim(),
    'cust_sessionid': sessionId,
    'cust_reg_id': textCustomerRegId.text.trim(),
    'location_id': selectedLocation,
    'cust_cat_id': selectedCustomerCategory,
    'cust_tax_reg_id': textGstTrnNumber.text.trim(),
    'timezone': DateTime.now().timeZoneName,
  };

  final connectivityResult = await Connectivity().checkConnectivity();
  final isOnline = connectivityResult != ConnectivityResult.none;

  try {
    if (isOnline) {
      final url = Uri.parse("${MyAppState.getUrl}/customer_Registration1");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': customerData}),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final result = jsonDecode(response.body);
        final parsed = result is String ? jsonDecode(result) : result;
        

        if (parsed['result'] == 'SUCCESS' || parsed['result'] == 'EXIST') {
          final customerId = parsed['customer_id'].toString();
          if (textCustomerRegId.text.isEmpty) {
            textCustomerRegId.text = customerId;
          }

          await MyAppState.saveCustomer({
            ...customerData,
            'cust_id': customerId,
            'is_new_registration': '0',
            'cust_sync_status': '1',
          });
          

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer registered online successfully!')),
          );
          return;
        } else if (parsed == 'REGID') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration ID already exists')),
          );
          return;
        }
      }

      throw Exception('Server rejected the request');
    }

    // Save offline if not online or failed
    throw Exception('No internet connection');
  } catch (e) {
    final offlineId = sessionId;
    if (textCustomerRegId.text.isEmpty) {
      textCustomerRegId.text = offlineId;
    }

    await MyAppState.saveCustomer({
      ...customerData,
      'cust_id': offlineId,
      'is_new_registration': '1',
      'cust_sync_status': '0',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer saved offline.')),
    );
  }
},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF337ab7),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Add Customer',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String selected,
      List<DropdownMenuItem<String>> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item.value == selected) ? selected : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}
