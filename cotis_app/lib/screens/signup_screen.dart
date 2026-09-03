import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/motion_tokens.dart';
import '../widgets/motion/motion_aware.dart';
import '../widgets/motion/animated_appear.dart';
import 'package:kased_app/widgets/spring_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_google_signin_button.dart';
import '../widgets/google_auth_error.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emailFocus.requestFocus());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await ref.read(authProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenue ! Votre compte est prêt.')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        // Afficher des messages compréhensibles pour l'utilisateur
        String userMsg;
        if (msg.contains('No Internet') || msg.contains('Network')) {
          userMsg = 'Vérifiez votre connexion internet';
        } else if (msg.contains('timeout') || msg.contains('Timeout')) {
          userMsg = 'La connexion a pris trop de temps, réessayez';
        } else if (msg.contains('email') || msg.contains('address')) {
          userMsg = 'Adresse email déjà utilisée';
        } else {
          userMsg = 'Une erreur est survenue, veuillez réessayer';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMsg)),
        );
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      final result = await ref.read(authProvider.notifier).signInWithGoogle();
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bienvenue 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion annulée')),
        );
      }
    } on Exception catch (error) {
      if (!mounted) return;
      final errMsg = error.toString();
      if (!showGoogleAuthError(context, errMsg)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${errMsg.replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
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
              
              // Subtle Decorative Shape
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.04),
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
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(alpha: 0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
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
                                      'Créer un compte',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Rejoignez-nous pour gérer vos cotisations simplement',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
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
                                      controller: _nameController,
                                      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                      decoration: const InputDecoration(
                                        labelText: 'Nom complet',
                                        prefixIcon: Icon(Icons.person_outline, size: 20),
                                      ),
                                      validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
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
                                      obscureText: _obscurePassword,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        labelText: 'Mot de passe',
                                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        helperText: 'Minimum 6 caractères',
                                        helperStyle: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Requis';
                                        if (value.length < 6) return 'Minimum 6 caractères';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32), // 4. Register Button
                              AnimatedAppear(
                                delay: MotionStagger.standard * 3,
                                reduceMotion: reduceMotion,
                                child: SpringButton(
                                  onTap: isAnyLoading ? null : _register,
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
                                        : const Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.5))),
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
                                        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.5))),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    SpringButton(
                                      onTap: isAnyLoading ? () {} : _signUpWithGoogle,
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
            
                              // 6. Link to Login
                              AnimatedAppear(
                                delay: MotionStagger.standard * 5,
                                reduceMotion: reduceMotion,
                                child: Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'Déjà un compte ? ',
                                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                                      ),
                                      GestureDetector(
                                        onTap: () => context.go('/login'),
                                        child: Text(
                                          'Se connecter',
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
                              const SizedBox(height: 24),
                              AnimatedAppear(
                                delay: MotionStagger.standard * 6,
                                reduceMotion: reduceMotion,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Vos données sont chiffrées et stockées en sécurité',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurfaceVariant,
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

