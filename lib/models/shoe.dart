import 'package:flutter/material.dart';

class Shoe {
  const Shoe({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.image,
    required this.color,
    this.tag = 'Popular',
    this.galleryImages = const [],
    this.description = '',
    this.details = const [],
  });

  final String id;
  final String name;
  final String brand;
  final int price;
  final String image;
  final Color color;
  final String tag;
  final List<String> galleryImages;
  final String description;
  final List<String> details;
}
