/// REST envelope shared by all GitHub search endpoints:
/// `{ "total_count": int, "items": [ ... ] }`.
class SearchEnvelopeApiModel<T> {
  const SearchEnvelopeApiModel({required this.totalCount, required this.items});

  final int totalCount;
  final List<T> items;

  factory SearchEnvelopeApiModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    return SearchEnvelopeApiModel<T>(
      totalCount: json['total_count'] as int? ?? 0,
      items: ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(parseItem)
          .toList(),
    );
  }
}
