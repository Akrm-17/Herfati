import 'package:flutter/material.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

// Admin Orders Screen
// Arabic: شاشة إدارة جميع الطلبات في النظام للمشرف.
// English: Lists all orders and allows admin actions like delete or status change.

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
      ),
      body: StreamBuilder<List<app_models.Order>>(
        stream: service.streamAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حالياً.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text('طلب: ${order.serviceDescription}'),
                  subtitle: Text(
                      'الحالة: ${order.status.toString().split('.').last}'),
                  leading: _getStatusIcon(order.status),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteOrderDialog(context, order.id);
                      } else {
                        _showUpdateOrderStatusDialog(context, order);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'status',
                        child: Text('تغيير الحالة'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف الطلب',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الطلب: ${order.id}'),
                          Text('السعر: ${order.price} ر.س'),
                          Text(
                              'تاريخ التنفيذ: ${order.scheduledDate.toDate().toString().split(' ')[0]}'),
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

  void _showDeleteOrderDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل تريد حذف هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseService().deleteOrder(orderId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showUpdateOrderStatusDialog(
      BuildContext context, app_models.Order order) {
    const statuses = app_models.OrderStatus.values;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير حالة الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return RadioListTile<app_models.OrderStatus>(
              title: Text(status.toString().split('.').last),
              value: status,
              groupValue: status == order.status ? status : null,
              onChanged: (selected) async {
                if (selected != null) {
                  await FirebaseService().updateOrderStatus(
                      order.id, selected.toString().split('.').last);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
