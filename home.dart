import 'package:flutter/material.dart';
import 'package:billcrm/screens/customer list.dart';
import 'package:billcrm/screens/menu.dart';

class HomePageMenu extends StatelessWidget {
  const HomePageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    
    final menuItems = <_MenuItem>[
      _MenuItem(
        title: 'Offline Entries',
        subtitle: 'Items to be synced later',
        iconPath: 'assets/img/offline.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showOfflineContents(context),
        trailingBuilder: (context) => const _OfflineCountBadge(),
      ),
      _MenuItem(
        title: 'Customers',
        subtitle: 'All operations related to Customers',
        iconPath: 'assets/img/cart.png',
        bgColor: Colors.white,
        onTap: () => showCustomers(context), // ← will open CustomerListPage
      ),
      _MenuItem(
        title: 'Pending Approvals',
        subtitle: 'Customer class changes & orders',
        iconPath: 'assets/img/underReview.jpg',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showPendingItems(context),
      ),
      _MenuItem(
        title: 'My Orders',
        subtitle: 'Track performance , Income etc.',
        iconPath: 'assets/img/order.png',
        bgColor: Colors.white,
        onTap: () => showMyOrders(context),
      ),
      _MenuItem(
        title: 'Pending Payment Clearance',
        subtitle: 'Clear Orders with Credit/Wallet balance',
        iconPath: 'assets/img/billclr.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showClearancePage(context),
      ),
      _MenuItem(
        title: 'My Activities',
        subtitle: 'Track whole activities at one place',
        iconPath: 'assets/img/activity.jpg',
        bgColor: Colors.white,
        onTap: () => showMyActivities(context),
      ),
      _MenuItem(
        title: 'Assigned Deliveries',
        subtitle: 'Orders assigned to you for delivery',
        iconPath: 'assets/img/delivered.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showAssignedDeliveryPage(context),
      ),
      _MenuItem(
        title: 'Sales Overview',
        subtitle: 'Analyse sales performance',
        iconPath: 'assets/img/single_user.png',
        bgColor: Colors.white,
        onTap: () => showSalesOverview(context),
      ),
      _MenuItem(
        title: 'Edited Orders',
        subtitle: 'View all changes made to your orders',
        iconPath: 'assets/img/edit.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showEditedOrders(context),
      ),
      _MenuItem(
        title: 'Due Payments',
        subtitle: 'Payment Dues for Delivered orders',
        iconPath: 'assets/img/pay_due.png',
        bgColor: Colors.white,
        onTap: () => showDues(context),
      ),
      _MenuItem(
        title: 'Product Overview',
        subtitle: 'Analyse brandwise business',
        iconPath: 'assets/img/fast-food-icon.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showProductOverview(context),
      ),
      _MenuItem(
        title: 'Scheduled Visits',
        subtitle: 'Follow Up date informations',
        iconPath: 'assets/img/quickly.png',
        bgColor: Colors.white,
        onTap: () => showCustFollowUps(context),
      ),
      _MenuItem(
        title: 'Stock Status',
        subtitle: 'Analyse stock',
        iconPath: 'assets/img/Stock-icon.png',
        bgColor: const Color(0xFFF9F9F9),
        onTap: () => showStock(context),
      ),
      _MenuItem(
        title: 'Manage Sales Returns',
        subtitle: 'Track sales returns',
        iconPath: 'assets/img/slrtn.jpg',
        bgColor: Colors.white,
        onTap: () => showSalesReturns(context),
      ),
    ];

return Scaffold(
  backgroundColor: Colors.white,
  appBar: AppBar(
    title: const Text('Invoice Me',style: TextStyle(
        fontSize: 16,    
        fontWeight: FontWeight.normal,
      ),),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuPage()),
          );
        },
      ),
    ],
  ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8), // was 58
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                const _Header(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  itemBuilder:
                      (context, index) => _HomePageTile(item: menuItems[index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final String iconPath;
  final Color bgColor;
  final VoidCallback onTap;
  final Widget Function(BuildContext context)? trailingBuilder;
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.bgColor,
    required this.onTap,
    this.trailingBuilder,
  });
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Image.asset('assets/img/gg.png', width: width * 0.30),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF337AB7),
              ),
              children: [
                TextSpan(text: 'Invoice Me '),
                TextSpan(
                  text: 'Salesman',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _HomePageTile extends StatelessWidget {
  final _MenuItem item;
  const _HomePageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    debugPrint('✅ HomePageMenu built');
    return Material(
      color: item.bgColor,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(item.iconPath),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              if (item.trailingBuilder != null) item.trailingBuilder!(context),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineCountBadge extends StatelessWidget {
  const _OfflineCountBadge();
  @override
  Widget build(BuildContext context) {
    const int count = 0;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

void showOfflineContents(BuildContext context) {}

void showCustomers(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CustomerListPage()),
  );
}

void showPendingItems(BuildContext context) {}
void showMyOrders(BuildContext context) {}
void showClearancePage(BuildContext context) {}
void showMyActivities(BuildContext context) {}
void showAssignedDeliveryPage(BuildContext context) {}
void showSalesOverview(BuildContext context) {}
void showEditedOrders(BuildContext context) {}
void showDues(BuildContext context) {}
void showProductOverview(BuildContext context) {}
void showCustFollowUps(BuildContext context) {}
void showStock(BuildContext context) {}
void showSalesReturns(BuildContext context) {}
