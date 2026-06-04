import 'dart:async';

import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  late final StreamSubscription<List<app_models.User>> _usersSubscription;
  late final StreamSubscription<List<app_models.Craftsman>>
      _craftsmenSubscription;
  late final StreamSubscription<List<app_models.Order>> _ordersSubscription;
  late final StreamSubscription<List<app_models.Order>>
      _completedOrdersSubscription;

  int _totalUsers = 0;
  int _totalCraftsmen = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToStatistics();
  }

  void _subscribeToStatistics() {
    _usersSubscription = _firebaseService.streamAllUsers().listen((users) {
      if (!mounted) return;
      setState(() {
        _totalUsers = users.length;
        _isLoading = false;
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showSnackBar('فشل تحميل عدد المستخدمين: $error', isError: true);
    });

    _craftsmenSubscription = _firebaseService.streamAllCraftsmen().listen(
      (craftsmen) {
        if (!mounted) return;
        setState(() {
          _totalCraftsmen = craftsmen.length;
          _isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        showSnackBar('فشل تحميل عدد الحرفيين: $error', isError: true);
      },
    );

    _ordersSubscription = _firebaseService.streamAllOrders().listen((orders) {
      if (!mounted) return;
      setState(() {
        _totalOrders = orders.length;
        _isLoading = false;
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showSnackBar('فشل تحميل عدد الطلبات: $error', isError: true);
    });

    _completedOrdersSubscription =
        _firebaseService.streamCompletedOrders().listen((orders) {
      if (!mounted) return;
      setState(() {
        _totalRevenue = orders.fold<double>(0.0, (sum, order) {
          final price = order.price;
          return sum + (price is num ? price.toDouble() : 0.0);
        });
        _isLoading = false;
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showSnackBar('فشل تحميل الإيرادات: $error', isError: true);
    });
  }

  @override
  void dispose() {
    _usersSubscription.cancel();
    _craftsmenSubscription.cancel();
    _ordersSubscription.cancel();
    _completedOrdersSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _totalUsers = await _firebaseService.getUsersCount();
      _totalCraftsmen = await _firebaseService.getCraftsmenCount();
      _totalOrders = await _firebaseService.getOrdersCount();
      _totalRevenue = await _firebaseService.getCompletedOrdersRevenue();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBar('فشل تحميل الإحصائيات: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المسؤول'),
        backgroundColor: AppColors.primaryDarkBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStatistics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة عامة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'إجمالي المستخدمين',
                      '$_totalUsers',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'إجمالي الحرفيين',
                      '$_totalCraftsmen',
                      Icons.handyman,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'الطلبات النشطة',
                      '$_totalOrders',
                      Icons.pending_actions,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'إجمالي الأرباح',
                      '${_totalRevenue.toStringAsFixed(0)} ر.س',
                      Icons.payments,
                      AppColors.primaryGold,
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Text(
                'الإدارة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 16),
              _buildAdminMenuTile(
                context,
                'إدارة المستخدمين',
                'إدارة العملاء والحرفيين وتفعيل الحسابات',
                Icons.manage_accounts,
                AppRoutes.adminUsers,
              ),
              _buildAdminMenuTile(
                context,
                'إدارة الطلبات',
                'متابعة جميع الطلبات وحالاتها',
                Icons.list_alt,
                AppRoutes.adminOrders,
              ),
              _buildAdminMenuTile(
                context,
                'التقارير والإحصائيات',
                'عرض تقارير الأداء والنمو',
                Icons.analytics,
                AppRoutes.adminReports,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildAdminMenuTile(BuildContext context, String title,
      String subtitle, IconData icon, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryDarkBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primaryDarkBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).pushNamed(route);
        },
      ),
    );
  }
}
