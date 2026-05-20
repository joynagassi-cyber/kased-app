import 'package:flutter/material.dart';
import '../../references/motion_tokens.dart'; // Supposé être généré ou mappé

/// Exemple complexe de transition d'écran complet avec orchestration
/// Utilise le staggering, les hero animations et les tokens du système.
class FullScreenTransitionExample extends StatelessWidget {
  const FullScreenTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Détails Cotisation'),
              background: Hero(
                tag: 'header-image',
                child: Image(
                  image: NetworkImage('https://picsum.photos/800/400'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 1 : Hero & Title
                  const AnimatedAppear(
                    delay: Duration.zero,
                    child: Text(
                      'Cotisation Mensuelle - Mai 2026',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const AnimatedAppear(
                    delay: MotionStagger.child,
                    child: Text(
                      'Statut : Payé',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Phase 2 : List of details with Staggering
                  const Text(
                    'Répartition',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  AnimatedStaggerList(
                    staggerDelay: MotionStagger.standard,
                    children: [
                      _buildDetailItem('Assurance Santé', '45,000 XAF'),
                      _buildDetailItem('Retraite Complémentaire', '12,500 XAF'),
                      _buildDetailItem('Fonds de Solidarité', '5,000 XAF'),
                      _buildDetailItem('Frais de Gestion', '2,500 XAF'),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Phase 3 : Action Button
                  AnimatedAppear(
                    delay: const Duration(milliseconds: 400), // Attendre la fin du stagger
                    child: AnimatedPress(
                      onTap: () => _showSuccessDialog(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Télécharger le reçu',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SuccessPulseDialog(),
    );
  }
}

/// Exemple de pattern Success-Pulse dans un Dialog
class SuccessPulseDialog extends StatelessWidget {
  const SuccessPulseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedAppear(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessPulseIcon(),
              const SizedBox(height: 16),
              const Text('Reçu téléchargé !', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessPulseIcon extends StatefulWidget {
  const SuccessPulseIcon({super.key});

  @override
  State<SuccessPulseIcon> createState() => _SuccessPulseIconState();
}

class _SuccessPulseIconState extends State<SuccessPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDuration.standard,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: MotionScale.success)
            .chain(CurveTween(curve: MotionCurve.emphasized)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: MotionScale.success, end: 1.0)
            .chain(CurveTween(curve: MotionCurve.emphasized)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(Icons.check_circle, color: Colors.green, size: 64),
    );
  }
}
