import 'dart:ui';

import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.headerSubtitle,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.form,
    required this.footer,
  });

  final String headerSubtitle;
  final String cardTitle;
  final String cardSubtitle;
  final Widget form;
  final Widget footer;

  static const Color _background = Color(0xFF0B0316);
  static const Color _cardBackground = Color(0x14FFFFFF);
  static const Color _cardBorder = Color(0x1AFFFFFF);
  static const LinearGradient _brandGradient = LinearGradient(
    colors: <Color>[Color(0xFF9333EA), Color(0xFFD946EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: <Widget>[
          const _BackdropBlob(
            alignment: Alignment(-1.1, -1.0),
            color: Color(0x4D7E22CE),
            size: 260,
            blur: 120,
          ),
          const _BackdropBlob(
            alignment: Alignment(1.1, -0.55),
            color: Color(0x40D946EF),
            size: 360,
            blur: 140,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 8),
                      Column(
                        children: <Widget>[
                          Container(
                            height: 52,
                            width: 52,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(18)),
                              gradient: _brandGradient,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x663B0764),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Ac',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ManiaDeAcai',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headerSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                            decoration: BoxDecoration(
                              color: _cardBackground,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  cardTitle,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  cardSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white60,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                form,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      footer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
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
