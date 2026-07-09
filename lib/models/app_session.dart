class AppSession {
  final String userId;
  final String role;
  final String name;
  final String level;
  final bool isRemote;

  const AppSession({
    required this.userId,
    required this.role,
    required this.name,
    required this.level,
    required this.isRemote,
  });

  bool get isTeacher {
    return role == 'teacher' || role == 'admin';
  }
}

class AppLoginResult {
  final AppSession? session;
  final String? errorMessage;

  const AppLoginResult._({required this.session, required this.errorMessage});

  factory AppLoginResult.success(AppSession session) {
    return AppLoginResult._(session: session, errorMessage: null);
  }

  factory AppLoginResult.failure(String message) {
    return AppLoginResult._(session: null, errorMessage: message);
  }

  bool get isSuccess {
    return session != null;
  }
}
