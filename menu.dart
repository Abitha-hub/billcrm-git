import 'package:flutter/material.dart';
import 'package:billcrm/screens/home.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF337AB7);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Image.asset('assets/img/gg.png', width: 80),
                const SizedBox(height: 8),
                const Text(
                  "Invoice Me",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF337AB7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _menuTile(context, "Check In", Icons.location_pin, primaryColor, () {
            // TODO: implement Check_in_Common();
          }),
          _menuTile(context, "Home", Icons.home, primaryColor, () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePageMenu()),
            );
          }),
          _menuTile(context, "View Orders", Icons.visibility, primaryColor, () {
            // TODO: implement showMyOrders(1);
          }),
          _menuTile(context, "Settings", Icons.settings, primaryColor, () {
            // TODO: implement showSettings();
          }),
          _menuTile(context, "Sync Data", Icons.sync, primaryColor, () {
            // TODO: implement show_Offline_Contents_from_sidemenu();
          }),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
