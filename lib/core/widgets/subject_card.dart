import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../theme/app_text_styles.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: subject.lightColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: subject.color.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: subject.color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    subject.icon,
                    color: subject.color,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                subject.name,
                style: AppTextStyles.label.copyWith(
                  color: subject.color,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: subject.progress,
                  minHeight: 6,
                  backgroundColor: subject.color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${subject.completedTopics}/${subject.totalTopics} topik',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
