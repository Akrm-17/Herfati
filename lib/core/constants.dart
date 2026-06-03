import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppColors {
  static const Color primaryGold = Color(0xFFC79A4D);
  static const Color primaryDarkBlue = Color(0xFF1B2A4A);
  static const Color background = Color(0xFFF8F9FA);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
}

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String clientHome = '/client/home';
  static const String clientCraftsmanProfile = '/client/craftsman_profile';
  static const String clientCraftsmanDetails = '/client/craftsman_details';
  static const String clientMyOrders = '/client/my_orders';
  static const String clientChat = '/client/chat';
  static const String clientProfile = '/client/profile';
  static const String clientRequestService = '/client/request_service';
  static const String craftsmanHome = '/craftsman/home';
  static const String craftsmanProfile = '/craftsman/profile';
  static const String craftsmanOrders = '/craftsman/orders';
  static const String craftsmanChat = '/craftsman/chat';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminOrders = '/admin/orders';
  static const String adminReports = '/admin/reports';
  static const String craftsmanDashboard = '/craftsman/dashboard';
}

class Professions {
  static const List<String> all = [
    "كهربائي",
    "سباك",
    "نجار",
    "دهان",
    "حداد",
    "فني تكييف",
    "فني ألمنيوم",
    "عامل بناء",
    "فني جبس وديكور",
    "فني كاميرات مراقبة",
    "فني شبكات وإنترنت",
    "أخرى",
  ];
}

class Categories {
  static const List<String> all = [
    "كهربائي",
    "سباك",
    "نجار",
    "دهان",
    "حداد",
    "تكييف",
    "ألمنيوم",
    "بناء",
    "جبس وديكور",
    "كاميرات",
    "شبكات",
  ];
}

void showSnackBar(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
