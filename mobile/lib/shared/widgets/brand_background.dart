import 'package:flutter/material.dart';

class BrandBackground extends StatelessWidget {
  const BrandBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const _BackdropBlob(
          alignment: Alignment(-1.15, -1.0),
          color: Color(0x4D7E22CE),
          size: 260,
          blur: 120,
        ),
        const _BackdropBlob(
          alignment: Alignment(1.1, -0.2),
          color: Color(0x40D946EF),
          size: 340,
          blur: 140,
        ),
        const _BackdropBlob(
          alignment: Alignment(0.1, 1.1),
          color: Color(0x332563EB),
          size: 280,
          blur: 130,
        ),
        child,
      ],
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({
    required this.alignment,
    required this.color,
    required this.size,
    required this.blur,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color,
                blurRadius: blur,
                spreadRadius: blur / 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
