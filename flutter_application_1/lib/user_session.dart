class UserSession {
  static String? email;

  static bool get isLoggedIn => email != null;

  static void logout() {
    email = null;
  }
}
