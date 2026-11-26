import 'package:flutter/material.dart';

class KakarotBrand extends StatelessWidget {
  const KakarotBrand({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * .18),
              child: Image.asset(
                'assets/images/kakarot_shiva_logo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kakarot Chat',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
          ),
        ],
      );
}
