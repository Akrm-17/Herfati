import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class CraftsmanHomeScreen extends StatefulWidget {
  const CraftsmanHomeScreen({super.key});

  @override
  State<CraftsmanHomeScreen> createState() => _CraftsmanHomeScreenState();
}

class _CraftsmanHomeScreenState extends State<CraftsmanHomeScreen> {
  final FirebaseService _service = FirebaseService();
  Map<app_models.OrderStatus, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await _service.getCurrentUser();
    if (user != null && user.role == app_models.UserRole.craftsman) {
      final stats = await _service.getCraftsmanStatistics(user.id);
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  int _getCount(app_models.OrderStatus status) => _stats[status] ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("لوحة الحرفي")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة الحرفي"),
        backgroundColor: AppColors.primaryDarkBlue,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.pushNamed(context, AppRoutes.craftsmanProfile)),
          IconButton(icon: const Icon(Icons.list_alt), onPressed: () => Navigator.pushNamed(context, AppRoutes.craftsmanOrders)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard("جديدة", _getCount(app_models.OrderStatus.pending), Colors.orange),
                    _buildStatCard("قيد التنفيذ", _getCount(app_models.OrderStatus.accepted), Colors.blue),
                    _buildStatCard("مكتملة", _getCount(app_models.OrderStatus.completed), Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("الإدارة السريعة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primaryGold),
              title: const Text("الملف الشخصي"),
              onTap: () => Navigator.pushNamed(context, AppRoutes.craftsmanProfile),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: AppColors.primaryGold),
              title: const Text("الطلبات"),
              onTap: () => Navigator.pushNamed(context, AppRoutes.craftsmanOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}