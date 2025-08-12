import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:billcrm/screens/customer_reg.dart';
import 'package:billcrm/seller.dart'; // for MyAppState.getUrl()

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  List<dynamic> customerList = [];
  List<dynamic> filteredList = [];
  final TextEditingController _searchController = TextEditingController();
  final List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

Future<void> loadCustomers() async {
  final url = Uri.parse('${MyAppState.getUrl()}/First_Sync');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    "user_id": "7",
    "timezone": "Arabian Standard Time",
  });

  List<Map<String, dynamic>> localCustomers = [];

  try {

    // 🔸 Call online API
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final nestedString = outer['d'];
      final nestedJson = jsonDecode(nestedString);

      final List<dynamic> apiCustomers = nestedJson['dt_customersData'] ?? [];

      // 🔸 Combine online + offline customers
      final allCustomers = [...localCustomers, ...apiCustomers];

      setState(() {
        customerList = allCustomers;
        filteredList = List.from(allCustomers);
      });
    } else {
      print('❌ Failed with status: ${response.statusCode}');
      // fallback to local
      setState(() {
        customerList = localCustomers;
        filteredList = List.from(localCustomers);
      });
    }
  } catch (e) {
    print('❌ Exception: $e');
    // fallback to local
    setState(() {
      customerList = localCustomers;
      filteredList = List.from(localCustomers);
    });
  }
}


  void filterCustomers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
  customerList = customerList;         // <- updates master list
  filteredList = List.from(customerList); // <- default to full list
});
      return;
    }
    setState(() {
      filteredList = customerList.where((cust) {
        return (cust['cust_name'] ?? '').toLowerCase().contains(q) ||
               (cust['cust_reg_id'] ?? '').toLowerCase().contains(q) ||
               (cust['cust_city'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  void onBackKeyDown() => Navigator.pop(context);

  void showCustomerRegistrationPage() {
final result = Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => AddNewCustomerPage()),
);
if (result == true) {
  loadCustomers();  // Call your method to refresh the customer list
}
  }

  void showCustomersOnMap() {
    print("Show customers on map");
  }

  Widget buildCustomerList() {
    if (filteredList.isEmpty) {
      return const Text(
        'NO CUSTOMER FOUND',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: [
        ...filteredList.asMap().entries.map((entry) {
          int i = entry.key;
          var customer = entry.value;
          bool isNew = customer['is_new_registration'] == '1';
          Color color = i % 2 == 0 ? const Color(0xFFF6F6F6) : Colors.white;

          return Container(
            color: color,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/img/Icon-store-round-150x150.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNew)
                        const Text(
                          "[NEW]",
                          style: TextStyle(color: Colors.red),
                        ),
                      Text(
                        customer['cust_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if ((customer['cust_reg_id'] ?? '').toString().isNotEmpty)
                        Text("CUSTOMER ID: ${customer['cust_reg_id']}"),
                      if ((customer['cust_tax_reg_id'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text("GSTIN: ${customer['cust_tax_reg_id']}"),
                      Text(
                        "${customer['cust_address'] ?? ''}, ${customer['cust_city'] ?? ''}",
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        title: const Text(
          "Invoice Me",
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: Image.asset('assets/img/back1.png', width: 22),
          onPressed: onBackKeyDown,
        ),
        actions: [
          IconButton(
            onPressed: () {
              print("Toggle navigation tapped");
            },
            icon: const Icon(Icons.menu, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF337ab7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    "New Customer",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  onPressed: showCustomerRegistrationPage,
                ),
              ),
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: filterCustomers,
                            style: const TextStyle(fontSize: 17),
                            decoration: InputDecoration(
                              hintText: 'Search for Customers',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFF337ab7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              filterCustomers(_searchController.text),
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF808080),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          "SELECT CUSTOMER (${filteredList.length})",
                          style: TextStyle(
                            color: Color(0xFF337ab7),
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: showCustomersOnMap,
                          icon: const Icon(
                            Icons.location_pin,
                            color: Color(0xFF337ab7),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    buildCustomerList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
