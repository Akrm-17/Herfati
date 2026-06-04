import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/models.dart' as app_models;

// دالة للتحقق من صحة البريد الإلكتروني
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'يرجى إدخال البريد الإلكتروني';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value)) {
    return 'يرجى إدخال بريد إلكتروني صالح';
  }
  return null;
}

String? validateRequired(String? value, {String message = 'يرجى إدخال هذا الحقل'}) {
  if (value == null || value.isEmpty) {
    return message;
  }
  return null;
}

String? validatePositiveNumber(String? value, {String message = 'يرجى إدخال رقم صالح'}) {
  if (value == null || value.isEmpty) {
    return 'يرجى إدخال هذا الحقل';
  }
  final number = double.tryParse(value);
  if (number == null || number < 0) {
    return message;
  }
  return null;
}

// دالة لتنسيق التاريخ
String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// دالة لتنسيق Timestamp من Firestore
String formatTimestamp(Timestamp timestamp) {
  return formatDate(timestamp.toDate());
}

// دالة للحصول على لون الحالة
Color getOrderStatusColor(app_models.OrderStatus status) {
  switch (status) {
    case app_models.OrderStatus.pending:
      return AppColors.warning;
    case app_models.OrderStatus.accepted:
      return Colors.blue;
    case app_models.OrderStatus.completed:
      return AppColors.success;
    case app_models.OrderStatus.cancelled:
    case app_models.OrderStatus.rejected:
      return AppColors.error;
  }
}

// دالة للحصول على نص الحالة بالعربية
String getOrderStatusText(app_models.OrderStatus status) {
  switch (status) {
    case app_models.OrderStatus.pending:
      return 'قيد الانتظار';
    case app_models.OrderStatus.accepted:
      return 'مقبول';
    case app_models.OrderStatus.completed:
      return 'مكتمل';
    case app_models.OrderStatus.cancelled:
      return 'ملغي';
    case app_models.OrderStatus.rejected:
      return 'مرفوض';
  }
}

// دالة لحساب متوسط التقييم
double calculateAverageRating(List<app_models.Review> reviews) {
  if (reviews.isEmpty) return 0.0;
  final sum = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
  return sum / reviews.length;
}