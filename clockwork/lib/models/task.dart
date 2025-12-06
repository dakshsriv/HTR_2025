import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? courseId;
  final int estimatedMinutes; // For determining if micro-steps are needed
  final List<MicroStep> microSteps;
  final int energyCost; // 1-5 lightning bolts
  final int completedCount; // For tracking Break Nudge

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.courseId,
    this.estimatedMinutes = 0,
    this.microSteps = const [],
    this.energyCost = 3,
    this.completedCount = 0,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? courseId,
    int? estimatedMinutes,
    List<MicroStep>? microSteps,
    int? energyCost,
    int? completedCount,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      courseId: courseId ?? this.courseId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      microSteps: microSteps ?? this.microSteps,
      energyCost: energyCost ?? this.energyCost,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'courseId': courseId,
      'estimatedMinutes': estimatedMinutes,
      'microSteps': microSteps.map((m) => m.toJson()).toList(),
      'energyCost': energyCost,
      'completedCount': completedCount,
    };
  }

  // Create from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      courseId: json['courseId'],
      estimatedMinutes: json['estimatedMinutes'] ?? 0,
      microSteps: (json['microSteps'] as List?)
              ?.map((m) => MicroStep.fromJson(m))
              .toList() ??
          [],
      energyCost: json['energyCost'] ?? 3,
      completedCount: json['completedCount'] ?? 0,
    );
  }

  // Check if task needs micro-steps (over 45 minutes)
  bool needsMicroSteps() {
    return estimatedMinutes > 45 && microSteps.isEmpty;
  }

  // Check if task is aging (3+ days old)
  bool isAging() {
    final now = DateTime.now();
    final ageInDays = now.difference(createdAt).inDays;
    return ageInDays >= 3 && !isCompleted;
  }

  // Get aging opacity (0.3 for 3+ days old, 1.0 for recent)
  double getAgingOpacity() {
    final now = DateTime.now();
    final ageInDays = now.difference(createdAt).inDays;
    if (ageInDays >= 3) {
      return 0.5; // Faded
    }
    return 1.0; // Full opacity
  }
}

class MicroStep {
  final String id;
  final String title;
  final bool isCompleted;
  final int orderIndex;

  MicroStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.orderIndex,
  });

  MicroStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? orderIndex,
  }) {
    return MicroStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'orderIndex': orderIndex,
    };
  }

  factory MicroStep.fromJson(Map<String, dynamic> json) {
    return MicroStep(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      orderIndex: json['orderIndex'] ?? 0,
    );
  }
}
