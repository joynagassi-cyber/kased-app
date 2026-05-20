# EXPÉRIENCE SENSORIELLE — PROMPT AGENT #2 (FLUTTER)

> ⚠️ RÈGLE GLOBALE SUR LES NOMS DE FICHIERS :
> Tous les noms de fichiers mentionnés dans ce prompt sont INDICATIFS.
> Avant chaque micro-tâche, l'agent DOIT scanner le projet réel pour trouver
> le fichier correspondant. Commande : find lib/ -name "*.dart" | sort
> Ne jamais supposer qu'un fichier existe — le vérifier d'abord.

---

## ██ PHASE 0 — CARTOGRAPHIE OBLIGATOIRE

```
TÂCHES (aucune modification autorisée en Phase 0) :

  1. Lancer : find lib/ -name "*.dart" | sort
     → Copier la liste complète dans la réponse

  2. Identifier et noter le fichier réel de chaque élément :
     □ Le fichier qui contient la BottomNavigationBar ou NavigationBar
     □ Le fichier qui contient le router principal (GoRouter)
     □ Le fichier qui contient les ListTile de membres
     □ Le fichier qui contient les ListTile de la séance/cotisations
     □ Le fichier qui contient le dashboard (stats, compteurs)
     □ Le fichier qui contient les chips de paiement
     □ Tous les fichiers dont le nom contient "skeleton" ou "shimmer" ou "loading"
     □ Le fichier main.dart — lire son contenu complet

  3. Pour chaque fichier skeleton/shimmer trouvé :
     - Lire son contenu complet
     - Noter pourquoi il ne s'affiche pas (widget non appelé ?
       condition jamais vraie ? provider pas en état loading ?)

  4. Lire pubspec.yaml — noter les dépendances actuelles exactes

CONFIRMATION REQUISE :
  Écrire "PHASE 0 VALIDÉE" avec :
  - La liste des fichiers réels identifiés pour chaque élément ci-dessus
  - Le diagnostic du bug skeleton (cause exacte)
```

---

## ██ PHASE 1 — CORRECTION SKELETON (PRIORITÉ HAUTE)

> Le skeleton ne fonctionne pas actuellement. Cette phase corrige ça avant
> d'ajouter quoi que ce soit de nouveau.

### Micro-tâche 1.1 — Diagnostic et correction du skeleton

```
CONTEXTE DU BUG (causes fréquentes à vérifier) :
  A) Le widget skeleton existe mais n'est jamais appelé dans le build()
  B) Le provider retourne toujours data (jamais loading) car Isar/DB
     répond trop vite et le state loading est skippé
  C) La condition if (isLoading) pointe vers la mauvaise variable
  D) Le skeleton a une hauteur nulle ou un parent sans contraintes de taille
  E) Le skeleton est incomplete t ne couvre pas toute les pages 

TÂCHE :
  1. Lire le fichier skeleton réel (trouvé en Phase 0)
  2. Lire le fichier screen qui devrait l'afficher
  3. Trouver la cause exacte parmi A/B/C/D ci-dessus
  4. Corriger selon le cas :

  CAS A — skeleton non appelé :
    Trouver le widget AsyncValue.when() ou if(isLoading) dans le screen
    Remplacer le loading: () => SizedBox() ou CircularProgressIndicator()
    par loading: () => SkeletonXxxScreen() (nom réel du skeleton)

  CAS B — loading trop rapide (cas Isar/local DB) :
    Le skeleton doit apparaître même 100ms — ajouter un Future.delayed
    minimal UNIQUEMENT au premier lancement :
    Dans le provider, wrapper le premier fetch avec :
    await Future.delayed(const Duration(milliseconds: 120));
    Cela rend le skeleton visible au cold start sans ralentir l'UX.

  CAS C — mauvaise variable :
    Tracer le vrai chemin : provider → AsyncValue → state → widget
    Corriger le bon ref.watch() et la bonne propriété .isLoading

  CAS D — hauteur nulle :
    Le skeleton doit avoir exactement la même structure de taille
    que le widget réel qu'il remplace.
    Utiliser SizedBox(height: X) ou Expanded selon le contexte parent.
```

### Micro-tâche 1.2 — Aligner le skeleton sur le widget réel
```
RÈGLE FONDAMENTALE DU SKELETON :
  La forme du skeleton doit correspondre exactement à la forme du widget réel.
  Si le ListTile réel a : avatar 40px + 2 lignes de texte + chip à droite
  Le skeleton doit avoir : cercle 40px + 2 barres + rectangle à droite
  Même padding. Même hauteur de ligne. Même espacement.

  1. Lire le widget réel (ListTile membre ou cotisation)
  2. Reproduire sa structure avec des Container shimmer :
     - Barres de texte : Container(height: 14, width: X, color: shimmerColor)
     - Avatars/cercles : CircleAvatar avec shimmerColor
     - Chips : Container(height: 32, width: 72, borderRadius: 20)
  3. Utiliser le package shimmer déjà installé :
     Shimmer.fromColors(
       baseColor: Colors.grey[300]!,
       highlightColor: Colors.grey[100]!,
       child: <structure skeleton>,
     )
  4. Afficher 6 items skeleton (ListView non-scrollable avec itemCount: 6)
```

CONFIRMATION REQUISE avant Phase 2.

---

## ██ PHASE 2 — TRANSITIONS D'ÉCRANS (HERO + CUSTOM)

### Micro-tâche 2.1 — Ajouter les custom page transitions dans le router
```
FICHIER : trouver le fichier router réel (Phase 0)

Remplacer les GoRoute builder standards par des CustomTransitionPage
pour donner une transition slide + fade entre les écrans :

GoRoute(
  path: '/votre-path',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: VotreEcranReel(),
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
          child: child,
        ),
      );
    },
  ),
)

Appliquer ce pattern à TOUTES les routes existantes dans le fichier router réel.
Ne pas changer les paths, seulement les builders.
```

### Micro-tâche 2.2 — Hero animation sur les cards membres
```
FICHIER : trouver le fichier ListTile/card membre réel (Phase 0)

Principe : l'élément cliqué "voyage" visuellement vers l'écran de détail.

Dans la liste des membres, wrapper l'avatar ou le nom avec Hero :
  Hero(
    tag: 'membre_${membre.id}',
    child: CircleAvatar(child: Text(membre.prenom[0])),
  )

Dans l'écran de détail du membre (si il existe), wrapper le même élément :
  Hero(
    tag: 'membre_${membre.id}',   // même tag exact
    child: CircleAvatar(child: Text(membre.prenom[0]), radius: 28),
  )

⚠️ Si l'écran de détail membre n'existe pas, appliquer Hero uniquement
   sur la transition vers la séance (card culte → écran séance).
   Tag : 'culte_${culte.id}'
```
### Micro-tâche 3.0— Redesign complet de la page details membre
```
1.Dans l'écran de détail du membre (il existe), wrapper le même élément :
Je veux que à ce niveau que tu ajoute une entete sous frome de profil avec l'icone de profildes iniatile de elttre son nom sur photode proifl pour faireun peit cercle de fphoto de rofil
tU VAS STRCUURER TOUT DE MANI7RE CORECTE AVEC DES titre bien desinger et de cartes en gradient linear (C'est un gradient fait sur trois projectionde toris couleur aligner et bine styler)
2.0Ensuite je veux que que tu adpate bien cet ecran au dark mode et au light mode, (eviter des textes qui ne seront lisbles dans unmode et choisir des cuouleur a la fois aligner avec le design system et cohrenet en libilité)


CONFIRMATION REQUISE avant Phase 3.

---

## ██ PHASE 3 — SCROLL PHYSIQUE REBONDISSANT

### Micro-tâche 3.1 — Activer BouncingScrollPhysics globalement
```
FICHIER : trouver main.dart ou le fichier MaterialApp/theme réel

Dans le ThemeData ou MaterialApp, ajouter :
  ScrollConfiguration.behavior qui force BouncingScrollPhysics sur Android :

Wrapper le MaterialApp avec :
  ScrollConfiguration(
    behavior: const BouncingScrollBehavior(),
    child: MaterialApp(...),
  )

Créer la classe dans lib/core/ (nom de fichier à choisir par l'agent) :
  class BouncingScrollBehavior extends ScrollBehavior {
    const BouncingScrollBehavior();

    @override
    ScrollPhysics getScrollPhysics(BuildContext context) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
  }
```

### Micro-tâche 3.2 — Vérifier chaque ListView du projet
```
Pour chaque ListView ou ListView.builder trouvé dans le projet :
  - S'assurer que physics n'est pas hardcodé à ClampingScrollPhysics
  - Si oui, supprimer le paramètre physics (il héritera du global)
  - Si la liste est dans un Column ou une Expanded, vérifier
    qu'elle a bien shrinkWrap: false (pour que le bounce soit visible)
```

CONFIRMATION REQUISE avant Phase 4.

---

## ██ PHASE 4 — FEEDBACK VISUEL DES ÉTATS

### Micro-tâche 4.1 — Animation de succès sur le paiement validé
```
FICHIER : trouver le fichier chip/bouton paiement réel (Phase 0)

Quand isPaid passe à true, déclencher une micro-célébration :
  1. Le chip passe au vert avec scale élastique 
  2. Ajouter une icône check qui apparaît avec rotation :

  AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => ScaleTransition(
      scale: animation,
      child: RotationTransition(
        turns: Tween(begin: -0.1, end: 0.0).animate(animation),
        child: child,
      ),
    ),
    child: Icon(
      isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      key: ValueKey(isPaid),
      color: isPaid ? Colors.green : Colors.grey,
    ),
  )
```

### Micro-tâche 4.2 — Célébration quand tous les membres ont payé
```
FICHIER : trouver le fichier écran séance réel (Phase 0)

Condition : totalPaies == totalMembres && totalMembres > 0

Quand cette condition devient vraie pour la première fois dans la session :
  Afficher un SnackBar animé avec message positif :

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        const Text('Tout le monde a payé !'),
      ]),
      backgroundColor: const Color(0xFF1D9E75),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ),
  );

⚠️ Utiliser un flag bool _celebrationShown = false pour ne déclencher
   la célébration qu'une seule fois par session d'écran.
```

### Micro-tâche 4.3 — Compteur animé sur le dashboard
```
FICHIER : trouver le fichier dashboard/home réel (Phase 0)

Sur le widget qui affiche le total collecté (ex: "600 FCFA") :
  Remplacer le Text statique par un compteur animé.

  Ajouter flutter_animate (déjà installé) :
  Text('${montantCollecte.toStringAsFixed(0)} FCFA')
    .animate(key: ValueKey(montantCollecte))
    .slideY(begin: 0.4, duration: 350.ms, curve: Curves.easeOutCubic)
    .fadeIn(duration: 250.ms)

  Même pattern sur le compteur "X payés sur Y".
  Le chiffre remonte visuellement à chaque nouveau paiement.
```

CONFIRMATION REQUISE avant Phase 5.

---

## ██ PHASE 5 — COULEURS ANIMÉES DE LA NAVBAR

### Micro-tâche 5.1 — Transition de couleur sur l'indicateur actif
```
FICHIER : trouver le fichier BottomNavigationBar/NavigationBar réel (Phase 0)

Dans le NavigationBar, wrapper l'indicateur de couleur avec AnimatedContainer :
  Le NavigationBar de Flutter Material 3 anime déjà les indicateurs,
  mais la couleur de l'icône non sélectionnée ne transite pas.

  Sur chaque SpringNavIcon , ajouter AnimatedDefaultTextStyle
  ou TweenAnimationBuilder pour animer la couleur :

  TweenAnimationBuilder<Color?>(
    tween: ColorTween(
      begin: isSelected ? Colors.grey : const Color(0xFF5C35D9),
      end: isSelected ? const Color(0xFF5C35D9) : Colors.grey,
    ),
    duration: const Duration(milliseconds: 220),
    builder: (context, color, _) {
      return Icon(iconData, color: color, size: 26);
    },
  )
```

CONFIRMATION REQUISE avant Phase 6.

---

## ██ PHASE 6 — VÉRIFICATION FINALE

### Micro-tâche 6.1 — Checklist de test
```
  □ Skeleton visible au lancement (même 100ms) sur chaque écran liste
  □ Skeleton a la même forme que les vrais items
  □ Changer d'écran → transition slide+fade fluide, pas de saut brutal
  □ Tapper un membre → Hero animation visible sur l'avatar
  □ Scroller jusqu'en bas d'une liste → rebond visible
  □ Marquer un paiement → check animé + chip verte
  □ Tous payés → SnackBar vert de célébration (une seule fois)
  □ Dashboard → montant collecté remonte visuellement à chaque paiement
  □ Changer d'onglet → couleur icône transite doucement
  □ Aucun overflow, aucun RenderFlex error dans la console
```

### Micro-tâche 6.2 — Build final
```bash
flutter analyze          # zéro erreur critique
dart run build_runner build -d
flutter build apk --debug
```

---

## ██ RÈGLES GLOBALES (rappel)

```
1. Noms de fichiers = indicatifs. Toujours scanner find lib/ avant d'éditer.
2. Lire un fichier entier avant de le modifier.
3. Une micro-tâche à la fois. Confirmation écrite entre chaque phase.
4. Ne jamais supprimer de logique métier existante.
5. Si une animation cause un lag ou un jank → la supprimer sans hésiter.
   La fluidité prime sur les effets.
6. Ne pas ajouter de nouvelles dépendances sans demander confirmation.
   flutter_animate et shimmer sont déjà disponibles — les utiliser en priorité.
```

---

## ██ Instruction DE DÉMARRAGE

```
Applique les améliorations UX de ce prompt sur le projet Flutter.
Commence par PHASE 0 : scanne tous les fichiers dart du projet avec
find lib/ -name "*.dart" | sort et identifie les fichiers réels
correspondant à chaque élément listé avant d'écrire la moindre ligne.
Confirme la Phase 0 avec la liste complète avant de continuer.
```

---

*Prompt #2 — Expérience sensorielle · kased-app*
*Cibles : skeleton fix · transitions · scroll physique · feedback états · navbar couleurs*
