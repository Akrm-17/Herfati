import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _firebaseService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          showSnackBar("تم تسجيل الدخول بنجاح");

          if (user.role == app_models.UserRole.client) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.clientHome);
          } else if (user.role == app_models.UserRole.craftsman) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.craftsmanHome);
          } else if (user.role == app_models.UserRole.admin) {
            Navigator.of(context)
                .pushReplacementNamed(AppRoutes.adminDashboard);
          }
        }
      } catch (e) {
        showSnackBar("حدث خطأ: ${e.toString()}", isError: true);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'مرحباً بك في حرفتي',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 32.0),
              CustomInputField(
                controller: _emailController,
                label: 'البريد الإلكتروني',
                hint: 'example@mail.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 16.0),
              CustomInputField(
                controller: _passwordController,
                label: 'كلمة المرور',
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: (value) =>
                    validateRequired(value, message: 'يرجى إدخال كلمة المرور'),
              ),
              const SizedBox(height: 32.0),
              CustomButton(
                text: 'دخول',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.signup);
                },
                child: const Text(
                  'ليس لديك حساب؟ إنشاء حساب جديد',
                  style: TextStyle(color: AppColors.primaryDarkBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
