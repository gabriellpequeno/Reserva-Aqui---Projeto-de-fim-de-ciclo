import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavbarVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) {
    state = visible;
  }
}

final navbarVisibleProvider = NotifierProvider<NavbarVisible, bool>(NavbarVisible.new);
