import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

// ── State ─────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── DeviceId ──────────────────────────────────────────────────────────────────

const _deviceIdKey = 'chat_device_id';

Future<String> _getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString(_deviceIdKey);
  if (deviceId == null || deviceId.isEmpty) {
    final rng = Random.secure();
    deviceId = '${DateTime.now().microsecondsSinceEpoch}-'
        '${rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}-'
        '${rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    await prefs.setString(_deviceIdKey, deviceId);
  }
  return deviceId;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ChatState> {
  String? _hotelId;

  @override
  ChatState build() {
    return const ChatState();
  }

  void setHotelId(String? hotelId) {
    _hotelId = hotelId;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isMe: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final dio = ref.read(dioProvider);
      final deviceId = await _getOrCreateDeviceId();

      final body = <String, dynamic>{
        'message': text.trim(),
        'deviceId': deviceId,
      };
      if (_hotelId != null && _hotelId!.isNotEmpty) {
        body['hotelId'] = _hotelId;
      }

      final response = await dio.post(
        '/chat/message',
        data: body,
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? 'Sem resposta';
      final sessionId = data['sessionId'] as String?;

      final botMessage = ChatMessage(
        text: reply,
        isMe: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
        sessionId: sessionId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro de conexão. Verifique sua internet e tente novamente.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
