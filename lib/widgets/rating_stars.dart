import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16, this.showValue = true});

  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.amber, size: size),
        const SizedBox(width: 2),
        if (showValue)
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * 0.8),
          ),
      ],
    );
  }
}

class RatingInput extends StatelessWidget {
  const RatingInput({super.key, required this.value, required this.onChanged, this.size = 32});

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < value;
        return IconButton(
          onPressed: () => onChanged(index + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: AppColors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}
