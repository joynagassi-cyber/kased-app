/// Widget de dialogue pour les mises à jour de l'application.
///
/// Affiche les informations de la nouvelle version, le changelog,
/// et permet de télécharger/installer la mise à jour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/core/updates/app_update_model.dart';
import 'package:kased_app/providers/update_provider.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final AppUpdate update;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.update,
    this.forceUpdate = false,
  });

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  double _progress = 0.0;
  bool _downloading = false;
  bool _installed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.system_update_outlined,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouvelle version disponible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.update.versionName.isNotEmpty)
                  Text(
                    'v${widget.update.versionName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.update.changelog.isNotEmpty) ...[
              Text(
                'Ce que contient cette version',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface2Dark : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.update.changelog,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_downloading) ...[
              LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _progress < 1.0
                    ? 'Téléchargement en cours... ${(_progress * 100).toStringAsFixed(0)}%'
                    : 'Installation en cours...',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_installed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mise à jour installée !',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading && !_installed)
          TextButton(
            onPressed: widget.forceUpdate ? null : () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _downloading
              ? null
              : () async {
                  setState(() => _downloading = true);
                  final success = await ref
                      .read(updateNotifierProvider.notifier)
                      .downloadAndInstall(widget.update);
                  if (mounted) {
                    setState(() {
                      _downloading = false;
                      _installed = success;
                    });
                    if (success) {
                      Navigator.pop(context);
                    }
                  }
                },
          child: _downloading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(widget.forceUpdate ? 'Mettre à jour' : 'Mettre à jour maintenant'),
        ),
      ],
    );
  }
}
