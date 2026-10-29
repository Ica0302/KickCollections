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

  factory Shoe.fromMap(Map<String, dynamic> row) {
    final rawDetails = row['details'];
    final details = rawDetails is List
        ? rawDetails.map((value) => value.toString()).toList()
        : (rawDetails?.toString() ?? '')
            .split('\n')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    final rawGallery = row['gallery_images'];
    final galleryImages = rawGallery is List
        ? rawGallery.map((value) => value.toString()).toList()
        : <String>[];

    final colorValue = (row['color'] ?? '#FFFFFF').toString();
    final colorHex = colorValue.replaceFirst('#', '');
    final color = Color(
      int.tryParse('FF$colorHex', radix: 16) ?? 0xFFFFFFFF,
    );

    return Shoe(
      id: row['id'].toString(),
      name: (row['name'] ?? '').toString(),
      brand: (row['brand'] ?? '').toString(),
      price: (row['price'] as num?)?.round() ?? 0,
      image: (row['image'] ?? '').toString(),
      color: color,
      tag: (row['tag'] ?? 'Popular').toString(),
      galleryImages: galleryImages,
      description: (row['description'] ?? '').toString(),
      details: details,
    );
  }
}
