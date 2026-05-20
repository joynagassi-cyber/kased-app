import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Pour context.go('/signup')
import '../providers/auth_provider.dart';
import '../core/theme/motion_tokens.dart';
import '../widgets/motion/motion_aware.dart';
import '../widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/spring_button.dart';
import '../widgets/custom_google_signin_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final result = await ref.read(authProvider.notifier).signInWithGoogle();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion annulée')),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();

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
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
        return;
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
        return;
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
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: ${errMsg.replaceAll('Exception: ', '')}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final isAnyLoading = auth.isEmailLoading || auth.isGoogleLoading;

    return MotionAware(
      builder: (context, reduceMotion) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: Stack(
            children: [
              // Background Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.4),
                        colorScheme.surface,
                        colorScheme.surface,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Subtle Decorative Shapes
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Logo
                              AnimatedAppear(
                                reduceMotion: reduceMotion,
                                child: Center(
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/kased_logo.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // 2. Title & Subtitle
                              AnimatedAppear(
                                delay: MotionStagger.standard,
                                reduceMotion: reduceMotion,
                                child: Column(
                                  children: [
                                    Text(
                                      'Bienvenue sur Kased',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Gérez vos cotisations d\'église en toute simplicité',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
            
                              // 3. Inputs
                              AnimatedAppear(
                                delay: MotionStagger.standard * 2,
                                reduceMotion: reduceMotion,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                                      ),
                                      validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                      decoration: const InputDecoration(
                                        labelText: 'Mot de passe',
                                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                                      ),
                                      validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
            
                              // 4. Login Button
                              AnimatedAppear(
                                delay: MotionStagger.standard * 3,
                                reduceMotion: reduceMotion,
                                child: SpringButton(
                                  onTap: isAnyLoading ? null : _loginWithEmail,
                                  child: SizedBox(
                                    height: 56,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: null, // Géré par SpringButton
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: auth.isEmailLoading 
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
                                          )
                                        : const Text(
                                            'Se connecter', 
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // 5. Divider & Google Button
                              AnimatedAppear(
                                delay: MotionStagger.standard * 4,
                                reduceMotion: reduceMotion,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.5), thickness: 1)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'OU', 
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.5), thickness: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    SpringButton(
                                      onTap: isAnyLoading ? () {} : _signInWithGoogle,
                                      child: CustomGoogleSignInButton(
                                        onPressed: () {}, // Géré par SpringButton
                                        isLoading: auth.isGoogleLoading,
                                        text: 'Continuer avec Google',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // 6. Link to Signup
                              AnimatedAppear(
                                delay: MotionStagger.standard * 5,
                                reduceMotion: reduceMotion,
                                child: Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'Pas encore de compte ? ',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/signup'),
                                        child: Text(
                                          'S\'inscrire gratuitement',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}