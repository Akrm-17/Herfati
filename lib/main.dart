// Firestore: قاعدة البيانات السحابية من Firebase
import 'package:cloud_firestore/cloud_firestore.dart';

// مكتبة واجهات Flutter الأساسية
import 'package:flutter/material.dart';

// تهيئة Firebase قبل تشغيل التطبيق
import 'package:firebase_core/firebase_core.dart';

// ملف إعدادات Firebase الخاص بالمشروع (يحتوي على API keys لكل منصة)
import 'package:herfatiapp/firebase_options.dart';

// التطبيق الرئيسي (واجهة التطبيق كلها)
import 'package:herfatiapp/app.dart';

// خدمة Firebase الخاصة بالمشروع (Auth + Firestore + كل الخدمات)
import 'package:herfatiapp/data/firebase_service.dart';

// خدمة الإشعارات (Push Notifications)
import 'package:herfatiapp/services/notification_service.dart';

// ==================== نقطة بداية التطبيق ====================
void main() async {
  // 🔥 مهم جدًا: يربط Flutter بمحرك النظام قبل أي async
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 تهيئة Firebase قبل استخدام أي خدمة (Auth, Firestore, Storage)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==================== إعداد Firestore ====================
  FirebaseFirestore.instance.settings = const Settings(
    // 📦 تفعيل التخزين المحلي (Offline mode)
    persistenceEnabled: true,

    // 💾 السماح بحجم كاش غير محدود
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 🌐 إعادة تفعيل الاتصال بالإنترنت مع Firestore
  await FirebaseFirestore.instance.enableNetwork();

  // ==================== تهيئة الإشعارات ====================
  try {
    // تشغيل إعدادات Firebase Messaging (Push Notifications)
    await NotificationService().initNotifications();
  } catch (e, st) {
    // في حالة فشل الإشعارات، لا نوقف التطبيق
    debugPrint('Notification initialization failed: $e');

    // طباعة Stack Trace لمعرفة مكان الخطأ
    debugPrint(st.toString());
  }

  // ==================== تجهيز خدمات التطبيق ====================

  // إنشاء كائن من خدمة FirebaseService (الطبقة التي تدير Firebase)
  final firebaseService = FirebaseService();

  // 🔐 محاولة جلب المستخدم الحالي (إذا كان مسجل دخول مسبقًا)
  final user = await firebaseService.getCurrentUser();

  // ==================== تشغيل التطبيق ====================

  runApp(
    MyApp(
      // إرسال المستخدم إلى التطبيق الرئيسي (لتحديد: يدخل مباشرة أو تسجيل دخول)
      initialUser: user,
    ),
  );
}
