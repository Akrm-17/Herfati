import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:herfatiapp/core/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _totalClients = 0;
  int _totalCraftsmen = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  double _averageRating = 0.0;
  Map<String, int> _craftsmenByProfession = {};
  List<Map<String, dynamic>> _topCraftsmen = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // جلب المستخدمين
      final usersSnapshot = await _firestore.collection('users').get();
      _totalClients = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'client')
          .length;
      _totalCraftsmen = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'craftsman')
          .length;

      // جلب الطلبات
      final ordersSnapshot = await _firestore.collection('orders').get();
      _totalOrders = ordersSnapshot.docs.length;
      _completedOrders = ordersSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      // جلب التقييمات
      final reviewsSnapshot = await _firestore.collection('reviews').get();
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
        _averageRating = totalRating / reviewsSnapshot.docs.length;
      }

      // جلب الحرفيين حسب المهنة
      final craftsmenSnapshot = await _firestore.collection('craftsmen').get();
      Map<String, int> professionCount = {};
      for (var doc in craftsmenSnapshot.docs) {
        final profession = doc.data()['profession'] as String? ?? 'أخرى';
        professionCount[profession] = (professionCount[profession] ?? 0) + 1;
      }
      _craftsmenByProfession = professionCount;

      // جلب أفضل الحرفيين (أعلى تقييم)
      final topCraftsmenSnapshot = await _firestore
          .collection('craftsmen')
          .orderBy('rating', descending: true)
          .limit(5)
          .get();
      _topCraftsmen = topCraftsmenSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'غير معروف',
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'totalOrders': data['totalOrders'] ?? 0,
          'profession': data['profession'] ?? 'حرفي',
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar('فشل تحميل التقارير: ${e.toString()}', isError: true);
    }
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
                        final totalValue = _craftsmenByProfession.values.fold(0, (int total, int value) => total + value);
                        final percentage = totalValue > 0 ? (entry.value / totalValue * 100).toStringAsFixed(1) : '0';
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
                                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.2),
                                child: Text('${index + 1}'),
                              ),
                              title: Text(craftsman['name']),
                              subtitle: Text('${craftsman['profession']} · ${craftsman['totalOrders']} طلب'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
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

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
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