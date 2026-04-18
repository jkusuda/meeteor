import 'package:flutter/material.dart';
import 'package:meeteor/main.dart';

// Data models
class ChallengeSubmission {
  final String username;
  final String imageUrl;
  final String note;
  final String gear;
  final String timeAgo;
  final Color accentColor;
  final DateTime? completedAt;

  const ChallengeSubmission({
    required this.username,
    required this.imageUrl,
    required this.note,
    required this.gear,
    required this.timeAgo,
    required this.accentColor,
    this.completedAt,
  });
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime activationDate;
  final String iconName;
  final List<String> tips;
  final List<ChallengeSubmission> submissions;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.activationDate,
    required this.iconName,
    required this.tips,
    required this.submissions,
    this.isCompleted = false,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? activationDate,
    String? iconName,
    List<String>? tips,
    List<ChallengeSubmission>? submissions,
    bool? isCompleted,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      activationDate: activationDate ?? this.activationDate,
      iconName: iconName ?? this.iconName,
      tips: tips ?? this.tips,
      submissions: submissions ?? this.submissions,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory DailyChallenge.fromMap(Map<String, dynamic> row) {
    final tipsRaw = row['tips'];
    final tips = tipsRaw is List
        ? tipsRaw.map((tip) => tip.toString()).toList()
        : const <String>[];

    return DailyChallenge(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? 'Challenge').toString(),
      description: (row['description'] ?? '').toString(),
      imageUrl: (row['imageURL'] ?? row['image_url'] ?? '').toString(),
      activationDate:
          _parseDate(row['activation_date']) ??
          _parseDate(row['created_at']) ??
          DateTime.now(),
      iconName: (row['icon'] ?? row['icon_name'] ?? 'star').toString(),
      tips: tips,
      submissions: const [],
      isCompleted: false,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

IconData iconForName(String iconName) {
  switch (iconName) {
    case 'camera':
      return Icons.camera_alt_rounded;
    case 'moon':
      return Icons.nightlight_round_rounded;
    case 'star':
    default:
      return Icons.star_rounded;
  }
}

Color highlightForIndex(int index) {
  const palette = [
    Color(0xFFFCB454),
    Color(0xFF7E6AD8),
    Color(0xFF4FD1C5),
    Color(0xFFF37F8D),
    Color(0xFF9A8CFF),
  ];
  return palette[index % palette.length];
}

String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

DateTime normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String relativeDateLabel(DateTime activationDate) {
  final today = DateTime.now();
  final a = DateTime(
    activationDate.year,
    activationDate.month,
    activationDate.day,
  );
  final t = DateTime(today.year, today.month, today.day);
  final days = t.difference(a).inDays;

  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days > 1) return '$days days ago';
  if (days == -1) return 'Tomorrow';
  return 'In ${-days} days';
}

String submissionTimeLabel(DateTime? completedAt) {
  if (completedAt == null) return 'Now';

  final diff = DateTime.now().difference(completedAt);
  if (diff.isNegative || diff.inMinutes < 60) return 'Now';

  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }

  final days = diff.inDays;
  return days == 1 ? '1 day ago' : '$days days ago';
}

class ChallengeBadge extends StatelessWidget {
  final String label;
  final double fontSize;

  const ChallengeBadge({super.key, required this.label, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.honeyBronze,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.prussianBlue,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

Widget buildChallengeImage({
  required String imagePath,
  required BoxFit fit,
  String? iconName,
  Widget Function()? fallbackBuilder,
}) {
  final fallback =
      fallbackBuilder ??
      () => Container(
        color: AppColors.spaceIndigo,
        alignment: Alignment.center,
        child: Icon(
          iconForName(iconName ?? 'star'),
          size: 72,
          color: AppColors.honeyBronze,
        ),
      );

  if (imagePath.isEmpty) return fallback();

  if (imagePath.startsWith('assets/')) {
    return Image.asset(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }

  return Image.network(
    imagePath,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => fallback(),
  );
}
