import 'dart:async';

import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late final StreamSubscription<List<app_models.User>> _usersSubscription;
  late final StreamSubscription<List<app_models.Order>> _ordersSubscription;
  late final StreamSubscription<List<app_models.Review>> _reviewsSubscription;
  late final StreamSubscription<List<app_models.Craftsman>>
      _craftsmenSubscription;
  bool _isLoading = true;
  int _totalClients = 0;
  int _totalCraftsmen = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  double _averageRating = 0.0;
  Map<String, int> _craftsmenByProfession = {};
  List<Map<String, dynamic>> _topCraftsmen = [];

  List<app_models.User> _allUsers = [];
  List<app_models.Order> _allOrders = [];
  List<app_models.Review> _allReviews = [];
  List<app_models.Craftsman> _allCraftsmen = [];

  @override
  void initState() {
    super.initState();
    _subscribeToReports();
  }

  void _subscribeToReports() {
    _usersSubscription = _firebaseService.streamAllUsers().listen(
      (users) {
        if (!mounted) return;
        _allUsers = users;
        _updateReportData();
      },
      onError: (error) {
        if (!mounted) return;
        showSnackBar('فشل تحميل بيانات المستخدمين: $error', isError: true);
      },
    );

    _ordersSubscription = _firebaseService.streamAllOrders().listen(
      (orders) {
        if (!mounted) return;
        _allOrders = orders;
        _updateReportData();
      },
      onError: (error) {
        if (!mounted) return;
        showSnackBar('فشل تحميل بيانات الطلبات: $error', isError: true);
      },
    );

    _reviewsSubscription = _firebaseService.streamAllReviews().listen(
      (reviews) {
        if (!mounted) return;
        _allReviews = reviews;
        _updateReportData();
      },
      onError: (error) {
        if (!mounted) return;
        showSnackBar('فشل تحميل بيانات التقييمات: $error', isError: true);
      },
    );

    _craftsmenSubscription = _firebaseService.streamAllCraftsmen().listen(
      (craftsmen) {
        if (!mounted) return;
        _allCraftsmen = craftsmen;
        _updateReportData();
      },
      onError: (error) {
        if (!mounted) return;
        showSnackBar('فشل تحميل بيانات الحرفيين: $error', isError: true);
      },
    );
  }

  void _updateReportData() {
    final users = _allUsers;
    final orders = _allOrders;
    final reviews = _allReviews;
    final craftsmen = _allCraftsmen;

    _totalClients =
        users.where((user) => user.role == app_models.UserRole.client).length;
    _totalCraftsmen = users
        .where((user) => user.role == app_models.UserRole.craftsman)
        .length;
    _totalOrders = orders.length;
    _completedOrders = orders
        .where((order) => order.status == app_models.OrderStatus.completed)
        .length;

    if (reviews.isNotEmpty) {
      final totalRating = reviews
          .map((review) => review.rating)
          .fold<double>(0.0, (sum, rating) => sum + rating);
      _averageRating = totalRating / reviews.length;
    } else {
      _averageRating = 0.0;
    }

    final professionCount = <String, int>{};
    for (var craftsman in craftsmen) {
      final profession =
          craftsman.profession.isNotEmpty ? craftsman.profession : 'أخرى';
      professionCount[profession] = (professionCount[profession] ?? 0) + 1;
    }
    _craftsmenByProfession = professionCount;

    final sortedCraftsmen = List.of(craftsmen)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    _topCraftsmen = sortedCraftsmen.take(5).map((craftsman) {
      return {
        'name': craftsman.name,
        'rating': craftsman.rating,
        'totalOrders': craftsman.totalOrders,
        'profession':
            craftsman.profession.isNotEmpty ? craftsman.profession : 'حرفي',
      };
    }).toList();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _firebaseService.getAllUsers();
      _allUsers = users;
      final orders = await _firebaseService.getAllOrders();
      _allOrders = orders;
      final reviews = await _firebaseService.getAllReviews();
      _allReviews = reviews;
      final craftsmen = await _firebaseService.getAllCraftsmen();
      _allCraftsmen = craftsmen;
      _updateReportData();
    } catch (e) {
      showSnackBar('فشل تحميل التقارير: ${e.toString()}', isError: true);
    }
  }

  @override
  void dispose() {
    _usersSubscription.cancel();
    _ordersSubscription.cancel();
    _reviewsSubscription.cancel();
    _craftsmenSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        backgroundColor: AppColors.primaryDarkBlue,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إحصائيات عامة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildReportCard(
                          'العملاء',
                          '$_totalClients',
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildReportCard(
                          'الحرفيون',
                          '$_totalCraftsmen',
                          Icons.handyman,
                          Colors.orange,
                        ),
                        _buildReportCard(
                          'إجمالي الطلبات',
                          '$_totalOrders',
                          Icons.receipt,
                          Colors.green,
                        ),
                        _buildReportCard(
                          'الطلبات المكتملة',
                          '$_completedOrders',
                          Icons.check_circle,
                          AppColors.success,
                        ),
                        _buildReportCard(
                          'متوسط التقييم',
                          '${_averageRating.toStringAsFixed(1)} / 5',
                          Icons.star,
                          Colors.amber,
                        ),
                        _buildReportCard(
                          'نسبة الإكمال',
                          '${_totalOrders > 0 ? ((_completedOrders / _totalOrders) * 100).toStringAsFixed(0) : 0}%',
                          Icons.percent,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'توزيع الحرفيين حسب المهنة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_craftsmenByProfession.isEmpty)
                      const Center(child: Text('لا توجد بيانات'))
                    else
                      ..._craftsmenByProfession.entries.map((entry) {
                        final totalValue = _craftsmenByProfession.values
                            .fold(0, (int total, int value) => total + value);
                        final percentage = totalValue > 0
                            ? (entry.value / totalValue * 100)
                                .toStringAsFixed(1)
                            : '0';
                        return Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: entry.value / totalValue,
                                    backgroundColor: Colors.grey[200],
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '$percentage%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    const SizedBox(height: 24),
                    const Text(
                      'أفضل 5 حرفيين',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_topCraftsmen.isEmpty)
                      const Center(child: Text('لا توجد بيانات'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topCraftsmen.length,
                        itemBuilder: (context, index) {
                          final craftsman = _topCraftsmen[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryGold
                                    .withValues(alpha: 0.2),
                                child: Text('${index + 1}'),
                              ),
                              title: Text(craftsman['name']),
                              subtitle: Text(
                                  '${craftsman['profession']} · ${craftsman['totalOrders']} طلب'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(craftsman['rating'].toStringAsFixed(1)),
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
      ),
    );
  }

  Widget _buildReportCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
