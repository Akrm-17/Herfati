import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';

/// ===============================
/// 🎨 GlassContainer
/// ===============================
/// فكرة هذا الـ Widget:
/// يعمل "تأثير زجاجي" (Glass Effect)
/// يستخدم في بطاقات العرض مثل:
/// - بطاقة الحرفي
/// - مربعات المعلومات
/// - واجهات جذابة شفافة
class GlassContainer extends StatelessWidget {
  final Widget child; // المحتوى الداخلي داخل البطاقة
  final double blur; // قوة الضبابية (Blur effect)
  final double opacity; // شفافية الخلفية
  final double borderRadius; // انحناء الزوايا
  final EdgeInsetsGeometry? padding; // مسافات داخلية اختيارية
  final Color? color; // لون خلفية اختياري

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10, // قيمة افتراضية للضباب
    this.opacity = 0.1, // شفافية خفيفة جدًا
    this.borderRadius = 15, // زوايا ناعمة
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // قص الزوايا بشكل دائري حسب borderRadius
      borderRadius: BorderRadius.circular(borderRadius),

      child: BackdropFilter(
        // يعمل تأثير الضباب على الخلفية فقط (وليس المحتوى)
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),

        child: Container(
          padding: padding,

          decoration: BoxDecoration(
            // إذا لم يتم تمرير لون استخدم الأبيض
            // withAlpha لتحويل الشفافية من 0..1 إلى 0..255
            color: (color ?? Colors.white).withAlpha((opacity * 255).round()),

            // نفس انحناء الزوايا
            borderRadius: BorderRadius.circular(borderRadius),

            // إطار خفيف شفاف لإظهار تأثير الزجاج
            border: Border.all(
              color: Colors.white.withAlpha((0.2 * 255).round()),
            ),
          ),

          // المحتوى الداخلي (أي Widget يتم تمريره)
          child: child,
        ),
      ),
    );
  }
}

/// ===============================
/// 🔘 CustomButton
/// ===============================
/// زر موحد في التطبيق يستخدم في:
/// - تسجيل الدخول
/// - إرسال الطلب
/// - حفظ البيانات
class CustomButton extends StatelessWidget {
  final String text; // نص الزر
  final VoidCallback? onPressed; // ماذا يحدث عند الضغط
  final bool isLoading; // حالة تحميل
  final Color? backgroundColor; // لون الخلفية
  final Color? foregroundColor; // لون النص
  final double? width; // عرض الزر
  final double height; // ارتفاع الزر
  final EdgeInsetsGeometry? padding; // الحشوة داخل الزر
  final BorderRadiusGeometry? borderRadius; // زاوية الانحناء
  final TextStyle? textStyle; // نمط النص

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 50,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? AppColors.primaryGold, // لون افتراضي
          foregroundColor: foregroundColor ?? Colors.white, // لون النص
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          minimumSize: Size(width ?? 0, height),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: textStyle ?? const TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}

/// ===============================
/// ⌨️ CustomInputField
/// ===============================
/// حقل إدخال موحد يستخدم في:
/// - تسجيل الدخول
/// - إنشاء الحساب
/// - طلب خدمة
class CustomInputField extends StatelessWidget {
  final TextEditingController controller; // التحكم بالنص
  final String label; // اسم الحقل
  final String? hint; // نص إرشادي داخل الحقل
  final IconData? prefixIcon; // أيقونة داخل الحقل
  final Widget? suffixIcon; // أيقونة اختيارية في نهاية الحقل
  final bool obscureText; // إخفاء النص (كلمة مرور)
  final TextInputType keyboardType; // نوع لوحة المفاتيح
  final int maxLines; // عدد الأسطر في الحقل
  final TextInputAction? textInputAction; // إجراء الإدخال على لوحة المفاتيح
  final String? Function(String?)? validator; // التحقق من صحة الإدخال

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction,

      decoration: InputDecoration(
        labelText: label, // اسم الحقل فوق
        hintText: hint, // نص مساعد داخل الحقل

        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon) : null, // أيقونة اختيارية
        suffixIcon: suffixIcon,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // شكل الحواف
        ),

        filled: true, // تفعيل الخلفية
        fillColor: Colors.white, // لون الخلفية
      ),

      validator: validator, // التحقق من صحة الإدخال
    );
  }
}

/// ===============================
/// ⏳ LoadingOverlay
/// ===============================
/// يستخدم عند:
/// - إرسال طلب
/// - تسجيل دخول
/// - رفع صورة
class LoadingOverlay extends StatelessWidget {
  final Widget child; // الشاشة الأساسية
  final bool isLoading; // هل يوجد تحميل؟

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // المحتوى الأساسي

        // إذا كان هناك تحميل اعرض طبقة فوق الشاشة
        if (isLoading)
          Container(
            color: Colors.black.withAlpha((0.3 * 255).round()), // تعتيم الشاشة
            child: const Center(
              child: CircularProgressIndicator(), // مؤشر تحميل
            ),
          ),
      ],
    );
  }
}

/// ===============================
/// 📭 EmptyState
/// ===============================
/// تستخدم عندما لا توجد بيانات:
/// - لا يوجد طلبات
/// - لا يوجد محادثات
/// - لا يوجد نتائج بحث
class EmptyState extends StatelessWidget {
  final String message; // رسالة للمستخدم
  final IconData icon; // أيقونة

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox, // أيقونة افتراضية
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400], // لون خفيف
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
