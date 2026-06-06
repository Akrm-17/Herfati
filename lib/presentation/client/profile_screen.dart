import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

// Client Profile Screen
// Arabic: شاشة الملف الشخصي للعميل لعرض وتحرير معلومات الحساب الأساسية.
// English: Shows client's profile details and allows basic edits.

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  app_models.User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final user = await _firebaseService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'الرجاء تسجيل الدخول';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل بيانات المستخدم: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
      );
      await _firebaseService.updateUser(updatedUser);
      setState(() {
        _isLoading = false;
        _currentUser = updatedUser;
      });
      showSnackBar('تم تحديث الملف الشخصي بنجاح');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar('فشل تحديث البيانات: ${e.toString()}', isError: true);
    }
  }

  Future<void> _logout() async {
    await _firebaseService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("الملف الشخصي")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("الملف الشخصي")),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("الملف الشخصي")),
        body: const Center(child: Text("لا توجد بيانات متاحة.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _currentUser!.profileImage != null
                    ? NetworkImage(_currentUser!.profileImage!)
                    : null,
                child: _currentUser!.profileImage == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showSnackBar('تغيير صورة الملف الشخصي - قريباً!');
                },
                child: const Text('تحديث الصورة الشخصية'),
              ),
            ),
            const SizedBox(height: 32.0),
            CustomInputField(
              controller: _nameController,
              label: 'الاسم',
              validator: (value) =>
                  validateRequired(value, message: 'يرجى إدخال الاسم'),
            ),
            const SizedBox(height: 16.0),
            CustomInputField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  validateRequired(value, message: 'يرجى إدخال رقم الهاتف'),
            ),
            const SizedBox(height: 32.0),
            CustomButton(
              text: 'حفظ الملف الشخصي',
              onPressed: _updateProfile,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16.0),
            CustomButton(
              text: 'تسجيل الخروج',
              onPressed: _logout,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
