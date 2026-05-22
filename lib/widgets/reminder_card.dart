import 'package:flutter/material.dart';
import '../models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggleComplete,
    required this.onDelete,
  });

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(dt.year, dt.month, dt.day);
    final difference = reminderDay.difference(today).inDays;

    String dayLabel;
    if (difference == 0) {
      dayLabel = 'Hoje';
    } else if (difference == 1) {
      dayLabel = 'Amanhã';
    } else if (difference == -1) {
      dayLabel = 'Ontem';
    } else {
      dayLabel = '${dt.day}/${dt.month}/${dt.year}';
    }

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayLabel às $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggleComplete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: reminder.isCompleted
                        ? Colors.green.shade300
                        : Colors.transparent,
                    border: Border.all(
                      color: reminder.isCompleted
                          ? Colors.green.shade300
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(reminder.category.icon,
                            size: 16, color: const Color(0xFF4A4A4A)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reminder.category.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            reminder.category.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                        ),
                        if (reminder.recurrence != RecurrenceType.none) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB4D4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🔁 ${reminder.recurrence.label}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A4A4A),
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(reminder.dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}