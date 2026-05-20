import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaisieRapideScreen extends ConsumerStatefulWidget {
  final String culteId;

  const SaisieRapideScreen({super.key, required this.culteId});

  @override
  ConsumerState<SaisieRapideScreen> createState() => _SaisieRapideScreenState();
}

class _SaisieRapideScreenState extends ConsumerState<SaisieRapideScreen> {
  final List<String> _queueIds = [];
  bool _initialized = false;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    final appDataAsync = ref.watch(appDataProvider);

    return appDataAsync.when(
      data: (state) {
        final culteIndex = state.cultes.indexWhere((c) => c.id == widget.culteId);
        if (culteIndex == -1) {
          return const Scaffold(body: Center(child: Text('Culte introuvable')));
        }
        final culte = state.cultes[culteIndex];

        _ensureQueue(state);
        _total = state.membres.length;
        final paidIds = state.cotisations.where((c) => c.culteId == widget.culteId && c.estPaye).map((c) => c.membreId).toSet();
        final remainingIds = _queueIds.where((id) => !paidIds.contains(id)).toList();
        final remainingMembers = remainingIds
            .map((id) => state.membres.firstWhere((m) => m.id == id))
            .toList();

        if (remainingMembers.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 96, color: AppColors.success),
                    const SizedBox(height: 16),
                    Text(
                      'Tout le monde a été traité',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.cotisations.where((c) => c.culteId == widget.culteId && c.estPaye).length} paiements enregistrés pour ce culte.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final currentMember = remainingMembers.first;
        final payesCount = state.cotisations.where((c) => c.culteId == widget.culteId && c.estPaye).length;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: _total == 0 ? 0 : payesCount / _total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$payesCount / $_total payés - ${culte.montantCotisation.toInt()} FCFA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.14, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return SlideTransition(position: slide, child: FadeTransition(opacity: animation, child: child));
                        },
                        child: Column(
                          key: ValueKey(currentMember.id),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMember.prenom,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentMember.nom.toUpperCase(),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0F0E1631), blurRadius: 24, offset: Offset(0, 10)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    currentMember.nomComplet,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tapez payé ou passez au suivant',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size.fromHeight(80),
                    ),
                    onPressed: () => _markPaid(context, culte.montantCotisation),
                    child: const Text('V Payé'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => _skipCurrent(),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  void _ensureQueue(AppState state) {
    if (_initialized) return;
    final sortedMembers = [...state.membres]..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    _queueIds
      ..clear()
      ..addAll(sortedMembers.map((m) => m.id));
    _initialized = true;
  }

  Future<void> _markPaid(BuildContext context, double montant) async {
    final currentId = _queueIds.isNotEmpty ? _queueIds.first : null;
    if (currentId == null) return;
    try {
      await ref.read(appDataProvider.notifier).togglePaiement(
            membreId: currentId,
            culteId: widget.culteId,
          );
      if (mounted) {
        setState(() {
          _queueIds.removeAt(0);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _skipCurrent() {
    if (_queueIds.isEmpty) return;
    setState(() {
      final first = _queueIds.removeAt(0);
      _queueIds.add(first);
    });
  }
}

