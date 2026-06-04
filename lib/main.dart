import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:herfatiapp/firebase_options.dart';
import 'package:herfatiapp/app.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirebaseFirestore.instance.enableNetwork();
  try {
    await NotificationService().initNotifications();
  } catch (e, st) {
    debugPrint('Notification initialization failed: $e');
    debugPrint(st.toString());
  }

  final firebaseService = FirebaseService();
  final user = await firebaseService.getCurrentUser();
  runApp(MyApp(initialUser: user));
}
