import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Client Craftsman Profile Screen
// Arabic: صفحة العرض التفصيلية لملف الحرفي كما يراها العميل.
// English: Allows clients to view craftsman's portfolio, reviews and contact options.

class ClientCraftsmanProfileScreen extends StatefulWidget {
  final String? craftsmanId;
  const ClientCraftsmanProfileScreen({super.key, this.craftsmanId});

  @override
  State<ClientCraftsmanProfileScreen> createState() =>
      _ClientCraftsmanProfileScreenState();
}

class _ClientCraftsmanProfileScreenState
    extends State<ClientCraftsmanProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  app_models.Craftsman? _craftsman;
  List<app_models.Review> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _craftsmanId;
  String? _currentUserId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _craftsmanId = widget.craftsmanId;
    _initData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_craftsmanId == null || _craftsmanId!.isEmpty) {
      final arguments = ModalRoute.of(context)!.settings.arguments;
      debugPrint('========== CLIENT CRAFTSMAN PROFILE DEBUG ==========');
      debugPrint('Arguments type: ${arguments.runtimeType}');
      debugPrint('Arguments value: $arguments');

      if (arguments is String) {
        _craftsmanId = arguments;
      } else if (arguments is Map) {
        _craftsmanId = arguments["craftsmanId"] ??
            arguments["id"] ??
            arguments["craftsman_id"];
      } else if (arguments != null) {
        _craftsmanId = arguments.toString();
      }
    }

    if (_craftsmanId != null && _craftsmanId!.isNotEmpty) {
      _fetchCraftsmanProfile(_craftsmanId!);
      _fetchCraftsmanReviews(_craftsmanId!);
      _initCurrentUser();
    } else if (_craftsmanId == null || _craftsmanId!.isEmpty) {
      setState(() {
        _errorMessage = 'لم يتم استلام معرف الحرفي';
        _isLoading = false;
      });
    }
  }

  Future<void> _initData() async {
    if (_craftsmanId != null && _craftsmanId!.isNotEmpty) {
      _fetchCraftsmanProfile(_craftsmanId!);
      _fetchCraftsmanReviews(_craftsmanId!);
      _initCurrentUser();
    }
  }

  Future<void> _initCurrentUser() async {
    final user = await _firebaseService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _currentUserId = user.id;
          _currentUserRole = user.role.toString().split('.').last;
        });
      }
      debugPrint('Current user role: $_currentUserRole, id: $_currentUserId');
    } else {
      debugPrint('No user logged in');
    }
  }

  Future<void> _fetchCraftsmanProfile(String craftsmanId) async {
    debugPrint('🔍 Fetching craftsman profile for ID: $craftsmanId');
    try {
      final craftsman = await _firebaseService.getCraftsmanProfile(craftsmanId);
      debugPrint('📦 Craftsman fetched: ${craftsman?.name}');
      if (craftsman != null) {
        if (mounted) {
          setState(() {
            _craftsman = craftsman;
          });
        }
      } else {
        debugPrint('❌ Craftsman is null for ID: $craftsmanId');
        if (mounted) {
          setState(() {
            _errorMessage = 'لم يتم العثور على حرفي بهذا المعرف: $craftsmanId';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchCraftsmanProfile: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات الحرفي: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCraftsmanReviews(String craftsmanId) async {
    debugPrint('⭐ Fetching reviews for craftsman ID: $craftsmanId');
    try {
      final reviews = await _firebaseService.getCraftsmanReviews(craftsmanId);
      debugPrint('⭐ Reviews count: ${reviews.length}');
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchCraftsmanReviews: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل التقييمات: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showReviewBottomSheet() async {
    if (_craftsman == null) return;

    double currentRating = 0.0;
    final TextEditingController commentController = TextEditingController();

    if (_currentUserId == null) {
      showSnackBar('يرجى تسجيل الدخول أولاً لتقييم الحرفي', isError: true);
      return;
    }

    final currentUser = await _firebaseService.getCurrentUser();
    if (currentUser == null) {
      showSnackBar('يرجى تسجيل الدخول أولاً', isError: true);
      return;
    }

    if (currentUser.id == _craftsman!.id) {
      showSnackBar('لا يمكنك تقييم نفسك', isError: true);
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'قيم الحرفي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 16.0),
                RatingBar.builder(
                  initialRating: currentRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    currentRating = rating;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'تعليقك (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),
                CustomButton(
                  text: 'إرسال التقييم',
                  onPressed: () async {
                    if (currentRating == 0.0) {
                      showSnackBar('الرجاء إضافة تقييم', isError: true);
                      return;
                    }
                    final review = app_models.Review(
                      id: const Uuid().v4(),
                      clientId: currentUser.id,
                      clientName: currentUser.name,
                      craftsmanId: _craftsman!.id,
                      rating: currentRating,
                      comment: commentController.text.trim(),
                      createdAt: Timestamp.now(),
                    );
                    if (!mounted) return;
                    final outerNavigator = Navigator.of(context);
                    Navigator.of(sheetContext).pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) {
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                    try {
                      await _firebaseService.submitReview(review);
                      if (!mounted) return;
                      outerNavigator.pop();
                      showSnackBar('تم إرسال تقييمك بنجاح!');
                      await _fetchCraftsmanReviews(_craftsmanId!);
                      await _fetchCraftsmanProfile(_craftsmanId!);
                    } catch (e) {
                      if (!mounted) return;
                      outerNavigator.pop();
                      showSnackBar('فشل إرسال التقييم: ${e.toString()}',
                          isError: true);
                    }
                  },
                  width: double.infinity,
                  height: 50,
                  backgroundColor: AppColors.primaryGold,
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startChat() async {
    if (_craftsman == null) {
      showSnackBar('لا يمكن بدء المحادثة حالياً', isError: true);
      return;
    }

    if (_currentUserId == null) {
      showSnackBar('يرجى تسجيل الدخول أولاً للدردشة مع الحرفي', isError: true);
      return;
    }

    final chatOrderId = buildChatId(_currentUserId!, _craftsman!.id);

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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ملف الحرفي")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      );
    }

    if (_craftsman == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("ملف الحرفي")),
        body: const Center(child: Text("لم يتم العثور على بيانات الحرفي")),
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
                  const SizedBox(height: 8),
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
            const SizedBox(height: 24.0),
            _buildInfoSection("المهنة", _craftsman!.profession),
            _buildInfoSection(
                "سنوات الخبرة", "${_craftsman!.yearsOfExperience} سنوات"),
            _buildInfoSection("المدينة", _craftsman!.city),
            _buildInfoSection("نبذة", _craftsman!.bio),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "طلب خدمة",
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.clientRequestService,
                          arguments: _craftsman!.id,
                        );
                      }
                    },
                    height: 44,
                    textStyle: const TextStyle(fontSize: 16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: "محادثة",
                    onPressed: _currentUserId != null &&
                            _currentUserId != _craftsman!.id
                        ? _startChat
                        : _currentUserId == null
                            ? () => showSnackBar('يرجى تسجيل الدخول أولاً',
                                isError: true)
                            : null,
                    backgroundColor: AppColors.primaryDarkBlue,
                    height: 44,
                    textStyle: const TextStyle(fontSize: 16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            const Text(
              "معرض الأعمال",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
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
            const SizedBox(height: 24.0),
            const Text(
              "تقييمات العملاء",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
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
                          const SizedBox(height: 8.0),
                          if (review.comment.isNotEmpty) Text(review.comment),
                          const SizedBox(height: 4.0),
                          Text(
                            DateFormat("dd/MM/yyyy")
                                .format(review.createdAt.toDate()),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16.0),
            if (_currentUserRole == 'client' &&
                _currentUserId != _craftsman!.id)
              Center(
                child: CustomButton(
                  text: "قيم هذا الحرفي",
                  onPressed: _showReviewBottomSheet,
                  width: 200,
                  height: 45,
                ),
              ),
            const SizedBox(height: 32.0),
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
