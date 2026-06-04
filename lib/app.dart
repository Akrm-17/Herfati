import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/themes.dart';
import 'package:herfatiapp/presentation/admin/dashboard_screen.dart';
import 'package:herfatiapp/presentation/admin/orders_screen.dart';
import 'package:herfatiapp/presentation/admin/reports_screen.dart';
import 'package:herfatiapp/presentation/admin/users_screen.dart';
import 'package:herfatiapp/presentation/auth/login_screen.dart';
import 'package:herfatiapp/presentation/auth/signup_screen.dart';
import 'package:herfatiapp/presentation/client/chat_screen.dart';
import 'package:herfatiapp/presentation/client/craftsman_details_screen.dart';
import 'package:herfatiapp/presentation/client/craftsman_profile_screen.dart';
import 'package:herfatiapp/presentation/client/home_screen.dart';
import 'package:herfatiapp/presentation/client/my_orders_screen.dart';
import 'package:herfatiapp/presentation/client/profile_screen.dart';
import 'package:herfatiapp/presentation/client/request_service_screen.dart';
import 'package:herfatiapp/presentation/craftsman/chat_screen.dart'
    as craftsman_chat;
import 'package:herfatiapp/presentation/craftsman/home_screen.dart'
    as craftsman_home;
import 'package:herfatiapp/presentation/craftsman/orders_screen.dart'
    as craftsman_orders;
import 'package:herfatiapp/presentation/craftsman/craftsman_profile_screen.dart'
    as craftsman_edit;

import 'package:herfatiapp/data/models.dart' as app_models;

class MyApp extends StatelessWidget {
  final app_models.User? initialUser;

  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق حرفتي',
      theme: appTheme,
      initialRoute: initialUser != null
          ? (initialUser!.role == app_models.UserRole.client
              ? AppRoutes.clientHome
              : AppRoutes.craftsmanHome)
          : AppRoutes.login,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: const Locale("ar", "AE"),
      supportedLocales: const [
        Locale("ar", "AE"),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';
    const craftsmanDetailsPrefix = '/client/craftsman_details/';

    if (routeName.startsWith(craftsmanDetailsPrefix)) {
      final craftsmanId = routeName.substring(craftsmanDetailsPrefix.length);
      return MaterialPageRoute(
        builder: (_) => CraftsmanDetailsScreen(craftsmanId: craftsmanId),
      );
    }

    switch (routeName) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case AppRoutes.clientHome:
        return MaterialPageRoute(builder: (_) => const ClientHomeScreen());
      case AppRoutes.clientCraftsmanDetails:
        final craftsmanId = settings.arguments as String?;
        if (craftsmanId == null || craftsmanId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("خطأ")),
              body: const Center(child: Text('لم يتم استلام معرف الحرفي')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CraftsmanDetailsScreen(craftsmanId: craftsmanId),
        );
      case AppRoutes.clientMyOrders:
        return MaterialPageRoute(builder: (_) => const MyOrdersScreen());
      case AppRoutes.clientChat:
        // ✅ تمرير المعاملات عبر settings
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ClientChatScreen(),
        );
      case AppRoutes.clientProfile:
        return MaterialPageRoute(builder: (_) => const ClientProfileScreen());
      case AppRoutes.clientRequestService:
        final craftsmanId = settings.arguments as String?;
        if (craftsmanId == null || craftsmanId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("خطأ")),
              body: const Center(child: Text('لم يتم استلام معرف الحرفي')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => RequestServiceScreen(craftsmanId: craftsmanId),
        );
      case AppRoutes.clientCraftsmanProfile:
        return MaterialPageRoute(
          builder: (_) => const ClientCraftsmanProfileScreen(),
        );
      case AppRoutes.craftsmanHome:
        return MaterialPageRoute(
            builder: (_) => const craftsman_home.CraftsmanHomeScreen());
      case AppRoutes.craftsmanDashboard:
        return MaterialPageRoute(
            builder: (_) => const craftsman_home.CraftsmanHomeScreen());
      case AppRoutes.craftsmanProfile:
        return MaterialPageRoute(
            builder: (_) => const craftsman_edit.CraftsmanProfileEditScreen());
      case AppRoutes.craftsmanOrders:
        return MaterialPageRoute(
            builder: (_) => const craftsman_orders.CraftsmanOrdersScreen());
      case AppRoutes.craftsmanChat:
        // ✅ تمرير المعاملات أيضاً لشاشة دردشة الحرفي
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const craftsman_chat.CraftsmanChatScreen(),
        );
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case AppRoutes.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
      case AppRoutes.adminOrders:
        return MaterialPageRoute(builder: (_) => const AdminOrdersScreen());
      case AppRoutes.adminReports:
        return MaterialPageRoute(builder: (_) => const AdminReportsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(routeName: routeName),
        );
    }
  }
}

class NotFoundScreen extends StatelessWidget {
  final String? routeName;

  const NotFoundScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة غير موجودة'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 100,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                '404 - الصفحة غير موجودة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                routeName != null && routeName!.isNotEmpty
                    ? 'المسار "$routeName" غير معرّف. يرجى التحقق والمحاولة مرة أخرى.'
                    : 'المسار غير معرّف. يرجى العودة إلى الصفحة الرئيسية.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('عودة إلى الصفحة الرئيسية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
