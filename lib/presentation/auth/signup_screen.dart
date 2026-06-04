import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/core/utils.dart';
import 'package:herfatiapp/core/widgets.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _yearsOfExperienceController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _selectedProfession;

  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  app_models.UserRole _selectedRole = app_models.UserRole.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _yearsOfExperienceController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        showSnackBar("كلمات المرور غير متطابقة", isError: true);
        return;
      }

      if (_selectedRole == app_models.UserRole.craftsman &&
          _selectedProfession == null) {
        showSnackBar("يرجى اختيار المهنة", isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _firebaseService.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          role: _selectedRole.toString().split(".").last,
          profession: _selectedRole == app_models.UserRole.craftsman
              ? _selectedProfession
              : null,
          yearsOfExperience: _selectedRole == app_models.UserRole.craftsman
              ? int.tryParse(_yearsOfExperienceController.text)
              : null,
          city: _selectedRole == app_models.UserRole.craftsman
              ? _cityController.text.trim()
              : null,
          bio: _selectedRole == app_models.UserRole.craftsman
              ? _bioController.text.trim()
              : null,
        );

        if (user != null && mounted) {
          showSnackBar("تم إنشاء الحساب بنجاح. يرجى تسجيل الدخول.");
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
      appBar: AppBar(title: const Text("إنشاء حساب")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Text(
                "انضم إلينا الآن",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 32.0),
              CustomInputField(
                controller: _nameController,
                label: "الاسم الكامل",
                prefixIcon: Icons.person,
                validator: (value) =>
                    validateRequired(value, message: "يرجى إدخال اسمك"),
              ),
              const SizedBox(height: 16.0),
              CustomInputField(
                controller: _emailController,
                label: "البريد الإلكتروني",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 16.0),
              CustomInputField(
                controller: _passwordController,
                label: "كلمة المرور",
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال كلمة المرور";
                  }
                  if (value.length < 6) {
                    return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              CustomInputField(
                controller: _confirmPasswordController,
                label: "تأكيد كلمة المرور",
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى تأكيد كلمة المرور";
                  }
                  if (value != _passwordController.text) {
                    return "كلمات المرور غير متطابقة";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              CustomInputField(
                controller: _phoneController,
                label: "رقم الهاتف",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    validateRequired(value, message: "يرجى إدخال رقم الهاتف"),
              ),
              const SizedBox(height: 24.0),
              const Text(
                "نوع الحساب:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              SegmentedButton<app_models.UserRole>(
                segments: const [
                  ButtonSegment(
                    value: app_models.UserRole.client,
                    label: Text("عميل"),
                    icon: Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: app_models.UserRole.craftsman,
                    label: Text("حرفي"),
                    icon: Icon(Icons.handyman),
                  ),
                ],
                selected: <app_models.UserRole>{_selectedRole},
                onSelectionChanged: (Set<app_models.UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                    _selectedProfession = null;
                  });
                },
              ),
              if (_selectedRole == app_models.UserRole.craftsman)
                Column(
                  children: [
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProfession,
                      decoration: const InputDecoration(
                        labelText: "المهنة",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      hint: const Text("اختر المهنة"),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedProfession = newValue;
                        });
                      },
                      validator: (value) {
                        if (_selectedRole == app_models.UserRole.craftsman &&
                            (value == null || value.isEmpty)) {
                          return "يرجى اختيار المهنة";
                        }
                        return null;
                      },
                      items: Professions.all
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _yearsOfExperienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "سنوات الخبرة",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (_selectedRole == app_models.UserRole.craftsman) {
                          if (value == null || value.isEmpty) {
                            return "يرجى إدخال سنوات الخبرة";
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0) {
                            return "الرجاء إدخال رقم صالح";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: "المدينة",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (_selectedRole == app_models.UserRole.craftsman &&
                            (value == null || value.isEmpty)) {
                          return "يرجى إدخال المدينة";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "نبذة عنك (Bio)",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      validator: (value) {
                        if (_selectedRole == app_models.UserRole.craftsman &&
                            (value == null || value.isEmpty)) {
                          return "يرجى إدخال نبذة عنك";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 32.0),
              CustomButton(
                text: "إنشاء الحساب",
                onPressed: _signup,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
                child: const Text(
                  "لديك حساب بالفعل؟ سجل دخولك",
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
