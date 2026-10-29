import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.selectedIndex,
    required this.cartCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          NavItem(
            icon: Icons.directions_run,
            label: 'Sneakers',
            active: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          NavItem(
            icon: Icons.favorite_border,
            label: 'Favorites',
            active: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: NavItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              active: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? ink : muted),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
