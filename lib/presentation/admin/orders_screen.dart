import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حالياً.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final order = app_models.Order.fromJson(orderData);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text('طلب: ${order.serviceDescription}'),
                  subtitle: Text('الحالة: ${order.status.toString().split('.').last}'),
                  leading: _getStatusIcon(order.status),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الطلب: ${order.id}'),
                          Text('السعر: ${order.price} ر.س'),
                          Text('تاريخ التنفيذ: ${order.scheduledDate.toDate().toString().split(' ')[0]}'),
                          const Divider(),
                          Text('معرف العميل: ${order.clientId}'),
                          Text('معرف الحرفي: ${order.craftsmanId}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(app_models.OrderStatus status) {
    IconData iconData;
    Color color;
    switch (status) {
      case app_models.OrderStatus.pending:
        iconData = Icons.timer;
        color = Colors.orange;
        break;
      case app_models.OrderStatus.accepted:
        iconData = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case app_models.OrderStatus.completed:
        iconData = Icons.verified;
        color = Colors.green;
        break;
      case app_models.OrderStatus.cancelled:
      case app_models.OrderStatus.rejected:
        iconData = Icons.cancel;
        color = Colors.red;
        break;
    }
    return Icon(iconData, color: color);
  }
}
