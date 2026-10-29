import 'package:flutter/material.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/shoes/discover_shoes_banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
