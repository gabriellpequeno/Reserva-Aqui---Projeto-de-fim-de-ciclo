import 'package:flutter/material.dart';

class Room {
  final String id;
  final String hotelId;
  final String title;
  final String hotelName;
  final String destination;
  final String description;
  final List<String> imageUrls;
  final String rating;
  final List<Amenity> amenities;
  final double price;
  final Host host;

  const Room({
    required this.id,
    required this.hotelId,
    required this.title,
    required this.hotelName,
    required this.destination,
    required this.description,
    required this.imageUrls,
    required this.rating,
    required this.amenities,
    required this.price,
    required this.host,
  });
}

class Amenity {
  final String label;
  final IconData icon;

  const Amenity(this.label, this.icon);
}

class Host {
  final String name;
  final String bio;
  final String imageUrl;
  final String rating;

  const Host({
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.rating,
  });
}
