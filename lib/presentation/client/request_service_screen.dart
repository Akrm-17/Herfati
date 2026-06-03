import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class RequestServiceScreen extends StatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _craftsmanId;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _craftsmanId = ModalRoute.of(context)!.settings.arguments as String?;
    if (_craftsmanId == null) {
      showSnackBar("بيانات الحرفي غير مكتملة", isError: true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_craftsmanId == null) return;

      setState(() => _isLoading = true);

      try {
        final currentUser = await _firebaseService.getCurrentUser();
        if (currentUser == null) {
          showSnackBar("يجب تسجيل الدخول أولاً", isError: true);
          return;
        }

        final order = app_models.Order(
          id: '',
          clientId: currentUser.id,
          craftsmanId: _craftsmanId!,
          serviceDescription: _descriptionController.text,
          status: app_models.OrderStatus.pending,
          price: double.tryParse(_priceController.text) ?? 0.0,
          createdAt: Timestamp.now(),
          scheduledDate: Timestamp.fromDate(_selectedDate),
        );

        // استخدام firebase_service بدلاً من الاتصال المباشر
        await _firebaseService.createOrder(order);

        if (mounted) {
          showSnackBar('تم إرسال طلبك بنجاح');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showSnackBar('حدث خطأ: ${e.toString()}', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب خدمة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'تفاصيل الخدمة المطلوبة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف الخدمة',
                  border: OutlineInputBorder(),
                  hintText: 'اشرح ما تحتاجه بالتفصيل...',
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'يرجى إدخال الوصف' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الميزانية المقترحة (ر.س)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'يرجى إدخال السعر' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تاريخ الموعد'),
                subtitle: Text(formatDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('إرسال الطلب'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}