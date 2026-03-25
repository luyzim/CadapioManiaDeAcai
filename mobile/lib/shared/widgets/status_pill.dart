import 'package:flutter/material.dart';

import '../../core/utils/display_utils.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final String label = DisplayUtils.formatOrderStatus(status);
    final ({Color background, Color foreground}) colors =
        _resolveColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  ({Color background, Color foreground}) _resolveColors(String rawStatus) {
    switch (rawStatus) {
      case 'Recebido':
        return (
          background: const Color(0x2622C55E),
          foreground: const Color(0xFF86EFAC),
        );
      case 'Em_preparo':
      case 'Em preparo':
        return (
          background: const Color(0x26F59E0B),
          foreground: const Color(0xFFFCD34D),
        );
      case 'Pronto':
        return (
          background: const Color(0x262563EB),
          foreground: const Color(0xFF93C5FD),
        );
      case 'Entregue':
        return (
          background: const Color(0x26A855F7),
          foreground: const Color(0xFFE9D5FF),
        );
      default:
        return (
          background: const Color(0x14FFFFFF),
          foreground: Colors.white70,
        );
    }
  }
}
