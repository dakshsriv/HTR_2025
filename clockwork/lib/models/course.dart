import 'package:flutter/material.dart';

class Course {
  final String id;
  final String name;
  final Color color;
  final int colorValue; // Store color as int for serialization

  Course({
    required this.id,
    required this.name,
    required this.color,
  }) : colorValue = color.value;

  Course copyWith({
    String? id,
    String? name,
    Color? color,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      color: Color(json['colorValue']),
    );
  }
}
