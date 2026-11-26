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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size * .72,
                  height: size * .72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFFFE9A3), Color(0xFFFFA52E), Color(0xFFCF3B12)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x99FF8C1A), blurRadius: 22, spreadRadius: 2),
                    ],
                  ),
                ),
                Icon(Icons.chat_bubble_rounded, size: size * .35, color: Color(0xFF17213F)),
                Positioned(left: 2, top: 15, child: _sparkle(size * .12)),
                Positioned(right: 5, top: 2, child: _sparkle(size * .10)),
                Positioned(right: 0, bottom: 12, child: _sparkle(size * .13)),
                Positioned(left: 10, bottom: 2, child: _sparkle(size * .09)),
              ],
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

  static Widget _sparkle(double size) =>
      Icon(Icons.auto_awesome_rounded, size: size, color: const Color(0xFFFFE6A3));
}
