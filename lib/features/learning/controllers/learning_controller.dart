import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../models/learning_lesson_model.dart';
import '../repositories/learning_repository.dart';

class LearningController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<LearningCategory> selectedCategory = LearningCategory.dailyDhikr.obs;
  final RxString searchQuery = ''.obs;
  final RxList<LearningLessonModel> lessons = <LearningLessonModel>[].obs;
  final RxSet<String> completedLessonIds = <String>{}.obs;
  final RxBool isPlayingAudio = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLessons();
    });
  }

  void loadLessons() {
    final savedCompleted =
        _storageService.read<List<dynamic>>('completed_lesson_ids') ?? [];
    completedLessonIds.assignAll(savedCompleted.map((e) => e.toString()));

    lessons.assignAll(
      LearningRepository.allLessons.map((lesson) {
        return lesson.copyWith(
          isCompleted: completedLessonIds.contains(lesson.id),
        );
      }).toList(),
    );
  }

  List<LearningLessonModel> get filteredLessons {
    return lessons.where((lesson) {
      final matchesCategory = lesson.category == selectedCategory.value;
      final query = searchQuery.value.trim().toLowerCase();
      if (query.isEmpty) {
        return matchesCategory;
      }
      final matchesSearch =
          lesson.title.toLowerCase().contains(query) ||
          lesson.transliteration.toLowerCase().contains(query) ||
          lesson.translation.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void selectCategory(LearningCategory category) {
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void markLessonCompleted(String lessonId) {
    completedLessonIds.add(lessonId);
    _storageService.write('completed_lesson_ids', completedLessonIds.toList());

    final index = lessons.indexWhere((l) => l.id == lessonId);
    if (index != -1) {
      lessons[index] = lessons[index].copyWith(isCompleted: true);
    }
  }

  int get totalCompletedCount => completedLessonIds.length;
}
