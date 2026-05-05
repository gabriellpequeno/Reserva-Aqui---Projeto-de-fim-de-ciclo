import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';

class NavbarVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) {
    state = visible;
  }
}

final navbarVisibleProvider = NotifierProvider<NavbarVisible, bool>(NavbarVisible.new);

// Set to a role after desktop login to trigger the profile modal in MainLayout.
class PostLoginProfile extends Notifier<AuthRole?> {
  @override
  AuthRole? build() => null;

  void trigger(AuthRole role) => state = role;
  void clear() => state = null;
}

final postLoginProfileProvider =
    NotifierProvider<PostLoginProfile, AuthRole?>(PostLoginProfile.new);
