import 'package:flutter/material.dart';

import '../models/shoe.dart';

const shoeCatalog = <Shoe>[
  Shoe(
    id: 'classic-shell-toe-black',
    name: 'Classic Shell-Toe Low-Top',
    brand: 'Adidas',
    price: 1250,
    image: 'assets/shoes/black.png',
    color: Color(0xFF27292C),
    tag: 'BESTSELLER',
    galleryImages: [
      'assets/shoes/black_side.png',
      'assets/shoes/black_front.png',
      'assets/shoes/black_rear.png',
    ],
    description:
        'A classic black low-top sneaker with a textured shell-toe design and clean all-black finish.',
    details: [
      'Black lace-up upper',
      'Textured shell-toe cap',
      'Three-stripe side panels',
      'Flat black rubber cupsole',
    ],
  ),
  Shoe(
    id: 'gray-suede-low-top',
    name: 'Gray Suede-Style Low-Top',
    brand: 'Adidas',
    price: 1650,
    image: 'assets/shoes/gray.png',
    color: Color(0xFFBBB7AF),
    tag: 'NEW',
    galleryImages: [
      'assets/shoes/gray_side.png',
      'assets/shoes/gray_front.png',
      'assets/shoes/gray_rear.png',
    ],
    description:
        'A gray low-top sneaker with white accents and a gum-colored outsole.',
    details: [
      'Gray suede-style upper',
      'White lace-up closure',
      'Three-stripe side panels',
      'Cream midsole with gum outsole',
    ],
  ),
  Shoe(
    id: 'blue-suede-low-top',
    name: 'Blue Suede-Style Low-Top',
    brand: 'Adidas',
    price: 1200,
    image: 'assets/shoes/blue.png',
    color: Color(0xFF1746BD),
    tag: 'TRENDING',
    galleryImages: [
      'assets/shoes/blue_side.png',
      'assets/shoes/blue_front.png',
      'assets/shoes/blue_rear.png',
    ],
    description:
        'A royal-blue low-top sneaker with white side stripes and a gum outsole.',
    details: [
      'Royal-blue suede-style upper',
      'Blue lace-up closure',
      'White three-stripe side panels',
      'White midsole with gum outsole',
    ],
  ),
  Shoe(
    id: 'lavender-mesh',
    name: 'Lavender Lightweight Mesh',
    brand: 'Adidas',
    price: 1450,
    image: 'assets/shoes/lavender.png',
    color: Color(0xFFAAA1B4),
    tag: 'LIGHTWEIGHT',
    galleryImages: [
      'assets/shoes/lavender_side.png',
      'assets/shoes/lavender_front.png',
      'assets/shoes/lavender_rear.png',
    ],
    description:
        'A pale lavender low-top sneaker with a mesh-style upper and a thick light-colored sole.',
    details: [
      'Pale lavender mesh-style upper',
      'Matching lace-up closure',
      'Subtle side stripes',
      'Thick lightweight-looking sole',
    ],
  ),
  Shoe(
    id: 'handball-spezial',
    name: 'Adidas Handball Spezial Sneakers',
    brand: 'Adidas',
    price: 1850,
    image: 'assets/shoes/handball_spezial_pair.png',
    color: Color(0xFF172A48),
    tag: 'RETRO CLASSIC',
    galleryImages: [
      'assets/shoes/handball_spezial_pair.png',
      'assets/shoes/handball_spezial.webp',
      'assets/shoes/handball_spezial_side.jpg',
      'assets/shoes/handball_spezial_rear.jpg',
      'assets/shoes/handball_spezial_profile.jpg',
    ],
    description:
        'The Adidas Handball Spezial features a navy blue suede upper with light blue three-stripe detailing, matching heel accents, and a gum-brown rubber sole. Its classic retro design combines comfort and style, making it suitable for everyday wear and casual outfits.',
    details: [
      'Navy blue suede upper',
      'Light blue three-stripe detailing and heel accents',
      'Gum-brown rubber sole',
      'Retro, casual, and vintage style',
      'Comfortable for everyday wear',
    ],
  ),
];
