import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class CraftsmanProfileEditScreen extends StatefulWidget {
  const CraftsmanProfileEditScreen({super.key});

  @override
  State<CraftsmanProfileEditScreen> createState() => _CraftsmanProfileEditScreenState();
}

class _CraftsmanProfileEditScreenState extends State<CraftsmanProfileEditScreen> {
  final FirebaseService _service = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearsController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedProfession;
  app_models.Craftsman? _craftsman;
  List<String> _portfolioImages = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _professions = const [
    "كهربائي", "سباك", "نجار", "دهان", "حداد",
    "فني تكييف", "فني ألمنيوم", "عامل بناء", "فني جبس وديكور",
    "فني كاميرات مراقبة", "فني شبكات وإنترنت", "أخرى"
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _service.getCurrentUser();
    if (user == null || user.role != app_models.UserRole.craftsman) {
      setState(() => _isLoading = false);
      showSnackBar('يرجى تسجيل الدخول كحرفي', isError: true);
      return;
    }
    final craftsman = await _service.getCraftsmanProfile(user.id);
    if (craftsman != null && mounted) {
      setState(() {
        _craftsman = craftsman;
        _nameController.text = craftsman.name;
        _phoneController.text = craftsman.phone;
        _bioController.text = craftsman.bio;
        _yearsController.text = craftsman.yearsOfExperience.toString();
        _cityController.text = craftsman.city;
        _selectedProfession = craftsman.profession;
        _portfolioImages = List.from(craftsman.portfolioImages);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      showSnackBar('لم نجد بيانات الحرفي', isError: true);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfession == null) {
      showSnackBar('اختر المهنة', isError: true);
      return;
    }
    if (_craftsman == null) return;

    setState(() => _isSaving = true);
    final updated = _craftsman!.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      yearsOfExperience: int.tryParse(_yearsController.text) ?? 0,
      city: _cityController.text.trim(),
      profession: _selectedProfession!,
      portfolioImages: _portfolioImages,
    );
    await _service.updateCraftsman(updated);
    setState(() {
      _craftsman = updated;
      _isSaving = false;
    });
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      dynamic file;
      if (kIsWeb) {
        file = await picked.readAsBytes();
      } else {
        file = File(picked.path);
      }
      final url = await _service.uploadProfileImage(_craftsman!.id, file);
      if (url != null && mounted) {
        final updated = _craftsman!.copyWith(profileImage: url);
        await _service.updateCraftsman(updated);
        setState(() {
          _craftsman = updated;
        });
        showSnackBar('تم تحديث الصورة الشخصية');
      } else {
        showSnackBar('فشل رفع الصورة', isError: true);
      }
    } catch (e) {
      showSnackBar('خطأ: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addPortfolioImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isSaving = true);
    try {
      dynamic file;
      if (kIsWeb) {
        file = await picked.readAsBytes();
      } else {
        file = File(picked.path);
      }
      final url = await _service.uploadPortfolioImage(_craftsman!.id, file);
      if (url != null && mounted) {
        setState(() {
          _portfolioImages.add(url);
        });
        await _service.updateCraftsmanPortfolio(_craftsman!.id, _portfolioImages);
        showSnackBar('تمت إضافة الصورة');
      } else {
        showSnackBar('فشل رفع الصورة', isError: true);
      }
    } catch (e) {
      showSnackBar('خطأ: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removePortfolioImage(int index) async {
    setState(() => _isSaving = true);
    _portfolioImages.removeAt(index);
    await _service.updateCraftsmanPortfolio(_craftsman!.id, _portfolioImages);
    setState(() => _isSaving = false);
    showSnackBar('تم حذف الصورة');
  }

  String? _validateYears(String? value) {
    if (value == null || value.isEmpty) return 'مطلوب';
    final intVal = int.tryParse(value);
    if (intVal == null || intVal < 0) return 'أدخل رقماً صحيحاً (0+)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text("الملف الشخصي")), body: const Center(child: CircularProgressIndicator()));
    }
    if (_craftsman == null) {
      return Scaffold(appBar: AppBar(title: const Text("الملف الشخصي")), body: const Center(child: Text("لا توجد بيانات")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("تعديل الملف الشخصي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _craftsman!.profileImage != null ? NetworkImage(_craftsman!.profileImage!) : null,
                      child: _craftsman!.profileImage == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _uploadProfileImage,
                      child: const Text("تغيير الصورة الشخصية"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "الاسم"), validator: (v) => v != null && v.isNotEmpty ? null : "مطلوب"),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "الهاتف"), validator: (v) => v != null && v.isNotEmpty ? null : "مطلوب"),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfession,
                items: _professions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _selectedProfession = v),
                decoration: const InputDecoration(labelText: "المهنة"),
                validator: (v) => v != null ? null : "اختر المهنة",
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _yearsController, decoration: const InputDecoration(labelText: "سنوات الخبرة"), keyboardType: TextInputType.number, validator: _validateYears),
              const SizedBox(height: 12),
              TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: "المدينة"), validator: (v) => v != null && v.isNotEmpty ? null : "مطلوب"),
              const SizedBox(height: 12),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: "نبذة"), maxLines: 3),
              const SizedBox(height: 24),
              const Text("معرض الأعمال", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _portfolioImages.isEmpty
                  ? const Text("لا توجد صور")
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _portfolioImages.length,
                      itemBuilder: (_, i) => Stack(
                        children: [
                          Image.network(_portfolioImages[i], fit: BoxFit.cover, width: double.infinity),
                          Positioned(
                            top: 0, right: 0,
                            child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _removePortfolioImage(i)),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _isSaving ? null : _addPortfolioImage, child: const Text("إضافة صورة للمعرض")),
              const SizedBox(height: 24),
              _isSaving ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updateProfile, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("حفظ الملف الشخصي")),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _service.signOut();
                  if (!mounted) return;
                  navigator.pushReplacementNamed(AppRoutes.login);
                },
                child: const Text("تسجيل الخروج"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}