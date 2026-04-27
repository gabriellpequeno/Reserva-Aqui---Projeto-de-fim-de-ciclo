class HotelRatingSummary {
  final double? average;
  final int count;

  HotelRatingSummary({
    required this.average,
    required this.count,
  });

  factory HotelRatingSummary.empty() {
    return HotelRatingSummary(average: null, count: 0);
  }
}
