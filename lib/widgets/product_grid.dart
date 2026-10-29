import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/shoe.dart';
import '../utils/price_format.dart';
import 'shoe_image.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.shoes,
    required this.favorites,
    required this.onOpen,
    required this.onFavorite,
    required this.onAddToCart,
  });

  final List<Shoe> shoes;
  final Set<Shoe> favorites;
  final ValueChanged<Shoe> onOpen;
  final ValueChanged<Shoe> onFavorite;
  final ValueChanged<Shoe> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shoes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final shoe = shoes[index];

        return ProductCard(
          shoe: shoe,
          favorite: favorites.contains(shoe),
          onTap: () => onOpen(shoe),
          onFavorite: () => onFavorite(shoe),
          onAdd: () => onAddToCart(shoe),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.shoe,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAdd,
  });

  final Shoe shoe;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDCDDDF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ShoeImage(shoe.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₱ ${formatPrice(shoe.price)}.00',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    tooltip: 'Add to cart',
                    icon: const Icon(Icons.shopping_cart_outlined, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 34,
                    ),
                  ),
                  IconButton(
                    onPressed: onFavorite,
                    tooltip: favorite
                        ? 'Alisin sa favorites'
                        : 'Idagdag sa favorites',
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      size: 22,
                    ),
                    color: favorite ? Colors.red : ink,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 34,
                    ),
                  ),
                  IconButton(
                    onPressed: onTap,
                    tooltip: 'See details',
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 34,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
