import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kased_app/providers/app_data_provider.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:kased_app/widgets/kased_avatar.dart';
import 'package:kased_app/widgets/spring_button.dart';

class AddMembreScreen extends ConsumerStatefulWidget {
  const AddMembreScreen({super.key});

  @override
  ConsumerState<AddMembreScreen> createState() => _AddMembreScreenState();
}

class _AddMembreScreenState extends ConsumerState<AddMembreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dateAdhesion = DateTime.now();
  DateTime? _dateNaissance;
  bool _isSaving = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un membre')),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isSaving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KasedAvatar(
                          name: _prenomController.text.isEmpty && _nomController.text.isEmpty ? '?' : '${_prenomController.text} ${_nomController.text}'.trim(),
                          size: 108,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pas de photo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      title: Text(
                        'Date d\'adhesion',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(_dateAdhesion),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateAdhesion,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _dateAdhesion = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      title: Text(
                        'Date de naissance (optionnel)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _dateNaissance == null
                            ? 'Aucune date sélectionnée'
                            : DateFormat('dd MMMM yyyy').format(_dateNaissance!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dateNaissance != null)
                            IconButton(
                              onPressed: () => setState(() => _dateNaissance = null),
                              icon: const Icon(Icons.close),
                            ),
                          const Icon(Icons.cake_outlined),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateNaissance ?? DateTime(1990, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _dateNaissance = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SpringButton(
                    onTap: _save,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            const ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }


  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isSaving = true);
        final notifier = ref.read(appDataProvider.notifier);
        await notifier.addMembre(
              nom: _nomController.text.trim(),
              prenom: _prenomController.text.trim(),
              dateAdhesion: _dateAdhesion,
              dateNaissance: _dateNaissance,
              telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}

