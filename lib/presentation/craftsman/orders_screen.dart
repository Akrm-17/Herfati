import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class CraftsmanOrdersScreen extends StatefulWidget {
  const CraftsmanOrdersScreen({super.key});

  @override
  State<CraftsmanOrdersScreen> createState() => _CraftsmanOrdersScreenState();
}

class _CraftsmanOrdersScreenState extends State<CraftsmanOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _service = FirebaseService();
  String? _craftsmanId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCraftsmanId();
  }

  Future<void> _loadCraftsmanId() async {
    final user = await _service.getCurrentUser();
    if (user != null && user.role == app_models.UserRole.craftsman) {
      setState(() => _craftsmanId = user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_craftsmanId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("طلباتي")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("طلباتي"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "جديدة"),
            Tab(text: "قيد التنفيذ"),
            Tab(text: "مكتملة"),
            Tab(text: "ملغاة"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderStream(app_models.OrderStatus.pending),
          _buildOrderStream(app_models.OrderStatus.accepted),
          _buildOrderStream(app_models.OrderStatus.completed),
          _buildOrderStream(app_models.OrderStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildOrderStream(app_models.OrderStatus status) {
    return StreamBuilder<List<app_models.Order>>(
      stream: _service.streamCraftsmanOrders(_craftsmanId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        final filtered = orders.where((o) => o.status == status).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text("لا توجد طلبات"));
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final order = filtered[index];
            return FutureBuilder<app_models.User?>(
              future: _service.getUserById(order.clientId),
              builder: (context, userSnap) {
                final clientName = userSnap.data?.name ?? "عميل";
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: getOrderStatusColor(order.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                getOrderStatusText(order.status),
                                style: TextStyle(
                                  color: getOrderStatusColor(order.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('الخدمة: ${order.serviceDescription}'),
                        const SizedBox(height: 6),
                        Text('السعر: ${order.price.toStringAsFixed(2)} ر.س'),
                        const SizedBox(height: 6),
                        Text(
                            'التاريخ: ${formatTimestamp(order.scheduledDate)}'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            CustomButton(
                              text: "محادثة",
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.craftsmanChat,
                                  arguments: {
                                    "orderId": order.id,
                                    "clientId": order.clientId,
                                    "clientName": clientName,
                                  },
                                );
                              },
                              width: 90,
                              height: 40,
                            ),
                            if (order.status ==
                                app_models.OrderStatus.pending) ...[
                              CustomButton(
                                text: "قبول",
                                onPressed: () => _updateOrderStatus(
                                  order.id,
                                  app_models.OrderStatus.accepted
                                      .toString()
                                      .split(".")
                                      .last,
                                  order.clientId,
                                  "طلب مقبول",
                                  "تم قبول طلبك من قبل الحرفي",
                                  order.id,
                                ),
                                width: 90,
                                height: 40,
                                backgroundColor: AppColors.success,
                              ),
                              CustomButton(
                                text: "رفض",
                                onPressed: () => _updateOrderStatus(
                                  order.id,
                                  app_models.OrderStatus.rejected
                                      .toString()
                                      .split(".")
                                      .last,
                                  order.clientId,
                                  "طلب مرفوض",
                                  "تم رفض طلبك من قبل الحرفي",
                                  order.id,
                                ),
                                width: 90,
                                height: 40,
                                backgroundColor: Colors.red,
                              ),
                            ],
                            if (order.status ==
                                app_models.OrderStatus.accepted) ...[
                              CustomButton(
                                text: "متابعة الطلب",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.craftsmanChat,
                                    arguments: {
                                      "orderId": order.id,
                                      "clientId": order.clientId,
                                      "clientName": clientName,
                                    },
                                  );
                                },
                                width: 130,
                                height: 40,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color getOrderStatusColor(app_models.OrderStatus status) {
    switch (status) {
      case app_models.OrderStatus.pending:
        return Colors.orange;
      case app_models.OrderStatus.accepted:
        return AppColors.success;
      case app_models.OrderStatus.rejected:
        return Colors.red;
      case app_models.OrderStatus.completed:
        return Colors.blue;
      case app_models.OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(
      String orderId,
      String status,
      String recipientId,
      String title,
      String body,
      String orderIdForNotification) async {
    try {
      await _service.updateOrderStatus(orderId, status);
      await _sendOrderNotification(
          recipientId, title, body, orderIdForNotification);
      setState(() {}); // Refresh the list
      showSnackBar("تم تحديث حالة الطلب");
    } catch (e) {
      showSnackBar("فشل تحديث الحالة: ${e.toString()}", isError: true);
    }
  }

  Future<void> _sendOrderNotification(
      String recipientId, String title, String body, String orderId) async {
    await _service.sendOrderNotification(recipientId, title, body,
        orderId: orderId);
  }
}
