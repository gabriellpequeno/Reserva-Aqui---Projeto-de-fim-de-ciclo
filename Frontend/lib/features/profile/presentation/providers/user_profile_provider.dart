import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile_model.dart';
import '../../../../utils/Usuario.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfileModel> {
  @override
  Future<UserProfileModel> build() async {
    final completer = Completer<UserProfileModel>();

    ref.read(usuarioServiceProvider).getAutenticado(
      onSuccess: (data) =>
          completer.complete(UserProfileModel.fromJson(data)),
      onError: (message) =>
          completer.completeError(Exception(message)),
    );

    return completer.future;
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileModel>(
  UserProfileNotifier.new,
);
