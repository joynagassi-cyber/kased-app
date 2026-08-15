import 'package:flutter/material.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/widgets/kased_gradient_card.dart';

/// Dialogue pour payer plusieurs cultes en avance d'un coup.
///
/// Permet de sélectionner plusieurs cultes futurs et de payer pour tous
/// avec un seul montant total. Le système calcule automatiquement
/// combien de cultes sont couverts.
class BatchPaymentDialog extends StatefulWidget {
  final List<Culte> futureCultes;
  final double montantParCulte;
  final Function(List<Culte> selectedCultes, double totalAmount) onPay;

  const BatchPaymentDialog({
    super.key,
    required this.futureCultes,
    required this.montantParCulte,
    required this.onPay,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Culte> futureCultes,
    required double montantParCulte,
    required Function(List<Culte> selectedCultes, double totalAmount) onPay,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BatchPaymentDialog(
        futureCultes: futureCultes,
        montantParCulte: montantParCulte,
        onPay: onPay,
      ),
    );
  }

  @override
  State<BatchPaymentDialog> createState() => _BatchPaymentDialogState();
}

class _BatchPaymentDialogState extends State<BatchPaymentDialog> {
  final Set<String> _selectedCulteIds = {};
  final TextEditingController _montantController = TextEditingController();
  bool _isLoading = false;

  double get _montantParCulte => widget.montantParCulte;
  int get _selectedCount => _selectedCulteIds.length;
  double get _totalMontant => _selectedCount * _montantParCulte;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le montant par défaut
    _montantController.text = _montantParCulte.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  void _toggleCulte(String culteId) {
    setState(() {
      if (_selectedCulteIds.contains(culteId)) {
        _selectedCulteIds.remove(culteId);
      } else {
        _selectedCulteIds.add(culteId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedCulteIds.length == widget.futureCultes.length) {
        _selectedCulteIds.clear();
      } else {
        _selectedCulteIds.addAll(
            widget.futureCultes.map((c) => c.id).toSet());
      }
    });
  }

  void _pay() async {
    if (_selectedCulteIds.isEmpty) return;

    setState(() => _isLoading = true);

    final selectedCultes = widget.futureCultes
        .where((c) => _selectedCulteIds.contains(c.id))
        .toList();

    // Utiliser le montant saisí ou le montant par culte
    final montantSaisi =
        double.tryParse(_montantController.text.trim()) ?? _montantParCulte;
    final totalAmount = montantSaisi * selectedCultes.length;

    await widget.onPay(selectedCultes, totalAmount);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiement en avance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sélectionnez les cultes à payer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_selectedCount sélectionné${_selectedCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Liste des cultes
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: widget.futureCultes.length,
                itemBuilder: (context, index) {
                  final culte = widget.futureCultes[index];
                  final isSelected =
                      _selectedCulteIds.contains(culte.id);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1A237E)
                              : const Color(0xFFE3F2FD))
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2962FF)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.border),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2962FF)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.background),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2962FF)
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.calendar_today,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary),
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        culte.titre ??
                            'Culte du ${culte.dateCulte.day}/${culte.dateCulte.month}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF2962FF)
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        ),
                      ),
                      subtitle: Text(
                        culte.dateFormatee,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                        ),
                      ),
                      trailing: Text(
                        '${culte.montantCotisation.toStringAsFixed(0)} F',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF2962FF)
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        ),
                      ),
                      onTap: () => _toggleCulte(culte.id),
                      selected: isSelected,
                    ),
                  );
                },
              ),
            ),

            // Sélecteur rapide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Sélection rapide :',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 5, 10]
                          .map((n) => ActionChip(
                                label: Text('$n culte${n > 1 ? 's' : ''}'),
                                onPressed: () {
                                  final firstNCultes =
                                      widget.futureCultes.take(n).toList();
                                  setState(() {
                                    _selectedCulteIds.clear();
                                    _selectedCulteIds.addAll(
                                        firstNCultes.map((c) => c.id));
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    child: Text(
                      _selectedCount == widget.futureCultes.length
                          ? 'Désélectionner tout'
                          : 'Tout sélectionner',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Montant total
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _selectedCount > 0
                    ? const LinearGradient(
                        colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
                      )
                    : null,
                color: _selectedCount > 0
                    ? null
                    : (isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedCount > 0
                      ? Colors.transparent
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total à payer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _selectedCount > 0
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_totalMontant.toStringAsFixed(0)} F',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: _selectedCount > 0
                          ? Colors.white
                          : const Color(0xFF2962FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedCount > 0 && !_isLoading
                          ? _pay
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Payer en avance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
