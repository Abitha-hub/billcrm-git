import 'package:flutter/material.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  const AppNavbar({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: Image.asset('assets/img/back1.png', width: 22),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
