import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SubjectModel {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color lightColor;
  final int totalTopics;
  final int completedTopics;
  final int questionsCount;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.totalTopics,
    required this.completedTopics,
    required this.questionsCount,
  });

  double get progress =>
      totalTopics > 0 ? completedTopics / totalTopics : 0.0;
}

final List<SubjectModel> smpSubjects = [
  SubjectModel(
    id: 'math',
    name: 'Matematika',
    emoji: '📐',
    color: AppColors.math,
    lightColor: AppColors.primarySurface,
    totalTopics: 24,
    completedTopics: 8,
    questionsCount: 240,
  ),
  SubjectModel(
    id: 'science',
    name: 'IPA',
    emoji: '🔬',
    color: AppColors.science,
    lightColor: AppColors.successSurface,
    totalTopics: 20,
    completedTopics: 5,
    questionsCount: 200,
  ),
  SubjectModel(
    id: 'social',
    name: 'IPS',
    emoji: '🌍',
    color: AppColors.social,
    lightColor: AppColors.accentSurface,
    totalTopics: 18,
    completedTopics: 3,
    questionsCount: 180,
  ),
  SubjectModel(
    id: 'indonesian',
    name: 'B. Indonesia',
    emoji: '📚',
    color: AppColors.indonesian,
    lightColor: AppColors.errorSurface,
    totalTopics: 22,
    completedTopics: 12,
    questionsCount: 220,
  ),
  SubjectModel(
    id: 'english',
    name: 'B. Inggris',
    emoji: '🇬🇧',
    color: AppColors.english,
    lightColor: Color(0xFFEFF6FF),
    totalTopics: 20,
    completedTopics: 7,
    questionsCount: 200,
  ),
  SubjectModel(
    id: 'civics',
    name: 'PKN',
    emoji: '🏛️',
    color: AppColors.civics,
    lightColor: Color(0xFFF5F3FF),
    totalTopics: 15,
    completedTopics: 4,
    questionsCount: 150,
  ),
  SubjectModel(
    id: 'religion',
    name: 'Ag. Islam',
    emoji: '✨',
    color: AppColors.religion,
    lightColor: Color(0xFFFDF2F8),
    totalTopics: 16,
    completedTopics: 6,
    questionsCount: 160,
  ),
  SubjectModel(
    id: 'arts',
    name: 'Seni Budaya',
    emoji: '🎨',
    color: AppColors.arts,
    lightColor: Color(0xFFFFF7ED),
    totalTopics: 12,
    completedTopics: 2,
    questionsCount: 120,
  ),
];
