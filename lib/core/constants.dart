import 'package:flutter/material.dart';

// مفتاح عالمي للوصول إلى ScaffoldMessenger من أي مكان في التطبيق.
// نستخدمه لإظهار رسائل SnackBar حتى لو لم نكن داخل Widget أو لم يكن لدينا BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppColors {
  // اللون الذهبي الرئيسي المستخدم في هوية تطبيق حرفتي.
  static const Color primaryGold = Color(0xFFC79A4D);

  // اللون الأزرق الداكن المستخدم غالباً في العناوين و AppBar.
  static const Color primaryDarkBlue = Color(0xFF1B2A4A);

  // لون الخلفية الافتراضي للتطبيق.
  static const Color background = Color(0xFFF8F9FA);

  // لون النجاح (مثال: تم إنشاء الطلب بنجاح).
  static const Color success = Color(0xFF4CAF50);

  // لون الخطأ (مثال: فشل تسجيل الدخول).
  static const Color error = Color(0xFFE53935);

  // لون التحذير.
  static const Color warning = Color(0xFFFF9800);
}

class AppRoutes {
  // جميع مسارات التنقل بين الشاشات.
  // بدلاً من كتابة أسماء المسارات في كل مكان داخل المشروع.

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

// إنشاء معرف موحد لغرفة الدردشة بين مستخدمين.
// الهدف: منع إنشاء غرفتي دردشة مختلفتين لنفس الشخصين.
//
// مثال:
//
// العميل:
// client123
//
// الحرفي:
// craftsman456
//
// النتيجة:
// chat_client123_craftsman456
//
// حتى لو انعكس ترتيب المعرفات ستبقى النتيجة نفسها.
String buildChatId(String id1, String id2) {
  // إنشاء قائمة تحتوي على المعرفين ثم ترتيبها.
  final ids = [id1, id2]..sort();

  // إرجاع معرف الدردشة النهائي.
  return 'chat_${ids[0]}_${ids[1]}';
}

class Professions {
  // قائمة المهن التي يمكن للحرفي اختيارها أثناء التسجيل
  // أو عند تعديل الملف الشخصي.

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
  // التصنيفات المستخدمة في البحث أو الفلترة داخل الصفحة الرئيسية.

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

// دالة عامة لإظهار SnackBar في أي مكان داخل التطبيق.
//
// message:
// النص الذي سيظهر للمستخدم.
//
// isError:
// إذا كانت true تظهر الرسالة باللون الأحمر.
// إذا كانت false تظهر الرسالة باللون الأخضر.
void showSnackBar(String message, {bool isError = false}) {
  // الوصول إلى ScaffoldMessenger عن طريق المفتاح العالمي
  // ثم طلب إظهار SnackBar.
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      // النص المعروض داخل الرسالة.
      content: Text(message),

      // إذا كانت رسالة خطأ استخدم اللون الأحمر.
      // وإلا استخدم اللون الأخضر.
      backgroundColor: isError ? AppColors.error : AppColors.success,

      // يجعل الـ SnackBar عائماً فوق الواجهة بدلاً من الالتصاق بالحافة.
      behavior: SnackBarBehavior.floating,

      // إعطاء الرسالة حواف دائرية.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
