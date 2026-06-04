import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  String? _clientId;
  final Map<String, String> _craftsmanNames = {};
  List<app_models.Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchClientId();
  }

  Future<void> _fetchClientId() async {
    try {
      final currentUser = await _firebaseService.getCurrentUser();
      if (currentUser != null) {
        _clientId = currentUser.id;
        await _fetchOrders();
      } else {
        setState(() {
          _errorMessage = 'الرجاء تسجيل الدخول';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (_clientId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _firebaseService.getClientOrders(_clientId!);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل الطلبات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String> _getCraftsmanName(String craftsmanId) async {
    if (_craftsmanNames.containsKey(craftsmanId)) {
      return _craftsmanNames[craftsmanId]!;
    }
    try {
      final craftsman = await _firebaseService.getCraftsmanProfile(craftsmanId);
      if (craftsman != null) {
        _craftsmanNames[craftsmanId] = craftsman.name;
        return craftsman.name;
      }
    } catch (e) {
      debugPrint('Error fetching craftsman name: $e');
    }
    return 'حرفي';
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, status);
      await _fetchOrders();
      showSnackBar('تم تحديث حالة الطلب');
    } catch (e) {
      showSnackBar('فشل تحديث الحالة: ${e.toString()}', isError: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("طلباتي")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("طلباتي")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              CustomButton(
                text: 'إعادة المحاولة',
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _fetchClientId();
                },
                width: 160,
                height: 42,
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("طلباتي")),
        body: const Center(child: Text('لا توجد طلبات حالياً')),
      );
    }

    final currentOrders = _orders.where((order) {
      return order.status == app_models.OrderStatus.pending ||
          order.status == app_models.OrderStatus.accepted;
    }).toList();

    final pastOrders = _orders.where((order) {
      return order.status == app_models.OrderStatus.completed ||
          order.status == app_models.OrderStatus.cancelled ||
          order.status == app_models.OrderStatus.rejected;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("طلباتي"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "الحالية"),
            Tab(text: "السابقة"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(currentOrders, isCurrent: true),
          _buildOrderList(pastOrders, isCurrent: false),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<app_models.Order> orders,
      {required bool isCurrent}) {
    if (orders.isEmpty) {
      return const Center(child: Text('لا توجد طلبات'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FutureBuilder<String>(
          future: _getCraftsmanName(order.craftsmanId),
          builder: (context, nameSnapshot) {
            final craftsmanName = nameSnapshot.data ?? 'جاري التحميل...';
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          craftsmanName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getOrderStatusColor(order.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getOrderStatusText(order.status),
                            style: TextStyle(
                              color: getOrderStatusColor(order.status),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('الخدمة: ${order.serviceDescription}'),
                    Text('السعر: ${order.price.toStringAsFixed(2)} ر.س'),
                    Text('التاريخ: ${formatTimestamp(order.scheduledDate)}'),
                    if (isCurrent &&
                        order.status == app_models.OrderStatus.pending) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: 'إلغاء الطلب',
                            onPressed: () => _updateOrderStatus(
                              order.id,
                              app_models.OrderStatus.cancelled
                                  .toString()
                                  .split('.')
                                  .last,
                            ),
                            width: 120,
                            height: 42,
                            backgroundColor: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          CustomButton(
                            text: 'متابعة',
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.clientChat,
                                arguments: {
                                  'orderId': order.id,
                                  'craftsmanId': order.craftsmanId,
                                  'craftsmanName': craftsmanName,
                                },
                              );
                            },
                            width: 120,
                            height: 42,
                          ),
                        ],
                      ),
                    ],
                    if (isCurrent &&
                        order.status == app_models.OrderStatus.accepted) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomButton(
                            text: 'متابعة الطلب',
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.clientChat,
                                arguments: {
                                  'orderId': order.id,
                                  'craftsmanId': order.craftsmanId,
                                  'craftsmanName': craftsmanName,
                                },
                              );
                            },
                            width: 140,
                            height: 42,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
