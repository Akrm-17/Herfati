import 'package:flutter/material.dart';
import 'constants.dart';

// الثيم الرئيسي للتطبيق بالكامل.
// يتم ربطه عادة داخل MaterialApp عبر:
// theme: appTheme
final ThemeData appTheme = ThemeData(
  // اللون الأساسي للتطبيق
  primaryColor: AppColors.primaryGold,

  // لون الخلفية الافتراضي لجميع الشاشات (Scaffold)
  scaffoldBackgroundColor: AppColors.background,

  // الخط الافتراضي المستخدم في التطبيق بالكامل
  // يجب أن يكون الخط مضافاً في pubspec.yaml
  fontFamily: 'Cairo',

  // إعدادات AppBar الموحدة لجميع الشاشات
  appBarTheme: const AppBarTheme(
    // لون شريط التطبيق
    backgroundColor: AppColors.primaryDarkBlue,

    // لون النصوص والأيقونات داخل AppBar
    foregroundColor: Colors.white,

    // إزالة الظل أسفل AppBar
    elevation: 0,

    // جعل العنوان في المنتصف
    centerTitle: true,
  ),

  // إنشاء نظام ألوان متناسق للتطبيق انطلاقاً من اللون الذهبي
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primaryGold,

    // اللون الأساسي
    primary: AppColors.primaryGold,

    // اللون الثانوي
    secondary: AppColors.primaryDarkBlue,
  ),

  // تخصيص شكل جميع أزرار ElevatedButton داخل التطبيق
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // لون خلفية الزر
      backgroundColor: AppColors.primaryGold,

      // لون النص والأيقونات داخل الزر
      foregroundColor: Colors.white,

      // المسافات الداخلية للزر
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 24,
      ),

      // جعل حواف الزر دائرية
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // تخصيص شكل جميع TextField و TextFormField
  inputDecorationTheme: InputDecorationTheme(
    // تفعيل لون خلفية للحقل
    filled: true,

    // لون الخلفية
    fillColor: Colors.white,

    // شكل الحقل الافتراضي
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),

      // لون الحدود
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),

    // شكل الحقل عندما لا يكون محدداً
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.grey.shade300,
      ),
    ),

    // شكل الحقل عندما يضغط المستخدم بداخله
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),

      // يتحول الإطار إلى اللون الذهبي
      borderSide: const BorderSide(
        color: AppColors.primaryGold,
        width: 2,
      ),
    ),
  ),

  // تخصيص شكل جميع بطاقات Card داخل التطبيق
  cardTheme: CardThemeData(
    // مقدار الظل
    elevation: 2,

    // شكل البطاقة وحوافها
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),

    // لون البطاقة
    color: Colors.white,
  ),
);
