import 'package:cloud_firestore/cloud_firestore.dart';

/// 👤 أنواع المستخدمين في تطبيق حرفتي
/// تستخدم لتحديد صلاحيات كل مستخدم داخل التطبيق
enum UserRole { client, craftsman, admin }

/// 📦 حالات الطلب داخل التطبيق
/// مهمة جدًا لأنها تتحكم في دورة حياة الطلب من البداية للنهاية
enum OrderStatus { pending, accepted, rejected, completed, cancelled }

/// ===============================
/// 👤 User (المستخدم الأساسي)
/// ===============================
/// هذا هو القالب الأساسي لكل مستخدم في التطبيق:
/// - عميل
/// - حرفي
/// - مدير
class User {
  final String id; // معرف المستخدم في Firebase
  final String name; // اسم المستخدم
  final String email; // البريد الإلكتروني
  final UserRole role; // نوع المستخدم (عميل / حرفي / مدير)
  final String phone; // رقم الهاتف
  final String? profileImage; // صورة اختيارية (قد تكون null)
  final Timestamp createdAt; // تاريخ إنشاء الحساب
  final bool isActive; // هل الحساب مفعل؟

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    required this.isActive,
  });

  /// 🔄 copyWith
  /// يستخدم لتعديل جزء من البيانات بدون إنشاء كائن جديد بالكامل
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? profileImage,
    Timestamp? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 📤 تحويل الكائن إلى JSON لحفظه في Firebase
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.toString().split('.').last, // تحويل enum إلى نص
        'phone': phone,
        'profileImage': profileImage,
        'createdAt': createdAt,
        'isActive': isActive,
      };

  /// 📥 تحويل JSON من Firebase إلى كائن User
  static User fromJson(Map<String, dynamic> json, {String? id}) {
    final rawRole = json['role']?.toString() ?? '';
    final normalizedRole = rawRole.toLowerCase();

    /// 🔄 تحويل النص إلى enum
    final role = UserRole.values.firstWhere(
      (e) {
        final value = e.toString().split('.').last.toLowerCase();
        return value == normalizedRole ||
            e.toString().toLowerCase() == normalizedRole;
      },
      orElse: () => UserRole.client,
    );

    /// ⏱️ معالجة التاريخ (Firebase قد يرجعه بأكثر من شكل)
    final createdAtRaw = json['createdAt'];
    Timestamp createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is DateTime) {
      createdAt = Timestamp.fromDate(createdAtRaw);
    } else if (createdAtRaw is String) {
      createdAt =
          Timestamp.fromDate(DateTime.tryParse(createdAtRaw) ?? DateTime.now());
    } else {
      createdAt = Timestamp.now();
    }

    /// 🟢 معالجة الحالة (نشط أو غير نشط)
    final isActiveRaw = json['isActive'];
    final isActive = isActiveRaw is bool
        ? isActiveRaw
        : isActiveRaw?.toString().toLowerCase() == 'true';

    return User(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: role,
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}

/// ===============================
/// 👷 Craftsman (الحرفي)
/// ===============================
/// هذا المستخدم هو نفس User لكن مع بيانات إضافية خاصة بالحرفيين
class Craftsman extends User {
  final String profession; // نوع المهنة (سباك، كهربائي...)
  final int yearsOfExperience; // سنوات الخبرة
  final String city; // المدينة
  final String bio; // نبذة عن الحرفي
  final List<String> skills; // المهارات
  final double rating; // التقييم
  final int totalOrders; // عدد الطلبات
  final int totalReviews; // عدد التقييمات
  final List<String> portfolioImages; // صور الأعمال

  Craftsman({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.phone,
    super.profileImage,
    required super.createdAt,
    required super.isActive,
    required this.profession,
    required this.yearsOfExperience,
    required this.city,
    required this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.totalOrders = 0,
    this.totalReviews = 0,
    this.portfolioImages = const [],
  });

  /// 📤 تحويل الحرفي إلى JSON
  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'profession': profession,
        'yearsOfExperience': yearsOfExperience,
        'city': city,
        'bio': bio,
        'skills': skills,
        'rating': rating,
        'totalOrders': totalOrders,
        'totalReviews': totalReviews,
        'portfolioImages': portfolioImages,
      };

  /// 📥 تحويل JSON إلى Craftsman
  static Craftsman fromJson(Map<String, dynamic> json, {String? id}) =>
      Craftsman(
        id: id ?? json["id"] as String? ?? '',
        name: json["name"],
        email: json["email"],
        role: UserRole.values.firstWhere(
          (e) => e.toString().split(".").last == json["role"],
        ),
        phone: json["phone"],
        profileImage: json["profileImage"],
        createdAt: json["createdAt"] as Timestamp,
        isActive: json["isActive"],
        profession: json["profession"],
        yearsOfExperience: json["yearsOfExperience"],
        city: json["city"],
        bio: json["bio"],
        skills: List<String>.from(json["skills"] ?? []),
        rating: (json["rating"] as num?)?.toDouble() ?? 0.0,
        totalOrders: json["totalOrders"] ?? 0,
        totalReviews: json["totalReviews"] ?? 0,
        portfolioImages: List<String>.from(json["portfolioImages"] ?? []),
      );

  /// 🔄 تعديل بيانات الحرفي
  @override
  Craftsman copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? profileImage,
    Timestamp? createdAt,
    bool? isActive,
    String? profession,
    int? yearsOfExperience,
    String? city,
    String? bio,
    List<String>? skills,
    double? rating,
    int? totalOrders,
    int? totalReviews,
    List<String>? portfolioImages,
  }) {
    return Craftsman(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      profession: profession ?? this.profession,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      totalReviews: totalReviews ?? this.totalReviews,
      portfolioImages: portfolioImages ?? this.portfolioImages,
    );
  }
}

/// ===============================
/// 📦 Order (الطلب)
/// ===============================
/// يمثل الطلب الذي يربط العميل بالحرفي
class Order {
  final String id;
  final String clientId;
  final String craftsmanId;
  final String serviceDescription;
  final OrderStatus status;
  final double price;
  final Timestamp createdAt;
  final Timestamp scheduledDate;

  Order({
    required this.id,
    required this.clientId,
    required this.craftsmanId,
    required this.serviceDescription,
    required this.status,
    this.price = 0.0,
    required this.createdAt,
    required this.scheduledDate,
  });

  Order copyWith({
    String? id,
    String? clientId,
    String? craftsmanId,
    String? serviceDescription,
    OrderStatus? status,
    double? price,
    Timestamp? createdAt,
    Timestamp? scheduledDate,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      craftsmanId: craftsmanId ?? this.craftsmanId,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      status: status ?? this.status,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'craftsmanId': craftsmanId,
        'serviceDescription': serviceDescription,
        'status': status.toString().split('.').last,
        'price': price,
        'createdAt': createdAt,
        'scheduledDate': scheduledDate,
      };

  static Order fromJson(Map<String, dynamic> json, {String? id}) => Order(
        id: id ?? json['id'] as String? ?? '',
        clientId: json['clientId'],
        craftsmanId: json['craftsmanId'],
        serviceDescription: json['serviceDescription'],
        status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
        ),
        price: (json['price'] as num).toDouble(),
        createdAt: json['createdAt'] as Timestamp,
        scheduledDate: json['scheduledDate'] as Timestamp,
      );
}

/// ===============================
/// 🧾 Service (الخدمة)
/// ===============================
class Service {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'imageUrl': imageUrl,
      };

  static Service fromJson(Map<String, dynamic> json) => Service(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        category: json['category'],
        imageUrl: json['imageUrl'],
      );
}

/// ===============================
/// ⭐ Review (التقييم)
/// ===============================
class Review {
  final String id;
  final String clientId;
  final String clientName;
  final String craftsmanId;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.craftsmanId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'craftsmanId': craftsmanId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };

  static Review fromJson(Map<String, dynamic> json, {String? id}) => Review(
        id: id ?? json['id'] as String? ?? '',
        clientId: json['clientId'],
        clientName: json['clientName'],
        craftsmanId: json['craftsmanId'],
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'],
        createdAt: json['createdAt'] as Timestamp,
      );
}

/// ===============================
/// 💬 ChatMessage (الرسائل)
/// ===============================
class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final String? recipientId;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.recipientId,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "orderId": orderId,
        "senderId": senderId,
        "message": message,
        "timestamp": timestamp,
        "isRead": isRead,
        "recipientId": recipientId,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json["id"],
        orderId: json["orderId"],
        senderId: json["senderId"],
        message: json["message"],
        timestamp: json["timestamp"] as Timestamp,
        isRead: json["isRead"] ?? false,
        recipientId: json["recipientId"],
      );
}
