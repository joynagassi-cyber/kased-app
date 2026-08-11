import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Affiche le dialogue / SnackBar adapté à une erreur d'authentification
/// Google (codes produits par [AuthService]).
///
/// Retourne `true` si l'erreur a été gérée avec un message dédié,
/// `false` sinon (l'appelant affiche alors le message brut).
bool showGoogleAuthError(BuildContext context, String errMsg) {
  if (errMsg.contains('ACCOUNT_EXISTS_WITH_PASSWORD')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Compte déjà existant'),
        content: const Text(
          'Un compte utilisant cette adresse email a été créé avec un mot de passe. '
          'Veuillez vous connecter avec votre adresse email et votre mot de passe.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
    return true;
  }

  if (errMsg.contains('GOOGLE_TIMEOUT')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion Google lente'),
        content: const Text(
          'La connexion Google a pris trop de temps. Cela peut arriver la première fois. '
          'Vérifiez votre connexion internet et réessayez.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
    return true;
  }

  if (errMsg.contains('BRIDGE_TIMEOUT')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serveur lent'),
        content: const Text(
          'Le serveur d\'authentification met trop de temps à répondre. '
          'Vérifiez votre connexion et réessayez dans quelques secondes.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return true;
  }

  if (errMsg.contains('GOOGLE_CONFIG_ERROR')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configuration Google requise'),
        content: const Text(
          'La connexion Google est bloquée par la configuration du projet (erreur '
          'DEVELOPER_ERROR / ApiException 10).\n\n'
          'À vérifier dans Google Cloud / Firebase pour « com.kasedapp » :\n'
          '• L\'empreinte SHA-1 de l\'APK installé (debug et release) est enregistrée.\n'
          '• Le Web Client ID passé à la compilation (GOOGLE_SERVER_CLIENT_ID) existe '
          'dans le même projet Google.\n\n'
          'Contactez le développeur de l\'application pour corriger cette configuration.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
    return true;
  }

  if (errMsg.contains('GOOGLE_BRIDGE_MISSING')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serveur Google indisponible'),
        content: const Text(
          'Le service de validation Google côté serveur n\'est plus disponible '
          '(la fonction « google-auth-bridge » n\'existe plus).\n\n'
          'L\'administrateur doit redéployer cette fonction sur InsForge pour '
          'rétablir la connexion Google. La connexion par email reste utilisable.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return true;
  }

  if (errMsg.contains('GOOGLE_NETWORK_ERROR')) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Problème réseau'),
        content: const Text(
          'La connexion Google n\'a pas pu être établie. Vérifiez votre '
          'connexion internet puis réessayez.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
    return true;
  }

  return false;
}
