      import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/child_model.dart';
import 'api_service.dart';
import 'user_session.dart';

/// Central singleton that manages the authenticated parent's children.
/// Maintains the reactive list of registered children and currently selected active child.
class ChildSession {
  ChildSession._();
  static final ChildSession instance = ChildSession._();

  final ValueNotifier<List<ChildModel>> childrenNotifier = ValueNotifier<List<ChildModel>>([]);
  final ValueNotifier<ChildModel?> selectedChildNotifier = ValueNotifier<ChildModel?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  List<ChildModel> get children => childrenNotifier.value;
  ChildModel? get selectedChild => selectedChildNotifier.value;
  ChildModel? get activeChild => selectedChildNotifier.value;
  bool get hasChildren => children.isNotEmpty;

  String get activeChildName => (selectedChild?.name.trim().isNotEmpty == true)
      ? selectedChild!.name.trim()
      : 'Your Child';

  String get activeChildAge => selectedChild?.ageDisplay ?? '';

  /// Fetches children from the backend database for the authenticated parent.
  /// Automatically selects the first child if none is selected, or keeps selection if already active.
  Future<void> loadChildren({bool force = false}) async {
    final token = UserSession.instance.currentToken;
    if (token == null || token.isEmpty) {
      clear();
      return;
    }

    if (!force && children.isNotEmpty) {
      return;
    }

    isLoadingNotifier.value = true;
    try {
      final fetchedList = await ApiService.instance.fetchChildren();
      childrenNotifier.value = fetchedList;

      if (fetchedList.isEmpty) {
        selectedChildNotifier.value = null;
      } else {
        final currentSelected = selectedChildNotifier.value;
        if (currentSelected != null) {
          // If the previously selected child exists in new list, update reference
          final updated = fetchedList.cast<ChildModel?>().firstWhere(
                (c) => c?.id == currentSelected.id,
                orElse: () => null,
              );
          selectedChildNotifier.value = updated ?? fetchedList.first;
        } else {
          // Default to first child
          selectedChildNotifier.value = fetchedList.first;
        }
      }
    } catch (e) {
      debugPrint('[ChildSession] Error loading children: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Sets the currently active child across all screens in the app
  void selectChild(ChildModel child) {
    selectedChildNotifier.value = child;
  }

  /// Selects a child by database ID
  void selectChildById(int childId) {
    final match = children.cast<ChildModel?>().firstWhere(
          (c) => c?.id == childId,
          orElse: () => null,
        );
    if (match != null) {
      selectedChildNotifier.value = match;
    }
  }

  /// Updates a child's weight in the database and updates reactive app state
  Future<bool> updateWeight(int childId, double weight) async {
    try {
      final updatedChild = await ApiService.instance.updateChild(
        childId: childId,
        weight: weight,
      );

      if (updatedChild != null) {
        // Update item in children list
        final updatedList = children.map((c) {
          return c.id == childId ? updatedChild : c;
        }).toList();

        childrenNotifier.value = updatedList;

        // If the updated child was currently active, update active reference
        if (selectedChildNotifier.value?.id == childId) {
          selectedChildNotifier.value = updatedChild;
        }
        return true;
      }
    } catch (e) {
      debugPrint('[ChildSession] Error updating child weight: $e');
    }
    return false;
  }

  /// Adds a new child to the database and selects it as active
  Future<ChildModel?> addChild({
    required String name,
    required String dob,
    required String gender,
    double? weight,
  }) async {
    try {
      final newChild = await ApiService.instance.addChild(
        name: name,
        dob: dob,
        gender: gender,
        weight: weight,
      );

      if (newChild != null) {
        final updatedList = List<ChildModel>.from(children)..add(newChild);
        childrenNotifier.value = updatedList;
        selectedChildNotifier.value = newChild;
        return newChild;
      }
    } catch (e) {
      debugPrint('[ChildSession] Error adding child: $e');
    }
    return null;
  }

  /// Clears state on user logout
  void clear() {
    childrenNotifier.value = [];
    selectedChildNotifier.value = null;
    isLoadingNotifier.value = false;
  }
}

