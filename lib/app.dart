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
import 'package:herfatiapp/presentation/client/craftsman_profile_screen.dart'
    as client_profile;
import 'package:herfatiapp/presentation/client/home_screen.dart';
import 'package:herfatiapp/presentation/client/my_orders_screen.dart';
import 'package:herfatiapp/presentation/client/profile_screen.dart';
import 'package:herfatiapp/presentation/client/request_service_screen.dart';
import 'package:herfatiapp/presentation/craftsman/chat_screen.dart';
import 'package:herfatiapp/presentation/craftsman/home_screen.dart';
import 'package:herfatiapp/presentation/craftsman/orders_screen.dart';
import 'package:herfatiapp/presentation/craftsman/craftsman_profile_screen.dart'
    as craftsman_edit;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق حرفتي',
      theme: appTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: const Locale('ar', 'AE'),
      supportedLocales: const [
        Locale('ar', 'AE'),
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
      case AppRoutes.clientCraftsmanProfile:
        return MaterialPageRoute(
            builder: (_) =>
                const client_profile.ClientCraftsmanProfileScreen());
      case AppRoutes.clientCraftsmanDetails:
        final uri = Uri.parse(settings.name ?? '');
        final craftsmanId = settings.arguments as String? ??
            (uri.pathSegments.length >= 3 ? uri.pathSegments[2] : null) ??
            uri.queryParameters['craftsmanId'] ??
            uri.queryParameters['id'];
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
        return MaterialPageRoute(builder: (_) => const ClientChatScreen());
      case AppRoutes.clientProfile:
        return MaterialPageRoute(builder: (_) => const ClientProfileScreen());
      case AppRoutes.clientRequestService:
        return MaterialPageRoute(builder: (_) => const RequestServiceScreen());
      case AppRoutes.craftsmanHome:
        return MaterialPageRoute(builder: (_) => const CraftsmanHomeScreen());
      case AppRoutes.craftsmanProfile:
        return MaterialPageRoute(
            builder: (_) => const craftsman_edit.CraftsmanProfileEditScreen());
      case AppRoutes.craftsmanOrders:
        return MaterialPageRoute(builder: (_) => const CraftsmanOrdersScreen());
      case AppRoutes.craftsmanChat:
        return MaterialPageRoute(builder: (_) => const CraftsmanChatScreen());
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
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
