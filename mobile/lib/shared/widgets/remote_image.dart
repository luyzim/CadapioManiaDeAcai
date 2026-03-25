import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.local_drink_rounded,
    this.placeholderLabel,
    this.backgroundColor = const Color(0x14FFFFFF),
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final IconData placeholderIcon;
  final String? placeholderLabel;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String? resolvedImageUrl = _resolveImageUrl(imageUrl);
    final Widget child = resolvedImageUrl == null
        ? _Placeholder(
            icon: placeholderIcon,
            label: placeholderLabel,
            backgroundColor: backgroundColor,
          )
        : Image.network(
            resolvedImageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, Object error, StackTrace? stackTrace) => _Placeholder(
              icon: placeholderIcon,
              label: placeholderLabel,
              backgroundColor: backgroundColor,
            ),
          );

    if (borderRadius == null) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }

  String? _resolveImageUrl(String? value) {
    final String normalizedValue = value?.trim() ?? '';
    if (normalizedValue.isEmpty) {
      return null;
    }

    return ApiConfig.resolveUrl(normalizedValue);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.backgroundColor,
    this.label,
  });

  final IconData icon;
  final String? label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            color: Colors.white38,
            size: 26,
          ),
          if (label != null && label!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
