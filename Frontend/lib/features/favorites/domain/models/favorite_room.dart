import 'package:flutter/material.dart';

class FavoriteRoom {
  final String id;
  final String title;
  final String hotelName;
  final String destination;
  final String imageUrl;
  final String rating;
  final List<IconData> amenities;
  final double price;

  const FavoriteRoom({
    required this.id,
    required this.title,
    required this.hotelName,
    required this.destination,
    required this.imageUrl,
    required this.rating,
    required this.amenities,
    required this.price,
  });

  FavoriteRoom copyWith({
    String? id,
    String? title,
    String? hotelName,
    String? destination,
    String? imageUrl,
    String? rating,
    List<IconData>? amenities,
    double? price,
  }) {
    return FavoriteRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      hotelName: hotelName ?? this.hotelName,
      destination: destination ?? this.destination,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      amenities: amenities ?? this.amenities,
      price: price ?? this.price,
    );
  }
}
