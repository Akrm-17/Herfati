import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class CraftsmanOrdersScreen extends StatefulWidget {
  const CraftsmanOrdersScreen({super.key});

  @override
  State<CraftsmanOrdersScreen> createState() => _CraftsmanOrdersScreenState();
}

class _CraftsmanOrdersScreenState extends State<CraftsmanOrdersScreen> with SingleTickerProviderStateMixin {
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
                            Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: getOrderStatusColor(order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(getOrderStatusText(order.status), style: TextStyle(color: getOrderStatusColor(order.status), fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("الخدمة: ${order.serviceDescription}"),
                        Text("السعر: ${order.price.toStringAsFixed(2)} ر.س"),
                        Text("التاريخ: ${formatTimestamp(order.scheduledDate)}"),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == app_models.OrderStatus.pending) ...[
                              ElevatedButton(onPressed: () => _service.updateOrderStatus(order.id, 'accepted'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("قبول")),
                              const SizedBox(width: 8),
                              ElevatedButton(onPressed: () => _service.updateOrderStatus(order.id, 'rejected'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("رفض")),
                            ] else if (status == app_models.OrderStatus.accepted) ...[
                              ElevatedButton(onPressed: () => _service.updateOrderStatus(order.id, 'completed'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold), child: const Text("إكمال")),
                            ],
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.craftsmanChat, arguments: {'orderId': order.id, 'clientId': order.clientId, 'clientName': clientName}),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkBlue),
                              child: const Text("محادثة"),
                            ),
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
}