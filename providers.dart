import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/app_database.dart';
import 'data/models.dart';

// ---------------- Main data ----------------
class AppData {
  final List<Note> notes;
  final List<TaskItem> tasks;
  final List<Category> categories;
  const AppData({required this.notes, required this.tasks, required this.categories});

  Category? categoryById(int? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class AppController extends StateNotifier<AsyncValue<AppData>> {
  AppController() : super(const AsyncValue.loading()) {
    load();
  }

  final _db = AppDatabase.instance;

  Future<void> load() async {
    try {
      state = AsyncValue.data(AppData(
        notes: await _db.notes(),
        tasks: await _db.tasks(),
        categories: await _db.categories(),
      ));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Notes
  Future<Note> saveNote(Note n) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final toSave = n.copyWith(updatedAt: now);
    Note result = toSave;
    if (n.id == null) {
      final id = await _db.insertNote(toSave);
      result = Note(
        id: id, title: toSave.title, description: toSave.description, color: toSave.color,
        categoryId: toSave.categoryId, pinned: toSave.pinned, favorite: toSave.favorite,
        archived: toSave.archived, trashed: toSave.trashed, createdAt: toSave.createdAt,
        updatedAt: toSave.updatedAt, blocks: toSave.blocks,
      );
    } else {
      await _db.updateNote(toSave);
    }
    await load();
    return result;
  }

  Future<void> duplicateNote(Note n) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insertNote(Note(
      title: n.title.isEmpty ? 'Copy' : '${n.title} (copy)',
      description: n.description, color: n.color, categoryId: n.categoryId,
      createdAt: now, updatedAt: now,
      blocks: n.blocks.map((b) => Block(id: newId() + b.id, type: b.type, text: b.text, checked: b.checked)).toList(),
    ));
    await load();
  }

  Future<void> deleteNoteForever(int id) async {
    await _db.deleteNote(id);
    await load();
  }

  // Categories
  Future<void> saveCategory(Category c) async {
    if (c.id == null) {
      await _db.insertCategory(c);
    } else {
      await _db.updateCategory(c);
    }
    await load();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await load();
  }

  // Tasks
  Future<TaskItem> saveTask(TaskItem t) async {
    TaskItem result = t;
    if (t.id == null) {
      final id = await _db.insertTask(t);
      result = TaskItem(
        id: id, title: t.title, description: t.description, dueAt: t.dueAt, priority: t.priority,
        done: t.done, categoryId: t.categoryId, noteId: t.noteId, remind: t.remind, createdAt: t.createdAt,
      );
    } else {
      await _db.updateTask(t);
    }
    await load();
    return result;
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    await load();
  }

  // Backup
  Future<Map<String, dynamic>> exportAll() => _db.exportAll();

  Future<void> restore(Map<String, dynamic> data) async {
    await _db.replaceAll(data);
    await load();
  }
}

final appProvider = StateNotifierProvider<AppController, AsyncValue<AppData>>((ref) => AppController());

// ---------------- Settings ----------------
class SettingsState {
  final ThemeMode themeMode;
  final int defaultNoteColor;
  final bool notificationsOn;
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.defaultNoteColor = 0,
    this.notificationsOn = true,
  });

  SettingsState copyWith({ThemeMode? themeMode, int? defaultNoteColor, bool? notificationsOn}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        defaultNoteColor: defaultNoteColor ?? this.defaultNoteColor,
        notificationsOn: notificationsOn ?? this.notificationsOn,
      );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _load();
  }

  final _db = AppDatabase.instance;

  Future<void> _load() async {
    final s = await _db.settings();
    state = SettingsState(
      themeMode: switch (s['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      defaultNoteColor: int.tryParse(s['defaultNoteColor'] ?? '') ?? 0,
      notificationsOn: (s['notifications'] ?? '1') == '1',
    );
  }

  Future<void> setThemeMode(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    await _db.setSetting('theme', m.name);
  }

  Future<void> setDefaultNoteColor(int i) async {
    state = state.copyWith(defaultNoteColor: i);
    await _db.setSetting('defaultNoteColor', '$i');
  }

  Future<void> setNotifications(bool on) async {
    state = state.copyWith(notificationsOn: on);
    await _db.setSetting('notifications', on ? '1' : '0');
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) => SettingsController());
