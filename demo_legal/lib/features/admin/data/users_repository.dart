import '../../../core/domain/user_role.dart';
import '../../../demo/demo_store.dart';
import '../../tasks/data/live_changes.dart';
import '../../tasks/data/task_file.dart';
import 'managed_user.dart';
import 'user_save_failure.dart';

/// Accounts for the admin users page (ADR-0006).
///
/// Demo build: reads and writes [DemoStore], with the production guards
/// re-stated: admins only, nobody with open tasks is deactivated, and a
/// lawyer can't be taken off a file where they still have open tasks.
class UsersRepository {
  UsersRepository(this._store);

  final DemoStore _store;

  /// Every account, inactive ones too, oldest first.
  Future<List<ManagedUser>> fetchUsers() async {
    await _store.latency();
    _requireAdmin();
    return [
      for (final p in _store.profiles)
        ManagedUser(
          id: p.id,
          displayName: p.displayName,
          email: p.email,
          role: p.role,
          isActive: p.isActive,
          fileIds: {...p.fileIds},
        ),
    ];
  }

  /// Files for the membership checkboxes, oldest first like the chips.
  Future<List<TaskFile>> fetchFiles() async => [for (final f in _store.files) TaskFile(id: f.id, name: f.name)];

  /// Creates an account with a first password and returns its id.
  ///
  /// Throws [UserSaveException].
  Future<String> createUser({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    required Set<String>? fileIds,
  }) async {
    await _store.latency();
    _requireAdmin();
    final normalized = email.trim().toLowerCase();
    if (_store.profiles.any((p) => p.email.toLowerCase() == normalized)) {
      throw const UserSaveException(UserSaveFailure.emailTaken);
    }
    if (password.length < 8) throw const UserSaveException(UserSaveFailure.weakPassword);
    final p = DemoProfile(
      id: _store.id('p'),
      displayName: displayName.trim(),
      email: normalized,
      role: role,
      createdAt: _store.now,
      fileIds: role == UserRole.lawyer ? {...?fileIds} : {},
      password: password,
    );
    _store.profiles.add(p);
    _store.changed(LiveTable.profiles);
    return p.id;
  }

  /// Saves a user's name and role and, unless [fileIds] is null, makes their
  /// memberships exactly [fileIds].
  ///
  /// Throws [UserSaveException].
  Future<void> saveUser(
    String id, {
    required String displayName,
    required UserRole role,
    required Set<String>? fileIds,
  }) async {
    await _store.latency();
    _requireAdmin();
    final p = _store.profile(id);
    if (p == null) throw const UserSaveException(UserSaveFailure.notAllowed);
    final openFiles = {
      for (final t in _store.tasks)
        if (t.assigneeId == id && !t.status.isClosed) _store.fileIdOfTask(t),
    };
    if (role == UserRole.lawyer) {
      final target = fileIds ?? p.fileIds;
      final outside = openFiles.difference(target);
      if (outside.isNotEmpty) {
        throw UserSaveException(
            p.role == UserRole.lawyer ? UserSaveFailure.openTasksInFile : UserSaveFailure.openTasksOutsideFiles);
      }
    }
    p
      ..displayName = displayName.trim()
      ..role = role;
    if (fileIds != null) {
      p.fileIds
        ..clear()
        ..addAll(fileIds);
    }
    _store.changed(LiveTable.profiles);
    _store.changed(LiveTable.fileMembers);
  }

  /// Deactivates or reactivates an account. Nobody with open tasks is
  /// deactivated: reassign them first.
  ///
  /// Throws [UserSaveException].
  Future<void> setActive(String id, {required bool active}) async {
    await _store.latency();
    final viewer = _requireAdmin();
    final p = _store.profile(id);
    if (p == null || p.id == viewer.id) throw const UserSaveException(UserSaveFailure.notAllowed);
    if (!active && _store.tasks.any((t) => t.assigneeId == id && !t.status.isClosed)) {
      throw const UserSaveException(UserSaveFailure.openTasks);
    }
    p.isActive = active;
    _store.changed(LiveTable.profiles);
  }

  /// Gives an account a new password.
  ///
  /// Throws [UserSaveException].
  Future<void> setPassword(String id, String password) async {
    await _store.latency();
    _requireAdmin();
    if (password.length < 8) throw const UserSaveException(UserSaveFailure.weakPassword);
    final p = _store.profile(id);
    if (p == null) throw const UserSaveException(UserSaveFailure.notAllowed);
    p.password = password;
  }

  DemoProfile _requireAdmin() {
    final viewer = _store.requireViewer();
    if (viewer.role != UserRole.admin) throw const UserSaveException(UserSaveFailure.notAllowed);
    return viewer;
  }
}
