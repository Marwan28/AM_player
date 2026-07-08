import 'package:flutter/material.dart';

class IconText extends StatelessWidget {
  final IconData iconData;
  final String string;
  final Color iconColor;
  final Color textColor;
  final double iconSize;

  const IconText(
      {super.key,
      required this.iconData,
      required this.string,
      required this.iconColor,
      required this.textColor,
      required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          iconData,
          size: iconSize,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          string,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
