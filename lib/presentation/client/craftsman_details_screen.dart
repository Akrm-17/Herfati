import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class CraftsmanDetailsScreen extends StatefulWidget {
  final String craftsmanId;
  const CraftsmanDetailsScreen({super.key, required this.craftsmanId});

  @override
  State<CraftsmanDetailsScreen> createState() => _CraftsmanDetailsScreenState();
}

class _CraftsmanDetailsScreenState extends State<CraftsmanDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  app_models.Craftsman? _craftsman;
  List<app_models.Review> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = await _firebaseService.getCurrentUser();
    if (user != null) {
      _currentUserId = user.id;
    }
  }

  Future<void> _fetchData() async {
    try {
      final craftsman =
          await _firebaseService.getCraftsmanProfile(widget.craftsmanId);
      final reviews =
          await _firebaseService.getCraftsmanReviews(widget.craftsmanId);
      setState(() {
        _craftsman = craftsman;
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل البيانات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// دالة لبدء المحادثة (مع التأكد من وجود userId)
  void _startChat() async {
    if (_craftsman == null) {
      showSnackBar('لا يمكن بدء المحادثة حالياً', isError: true);
      return;
    }

    // تأكد من جلب المستخدم الحالي إذا لم يكن موجوداً
    String? userId = _currentUserId;
    if (userId == null) {
      final user = await _firebaseService.getCurrentUser();
      if (user == null) {
        showSnackBar('يرجى تسجيل الدخول أولاً', isError: true);
        return;
      }
      userId = user.id;
      _currentUserId = userId;
    }

    // منع الدردشة مع النفس
    if (userId == _craftsman!.id) {
      showSnackBar('لا يمكنك الدردشة مع نفسك', isError: true);
      return;
    }

    // إنشاء معرف محادثة فريد
    final chatOrderId = buildChatId(userId, _craftsman!.id);

    // الانتقال إلى شاشة الدردشة
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.clientChat,
      arguments: {
        'orderId': chatOrderId,
        'craftsmanId': _craftsman!.id,
        'craftsmanName': _craftsman!.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("ملف الحرفي")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _craftsman == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ملف الحرفي")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage ?? "لم يتم العثور على الحرفي"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_craftsman!.name),
        backgroundColor: AppColors.primaryDarkBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _craftsman!.profileImage != null
                        ? NetworkImage(_craftsman!.profileImage!)
                        : null,
                    child: _craftsman!.profileImage == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _craftsman!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBarIndicator(
                        rating: _craftsman!.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_craftsman!.rating.toStringAsFixed(1)} (${_craftsman!.totalOrders} طلب)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoSection("المهنة", _craftsman!.profession),
            _buildInfoSection(
                "سنوات الخبرة", "${_craftsman!.yearsOfExperience} سنوات"),
            _buildInfoSection("المدينة", _craftsman!.city),
            _buildInfoSection("نبذة", _craftsman!.bio),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.clientRequestService,
                        arguments: _craftsman!.id,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        const Text("طلب خدمة", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startChat, // ✅ زر المحادثة المفعل
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("محادثة", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "معرض الأعمال",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _craftsman!.portfolioImages.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child: Text("لا توجد صور في معرض الأعمال")),
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _craftsman!.portfolioImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _craftsman!.portfolioImages[index],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            const Text(
              "تقييمات العملاء",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text("لا توجد تقييمات لهذا الحرفي حتى الآن")),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.clientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              RatingBarIndicator(
                                rating: review.rating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 16.0,
                                direction: Axis.horizontal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (review.comment.isNotEmpty) Text(review.comment),
                          const SizedBox(height: 4),
                          Text(
                            '${review.createdAt.toDate().year}-${review.createdAt.toDate().month}-${review.createdAt.toDate().day}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
          const Divider(),
        ],
      ),
    );
  }
}
