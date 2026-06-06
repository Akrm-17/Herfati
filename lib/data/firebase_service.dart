import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/models.dart' as app_models;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class FirebaseService {
  // خدمة Firebase الرئيسية التي تتعامل مع المصادقة، قاعدة البيانات، التخزين والإشعارات.
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // مرجع Firestore للوصول إلى مجموعات المستندات والقراءة/الكتابة عليها.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // مرجع Firebase Messaging لإدارة رموز الأجهزة وإرسال الإشعارات.
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // مفتاح خادم FCM المأخوذ من متغير بيئة لتأمين إرسال الإشعارات.
  final String _fcmServerKey = const String.fromEnvironment('FCM_SERVER_KEY');

  // ==================== AUTH ====================
  Future<app_models.User?> signInWithEmail(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _getUserById(result.user!.uid);
      // بعد تسجيل الدخول بنجاح، نحفظ رمز الجهاز للقدرة على إرسال إشعارات
      if (user != null) {
        _saveDeviceToken(user.id);
      }
      return user;
    } on auth.FirebaseAuthException catch (e) {
      String message = e.code == 'user-not-found' || e.code == 'wrong-password'
          ? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.'
          : e.message ?? 'فشل تسجيل الدخول';
      showSnackBar(message, isError: true);
      return null;
    } catch (e) {
      showSnackBar('خطأ: ${e.toString()}', isError: true);
      return null;
    }
  }

  Future<app_models.User?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? profession,
    int? yearsOfExperience,
    String? city,
    String? bio,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = app_models.User(
        id: result.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone,
        role: app_models.UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == role,
        ),
        createdAt: Timestamp.now(),
        isActive: true,
      );
      await _firestore.collection('users').doc(user.id).set(user.toJson());

      // إذا كان المستخدم حرفيًا، ننشئ مستندًا خاصًا بالحرفيين لتخزين بياناتهم المتخصصة.
      if (role == 'craftsman') {
        final craftsman = app_models.Craftsman(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          phone: user.phone,
          createdAt: user.createdAt,
          isActive: user.isActive,
          profession: profession!,
          yearsOfExperience: yearsOfExperience!,
          city: city!,
          bio: bio!,
          skills: [],
          rating: 0.0,
          totalOrders: 0,
          totalReviews: 0,
          portfolioImages: [],
        );
        await _firestore
            .collection("craftsmen")
            .doc(craftsman.id)
            .set(craftsman.toJson());
      }
      _saveDeviceToken(user.id);
      return user;
    } on auth.FirebaseAuthException catch (e) {
      String message = e.code == 'email-already-in-use'
          ? 'البريد مستخدم بالفعل'
          : e.message ?? 'فشل إنشاء الحساب';
      showSnackBar(message, isError: true);
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _removeDeviceToken();
    showSnackBar('تم تسجيل الخروج');
  }

  Future<app_models.User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final appUser = await _getUserById(user.uid);
    if (appUser != null) {
      _saveDeviceToken(appUser.id);
    }
    return appUser;
  }

  Future<app_models.User?> _getUserById(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return app_models.User.fromJson(doc.data()!);
  }

  Future<app_models.User?> getUserById(String uid) => _getUserById(uid);

  Future<void> _saveDeviceToken(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _firestore.collection("users").doc(userId).update({
        'deviceToken': token,
      });
    }
  }

  Future<void> _removeDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection("users").doc(userId).update({
          'deviceToken': FieldValue.delete(),
        });
      }
    }
  }

  Future<String?> getDeviceToken(String userId) async {
    final doc = await _firestore.collection("users").doc(userId).get();
    if (doc.exists) {
      return doc.data()?["deviceToken"];
    }
    return null;
  }

  Future<void> updateDeviceTokenForCurrentUser(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'deviceToken': token,
      });
    }
  }

  // يرسل إشعارًا عبر خدمة FCM باستخدام مفتاح الخادم وطلب HTTP.
  Future<bool> _sendFcmNotification(
    String token,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    if (_fcmServerKey.isEmpty) {
      log('FCM server key not configured. Skipping remote notification.');
      return false;
    }

    final payload = jsonEncode({
      'to': token,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...?data,
      },
    });

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_fcmServerKey',
      },
      body: payload,
    );

    if (response.statusCode == 200) {
      log('FCM notification sent successfully.');
      return true;
    }

    log('FCM notification failed: ${response.statusCode} ${response.body}');
    return false;
  }

  Future<void> sendFcmNotificationToUser(
    String recipientId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    final recipientToken = await getDeviceToken(recipientId);
    if (recipientToken == null) {
      log('No device token for recipient $recipientId.');
      return;
    }
    await _sendFcmNotification(recipientToken, title, body, data: data);
  }

  Future<void> sendOrderNotification(
    String recipientId,
    String title,
    String body, {
    String? orderId,
  }) async {
    await sendFcmNotificationToUser(recipientId, title, body, data: {
      if (orderId != null) 'orderId': orderId,
      'type': 'order',
    });
  }

  // ==================== CRAFTSMAN ====================
  // دوال استرجاع وتحديث ملف الحرفي في Firestore.
  Future<app_models.Craftsman?> getCraftsmanProfile(String id) async {
    final doc = await _firestore.collection('craftsmen').doc(id).get();
    if (!doc.exists) return null;
    return app_models.Craftsman.fromJson(doc.data()!);
  }

  Future<void> updateCraftsman(app_models.Craftsman craftsman) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('craftsmen').doc(craftsman.id),
        craftsman.toJson());
    batch.update(_firestore.collection('users').doc(craftsman.id), {
      'name': craftsman.name,
      'email': craftsman.email,
      'phone': craftsman.phone,
      'profileImage': craftsman.profileImage,
    });
    await batch.commit();
    showSnackBar('تم تحديث الملف الشخصي');
  }

  // يعيد الحرفيين الأعلى تقييماً لعرضهم في قسم التوصيات.
  Future<List<app_models.Craftsman>> getRecommendedCraftsmen(
      {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('craftsmen')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((d) => app_models.Craftsman.fromJson(d.data()))
        .toList();
  }

  // يعيد الحرفيين حسب التخصص المحدد مع التحقق من أنهم نشطون.
  Future<List<app_models.Craftsman>> getCraftsmenByCategory(
      String category) async {
    final snapshot = await _firestore
        .collection('craftsmen')
        .where('profession', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((d) => app_models.Craftsman.fromJson(d.data()))
        .toList();
  }

  // يسترجع جميع الطلبات المرتبطة بالعميل مرتبة حسب الأحدث.
  // ==================== CLIENT ORDERS ====================
  Future<List<app_models.Order>> getClientOrders(String clientId) async {
    final snapshot = await _firestore
        .collection('orders')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => app_models.Order.fromJson(d.data()))
        .toList();
  }

  // ==================== STATISTICS FOR CRAFTSMAN ====================
  Future<Map<app_models.OrderStatus, int>> getCraftsmanStatistics(
      String craftsmanId) async {
    final orders = await _firestore
        .collection('orders')
        .where('craftsmanId', isEqualTo: craftsmanId)
        .get();
    final Map<app_models.OrderStatus, int> stats = {};
    for (var doc in orders.docs) {
      final statusStr = doc.data()['status'] as String;
      final status = app_models.OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusStr,
        orElse: () => app_models.OrderStatus.pending,
      );
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  // دفق الطلبات الخاص بالحرفي حتى يتم تحديث واجهة المستخدم في الوقت الحقيقي.
  // ==================== ORDERS (Stream) ====================
  Stream<List<app_models.Order>> streamCraftsmanOrders(String craftsmanId) {
    return _firestore
        .collection('orders')
        .where('craftsmanId', isEqualTo: craftsmanId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  Future<app_models.Order> createOrder(app_models.Order order) async {
    final docRef = _firestore.collection('orders').doc();
    final orderWithId = order.copyWith(id: docRef.id);
    await docRef.set(orderWithId.toJson());
    return orderWithId;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': status});
  }

  // ==================== ADMIN HELPERS ====================
  Future<int> getUsersCount() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<List<app_models.User>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => app_models.User.fromJson(
              doc.data(),
              id: doc.id,
            ))
        .toList();
  }

  Future<int> getCraftsmenCount() async {
    final snapshot = await _firestore.collection('craftsmen').get();
    return snapshot.docs.length;
  }

  Future<int> getOrdersCount() async {
    final snapshot = await _firestore.collection('orders').get();
    return snapshot.docs.length;
  }

  Future<double> getCompletedOrdersRevenue() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();
    double revenue = 0.0;
    for (var doc in snapshot.docs) {
      final price = doc.data()['price'];
      revenue += price is num ? price.toDouble() : 0.0;
    }
    return revenue;
  }

  Stream<List<app_models.User>> streamUsersByRole(String role) {
    final normalizedRole = role.toLowerCase();
    final capitalizedRole = role.isNotEmpty
        ? '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}'
        : role;
    final roleVariants = {
      normalizedRole,
      capitalizedRole,
      'UserRole.$role',
    }.toList();

    return _firestore
        .collection('users')
        .where('role', whereIn: roleVariants)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.User.fromJson(
                  doc.data(),
                  id: doc.id,
                ))
            .toList());
  }

  Stream<List<app_models.User>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => app_models.User.fromJson(doc.data(), id: doc.id))
        .toList());
  }

  Stream<List<app_models.Craftsman>> streamAllCraftsmen() {
    return _firestore
        .collection('craftsmen')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Craftsman.fromJson(
                  doc.data(),
                  id: doc.id,
                ))
            .toList());
  }

  Stream<List<app_models.Review>> streamAllReviews() {
    return _firestore
        .collection('reviews')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Review.fromJson(
                  doc.data(),
                  id: doc.id,
                ))
            .toList());
  }

  Stream<List<app_models.Order>> streamCompletedOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromJson(
                  doc.data(),
                  id: doc.id,
                ))
            .toList());
  }

  Future<void> updateUser(app_models.User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
    if (user.role == app_models.UserRole.craftsman) {
      await _firestore.collection('craftsmen').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
      }, SetOptions(merge: true));
    }
    showSnackBar('تم تحديث بيانات المستخدم');
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  Stream<List<app_models.Order>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromJson(
                  doc.data(),
                  id: doc.id,
                ))
            .toList());
  }

  Future<List<app_models.Order>> getAllOrders() async {
    final snapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => app_models.Order.fromJson(
              doc.data(),
              id: doc.id,
            ))
        .toList();
  }

  Future<List<app_models.Review>> getAllReviews() async {
    final snapshot = await _firestore.collection('reviews').get();
    return snapshot.docs
        .map((doc) => app_models.Review.fromJson(
              doc.data(),
              id: doc.id,
            ))
        .toList();
  }

  Future<List<app_models.Craftsman>> getAllCraftsmen() async {
    final snapshot = await _firestore.collection('craftsmen').get();
    return snapshot.docs
        .map((doc) => app_models.Craftsman.fromJson(
              doc.data(),
              id: doc.id,
            ))
        .toList();
  }

  // ==================== CHAT (Stream) ====================
  // يوفّر دفق رسائل الدردشة المرتبطة بطلب معين ويستمع لتحديثاتها في الوقت الحقيقي.
  Stream<List<app_models.ChatMessage>> streamChatMessages(
    String orderId, {
    String? alternateId,
  }) {
    final ids = [orderId];
    if (alternateId != null && alternateId != orderId) {
      ids.add(alternateId);
    }

    final query = ids.length == 1
        ? _firestore
            .collection('chat_messages')
            .where('orderId', isEqualTo: orderId)
        : _firestore.collection('chat_messages').where('orderId', whereIn: ids);

    return query.orderBy('timestamp', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => app_models.ChatMessage.fromJson(doc.data()))
            .toList());
  }

  // يرسل رسالة الدردشة إلى Firestore ويقوم بإشعار المستلم إذا كان معرفه موجوداً.
  Future<void> sendChatMessage(app_models.ChatMessage message) async {
    await _firestore.collection('chat_messages').add(message.toJson());
    final recipientId = message.recipientId;
    if (recipientId != null) {
      await sendFcmNotificationToUser(
        recipientId,
        'رسالة جديدة',
        message.message,
        data: {
          'orderId': message.orderId,
          'senderId': message.senderId,
          'type': 'chat',
        },
      );
    }
  }

  // ==================== REVIEWS ====================
  Future<List<app_models.Review>> getCraftsmanReviews(
      String craftsmanId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('craftsmanId', isEqualTo: craftsmanId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => app_models.Review.fromJson(d.data()))
        .toList();
  }

  // يضيف تقييمًا جديدًا للحرفي ويحدث متوسط التقييم وعدد المراجعات باستخدام معاملة آمنة.
  Future<void> submitReview(app_models.Review review) async {
    final docRef = await _firestore.collection('reviews').add(review.toJson());
    await docRef.update({'id': docRef.id});

    final craftsmanRef =
        _firestore.collection('craftsmen').doc(review.craftsmanId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(craftsmanRef);
      if (!doc.exists) return;
      final data = doc.data()!;
      final ratingValue = data['rating'];
      final totalReviewsValue = data['totalReviews'];
      final double currentRating =
          ratingValue is num ? ratingValue.toDouble() : 0.0;
      final int totalReviews = totalReviewsValue is int ? totalReviewsValue : 0;
      final newTotal = (currentRating * totalReviews) + review.rating;
      final newCount = totalReviews + 1;
      final newAvg = newTotal / newCount;
      transaction.update(craftsmanRef, {
        'rating': newAvg,
        'totalReviews': newCount,
      });
    });
    showSnackBar('تم إضافة التقييم');
  }

  // ==================== IMAGE UPLOAD ====================
  // يرفع صورة إلى Firebase Storage سواء على الويب أو الهاتف، مع دعم أنواع الملفات المختلفة.
  Future<String?> _uploadImageToStorage(String path, dynamic file) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    try {
      UploadTask? uploadTask;
      if (kIsWeb) {
        if (file is Uint8List) {
          uploadTask = ref.putData(file);
        } else if (file is XFile) {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          throw Exception('Unsupported file type on web: ${file.runtimeType}');
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is XFile) {
          final fileObj = File(file.path);
          uploadTask = ref.putFile(fileObj);
        } else {
          throw Exception(
              'Unsupported file type on mobile: ${file.runtimeType}');
        }
      }

      // Wait for completion with a timeout to avoid hanging indefinitely.
      final whenCompleteFuture = uploadTask.whenComplete(() {});
      await whenCompleteFuture.timeout(const Duration(seconds: 60));

      final url = await ref.getDownloadURL();
      return url;
    } on TimeoutException catch (e) {
      debugPrint('Upload timeout: $e');
      showSnackBar('انتهت مهلة رفع الصورة. حاول مرة أخرى.', isError: true);
      return null;
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      showSnackBar('فشل رفع الصورة: ${e.toString()}', isError: true);
      return null;
    }
  }

  Future<String?> uploadPortfolioImage(
      String craftsmanId, dynamic imageFile) async {
    final fileName = const Uuid().v4();
    final path = 'craftsmen/$craftsmanId/portfolio/$fileName.jpg';
    return await _uploadImageToStorage(path, imageFile);
  }

  Future<String?> uploadProfileImage(String userId, dynamic imageFile) async {
    final fileName = const Uuid().v4();
    final path = 'users/$userId/profile/$fileName.jpg';
    return await _uploadImageToStorage(path, imageFile);
  }

  Future<void> updateCraftsmanPortfolio(
      String craftsmanId, List<String> images) async {
    await _firestore.collection('craftsmen').doc(craftsmanId).update({
      'portfolioImages': images,
    });
    showSnackBar('تم تحديث معرض الأعمال');
  }
}
