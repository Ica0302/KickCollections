import 'package:flutter/material.dart';

/// Displays a packaged asset path or an http(s) image URL from Supabase.
class ShoeImage extends StatelessWidget {
  const ShoeImage(
    this.source, {
    super.key,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isNetworkImage =
        source.startsWith('https://') || source.startsWith('http://');
    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) =>
        const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.black38),
        );

    if (isNetworkImage) {
      return Image.network(
        source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }

    return Image.asset(
      source,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
