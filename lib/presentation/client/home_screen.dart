import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<app_models.Craftsman> _allCraftsmen = [];
  List<app_models.Craftsman> _filteredCraftsmen = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchAllCraftsmen();
  }

  Future<void> _fetchAllCraftsmen() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final craftsmen = await _firebaseService.getRecommendedCraftsmen();
      setState(() {
        _allCraftsmen = craftsmen;
        _filteredCraftsmen = craftsmen;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar("فشل تحميل الحرفيين: ${e.toString()}", isError: true);
    }
  }

  void _filterCraftsmen() {
    setState(() {
      _filteredCraftsmen = _allCraftsmen.where((craftsman) {
        final name = craftsman.name;
        final profession = craftsman.profession;
        final city = craftsman.city;

        final matchesSearch = _searchQuery.isEmpty ||
            name.contains(_searchQuery) ||
            profession.contains(_searchQuery) ||
            city.contains(_searchQuery);

        final matchesCategory =
            _selectedCategory == null || profession == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _filterCraftsmen();
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterCraftsmen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حرفتي'),
        backgroundColor: AppColors.primaryDarkBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.clientMyOrders);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.clientProfile);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، المهنة، أو المدينة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _onSearchChanged("");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'التصنيفات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: Categories.all.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: const Text("الكل"),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          _onCategorySelected(null);
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor:
                            AppColors.primaryGold.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primaryGold,
                      ),
                    );
                  }
                  final category = Categories.all[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        _onCategorySelected(selected ? category : null);
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor:
                          AppColors.primaryGold.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primaryGold,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'جميع الحرفيين',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCraftsmen.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                "لا توجد حرفيون مطابقون لبحثك",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchQuery = "";
                                  _selectedCategory = null;
                                  _fetchAllCraftsmen();
                                },
                                child: const Text("مسح جميع الفلاتر"),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredCraftsmen.length,
                          itemBuilder: (context, index) {
                            final craftsman = _filteredCraftsmen[index];
                            final name = craftsman.name;
                            final profession = craftsman.profession;
                            final city = craftsman.city;
                            final rating = craftsman.rating;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage:
                                          craftsman.profileImage != null
                                              ? NetworkImage(
                                                  craftsman.profileImage!)
                                              : null,
                                      child: craftsman.profileImage == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            profession,
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(rating.toStringAsFixed(1)),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.location_city,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                city,
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        print('CRAFTSMAN ID = ${craftsman.id}');

                                        Navigator.of(context).pushNamed(
                                          '${AppRoutes.clientCraftsmanDetails}/${craftsman.id}',
                                          arguments: craftsman.id,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGold,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('عرض الملف'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
