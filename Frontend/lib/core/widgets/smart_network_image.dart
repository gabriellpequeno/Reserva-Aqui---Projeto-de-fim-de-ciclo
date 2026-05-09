import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../theme/app_colors.dart';

// ─── Hotel mock images (deterministic via hotelId.hashCode) ──────────────────

const _hotelMocks = <String>[
  'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
  'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80',
  'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80',
  'https://images.unsplash.com/photo-1455587734955-081b22074882?w=800&q=80',
  'https://images.unsplash.com/photo-1535827841776-24afc1e255ac?w=800&q=80',
  'https://images.unsplash.com/photo-1551882547-ff40c4a49f9b?w=800&q=80',
  'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',
  'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
];

// ─── Room mock images pool (ordered by quality/variety) ──────────────────────
// These 8 URLs are distinct room photos used to fill galleries deterministically.

const _roomMockPool = <String>[
  'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',
  'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&q=80',
  'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80',
  'https://images.unsplash.com/photo-1596436889106-be35e843f974?w=800&q=80',
  'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
  'https://images.unsplash.com/photo-1540518614846-7eded433c457?w=800&q=80',
  'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
  'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
];

// ─── Category → index map for room type fallback ──────────────────────────────

const _categoryIndex = <String, int>{
  'suite':    0,
  'standard': 1,
  'deluxe':   2,
  'family':   3,
  'master':   4,
};

// ─── Per-session HEAD cache ───────────────────────────────────────────────────

final _headCache = <String, bool>{};

// ─── Pure helper functions ────────────────────────────────────────────────────

/// Returns a deterministic hotel-exterior Unsplash URL, stable per hotelId.
String fallbackForHotel(String hotelId) {
  final index = hotelId.hashCode.abs() % _hotelMocks.length;
  return _hotelMocks[index];
}

/// Returns a single room Unsplash URL matching the category with hotel-based variation.
String fallbackForRoom(String? categoria, {String hotelId = ''}) {
  // Pick a base offset per hotel so rooms look different across hotels
  final hotelOffset = hotelId.isEmpty ? 0 : (hotelId.hashCode.abs() ~/ 3) % _roomMockPool.length;

  if (categoria != null) {
    final lower = categoria.toLowerCase();
    for (final entry in _categoryIndex.entries) {
      if (lower.contains(entry.key)) {
        return _roomMockPool[(entry.value + hotelOffset) % _roomMockPool.length];
      }
    }
  }
  // Default: rotate by hotelId so each hotel has a different "default" room image
  return _roomMockPool[hotelOffset];
}

/// Returns `count` distinct room Unsplash URLs, deterministic per hotel + category.
List<String> fallbacksForRoom(String? categoria, String hotelId, int count) {
  final base = hotelId.hashCode.abs();
  final result = <String>[];
  // Always start with the category-matched image for this hotel
  result.add(fallbackForRoom(categoria, hotelId: hotelId));
  // Fill remaining slots with subsequent images from the pool
  for (var i = 1; result.length < count; i++) {
    final candidate = _roomMockPool[(base + i) % _roomMockPool.length];
    if (!result.contains(candidate)) result.add(candidate);
    if (i >= _roomMockPool.length) break;
  }
  // Pad if pool exhausted (shouldn't happen with 8 images and count ≤ 4)
  while (result.length < count) {
    result.add(_roomMockPool[(base + result.length) % _roomMockPool.length]);
  }
  return result;
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class SmartNetworkImage extends ConsumerStatefulWidget {
  final String? url;
  final String fallback;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const SmartNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit,
  });

  @override
  ConsumerState<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends ConsumerState<SmartNetworkImage> {
  // null = HEAD still in-flight; non-null = resolved (real URL or fallback)
  String? _resolvedUrl;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _resolve(widget.url);
  }

  @override
  void didUpdateWidget(SmartNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _cancelToken?.cancel();
      _cancelToken = null;
      setState(() => _resolvedUrl = null);
      _resolve(widget.url);
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _resolve(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _resolvedUrl = widget.fallback);
      return;
    }

    if (_headCache.containsKey(url)) {
      if (mounted) setState(() => _resolvedUrl = _headCache[url]! ? url : widget.fallback);
      return;
    }

    final token = CancelToken();
    _cancelToken = token;

    try {
      final dio = ref.read(dioProvider);
      await dio.head<void>(url, cancelToken: token);
      _headCache[url] = true;
      if (!token.isCancelled && mounted) setState(() => _resolvedUrl = url);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _headCache[url] = false;
      if (mounted) setState(() => _resolvedUrl = widget.fallback);
    } catch (_) {
      _headCache[url] = false;
      if (mounted) setState(() => _resolvedUrl = widget.fallback);
    }
  }

  // Safe height for use in Container during loading: avoids double.infinity
  // which causes an assertion inside IntrinsicHeight layouts (e.g. FavoriteCard).
  double? get _safeHeight {
    final h = widget.height;
    if (h == null || h.isInfinite) return null;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedUrl;

    if (resolved == null) {
      return Container(
        width: widget.width,
        height: _safeHeight,
        color: AppColors.primary.withValues(alpha: 0.08),
      );
    }

    return Image.network(
      resolved,
      width: widget.width,
      height: _safeHeight,
      fit: widget.fit ?? BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'lib/assets/mock_room.jpg',
        width: widget.width,
        height: _safeHeight,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: widget.width,
          height: _safeHeight,
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
