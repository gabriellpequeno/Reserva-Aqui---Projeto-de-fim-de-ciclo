class FotoExistente {
  final String id;
  final String url;

  const FotoExistente({required this.id, required this.url});

  factory FotoExistente.fromJson(Map<String, dynamic> json) {
    return FotoExistente(
      id: json['id']?.toString() ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
