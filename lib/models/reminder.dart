import 'package:flutter/material.dart';

enum CategoryType {
  medication,
  appointment,
  family,
  task,
  other,
}

extension CategoryTypeExtension on CategoryType {
  String get label {
    switch (this) {
      case CategoryType.medication:
        return 'Medicação';
      case CategoryType.appointment:
        return 'Consulta';
      case CategoryType.family:
        return 'Família';
      case CategoryType.task:
        return 'Tarefa';
      case CategoryType.other:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryType.medication:
        return Icons.medical_services;
      case CategoryType.appointment:
        return Icons.local_hospital;
      case CategoryType.family:
        return Icons.favorite;
      case CategoryType.task:
        return Icons.check_circle;
      case CategoryType.other:
        return Icons.star;
    }
  }

  Color get color {
    switch (this) {
      case CategoryType.medication:
        return const Color(0xFFFFB4A2);
      case CategoryType.appointment:
        return const Color(0xFFB4D4FF);
      case CategoryType.family:
        return const Color(0xFFFFC9DE);
      case CategoryType.task:
        return const Color(0xFFB4E5C7);
      case CategoryType.other:
        return const Color(0xFFFFE5B4);
    }
  }
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
}

extension RecurrenceTypeExtension on RecurrenceType {
  String get label {
    switch (this) {
      case RecurrenceType.none:
        return 'Não repetir';
      case RecurrenceType.daily:
        return 'Todos os dias';
      case RecurrenceType.weekly:
        return 'Toda semana';
      case RecurrenceType.monthly:
        return 'Todo mês';
    }
  }
}

class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final CategoryType category;
  final RecurrenceType recurrence;
  final bool isCompleted;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.category,
    this.recurrence = RecurrenceType.none,
    this.isCompleted = false,
  });

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    CategoryType? category,
    RecurrenceType? recurrence,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // ============================================
  // 💾 JSON local (SharedPreferences) - mantido por compatibilidade
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'category': category.index,
      'recurrence': recurrence.index,
      'isCompleted': isCompleted,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      category: CategoryType.values[json['category']],
      recurrence: RecurrenceType.values[json['recurrence'] ?? 0],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // ============================================
  // ☁️ SUPABASE - conversão pra/de
  // ============================================
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'titulo': title,
      'descricao': description,
      'data_hora': dateTime.toIso8601String(),
      'categoria': category.name, // salva o nome do enum (ex: "medication")
      'recorrencia': recurrence.index,
      'concluido': isCompleted,
    };
  }

  factory Reminder.fromSupabase(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'].toString(),
      title: json['titulo'] ?? '',
      description: json['descricao'],
      dateTime: DateTime.parse(json['data_hora']),
      category: _parseCategoria(json['categoria']),
      recurrence: RecurrenceType.values[json['recorrencia'] ?? 0],
      isCompleted: json['concluido'] ?? false,
    );
  }

  static CategoryType _parseCategoria(dynamic value) {
    if (value == null) return CategoryType.other;
    final str = value.toString();
    try {
      return CategoryType.values.firstWhere((c) => c.name == str);
    } catch (_) {
      return CategoryType.other; // fallback se vier algo desconhecido
    }
  }
}