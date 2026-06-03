import 'dart:io';
import 'dart:async';
import 'package:cross_file/cross_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/models.dart' as app_models;
import 'package:uuid/uuid.dart';

class FirebaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ==================== AUTH ====================
  Future<app_models.User?> signInWithEmail(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _getUserById(result.user!.uid);
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
            .collection('craftsmen')
            .doc(craftsman.id)
            .set(craftsman.toJson());
      }
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
    showSnackBar('تم تسجيل الخروج');
  }

  Future<app_models.User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _getUserById(user.uid);
  }

  Future<app_models.User?> _getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return app_models.User.fromJson(doc.data()!);
  }

  Future<app_models.User?> getUserById(String uid) => _getUserById(uid);

  // ==================== CRAFTSMAN ====================
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

  // ==================== ORDERS (Stream) ====================
  Stream<List<app_models.Order>> streamCraftsmanOrders(String craftsmanId) {
    return _firestore
        .collection('orders')
        .where('craftsmanId', isEqualTo: craftsmanId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.Order.fromJson(doc.data()))
            .toList());
  }

  Future<app_models.Order> createOrder(app_models.Order order) async {
    final docRef = await _firestore.collection('orders').add(order.toJson());
    return order.copyWith(id: docRef.id);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': status});
    showSnackBar('تم تحديث الحالة');
  }

  // ==================== CHAT (Stream) ====================
  Stream<List<app_models.ChatMessage>> streamChatMessages(String orderId) {
    return _firestore
        .collection('chat_messages')
        .where('orderId', isEqualTo: orderId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_models.ChatMessage.fromJson(doc.data()))
            .toList());
  }

  Future<void> sendChatMessage(app_models.ChatMessage message) async {
    await _firestore.collection('chat_messages').add(message.toJson());
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

  Future<void> submitReview(app_models.Review review) async {
    final docRef = await _firestore.collection('reviews').add(review.toJson());
    await docRef.update({'id': docRef.id});

    final craftsmanRef =
        _firestore.collection('craftsmen').doc(review.craftsmanId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(craftsmanRef);
      if (!doc.exists) return;
      final data = doc.data()!;
      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int totalReviews = (data['totalReviews'] as int?) ?? 0;
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

  Future<void> updateUser(app_models.User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
    showSnackBar('تم تحديث الملف');
  }
}
