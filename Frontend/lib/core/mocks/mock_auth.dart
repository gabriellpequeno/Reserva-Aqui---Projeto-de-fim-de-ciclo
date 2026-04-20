enum UserRole { guest, user, host, admin }

class MockAuth {
  // Troque aqui para testar o roteamento do app localmente com perfis diferentes
  static const UserRole currentUserRole = UserRole.host;
  static const bool isLoggedIn = currentUserRole != UserRole.guest;
}
