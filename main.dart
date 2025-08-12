 import 'package:flutter/material.dart';
import 'package:billcrm/screens/splash.dart';
import 'package:billcrm/global.dart';
import 'package:billcrm/seller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:async';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('💥 FlutterError: ${details.exceptionAsString()}');
  };

  runZoned(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await _initAppGlobals(); // ✅ DB & globals
      runApp(const MyApp());
    },
    onError: (Object error, StackTrace stack) {
      debugPrint('💥 Uncaught zone error: $error');
      debugPrint(stack.toString());
    },
  );
}

Future<void> _initAppGlobals() async {
  if (serverOn == "Yes") {
    getServerURL = "http://abu.billcrm.com/app_Salesman.aspx";
    imgUrl = "http://abu.billcrm.com/custimage/";
    latitude = 0.0;
    longitude = 0.0;
    androidKey = 0;
    imageYes = "0";
  } else {
    getServerURL = "http://10.0.2.2:5140/app_Salesman.aspx"; // Android Emulator
    imgUrl = "http://abu.billcrm.com/custimage/";
    latitude = 1.1;
    longitude = 1.1;
    androidKey = 111;
    imageYes = "1";
  }

  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path, 'Invoice_Me_sales_divit.db');

  db = await openDatabase(
    path,
    version: 1,
    onCreate: (Database db, int version) async {
      await MyAppState.createTables(db);
    },
  );

  debugPrint("✅ DB opened/created at $path");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillCRM',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
