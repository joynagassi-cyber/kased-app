# 🚀 Quick Start — Mode Caveman

**Durée** : 5 minutes  
**Économie tokens** : 65-75%

---

## 📋 Qu'est-ce que Caveman ?

Mode de compression pour réponses agent. Supprime remplissage, garde précision technique. Code et erreurs intacts.

**Basé sur** : [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (MIT)

---

## 🎯 Niveaux

| Niveau     | Description                       | Usage                  |
| ---------- | --------------------------------- | ---------------------- |
| **lite**   | Professionnel, phrases complètes  | Documentation formelle |
| **full**   | Fragments, sans articles (défaut) | Chat, walkthroughs     |
| **ultra**  | Télégraphique, abréviations       | Tâches, commits        |
| **wenyan** | Chinois classique                 | Experts uniquement     |

---

## 🚀 Activation

```
/caveman lite    # Professionnel
/caveman full    # Par défaut
/caveman ultra   # Télégraphique
/caveman wenyan  # Chinois classique
```

**Désactivation :**
```
stop caveman
normal mode
```

---

## 📊 Exemples

### Avant (normal)
```
I'd be happy to help you with that! The issue you're experiencing is 
actually quite common. Basically, what's happening is that the 
authentication middleware is using the wrong comparison operator. 
I recommend that you change the `<` to `<=` in the token expiry check. 
This should resolve the problem.
```

### Après (lite)
```
Authentication middleware uses wrong comparison operator. 
Change `<` to `<=` in token expiry check.
```

### Après (full)
```
Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:
```

### Après (ultra)
```
auth mw bug. token expiry: `<` → `<=`. fix.
```

---

## 🔒 Invariants (jamais compressés)

- ✅ Code blocks
- ✅ Erreurs (citées exactement)
- ✅ Termes techniques
- ✅ Stack traces
- ✅ URLs, chemins
- ✅ Versions
- ✅ Regex
- ✅ SQL
- ✅ JSON/YAML

---

## 📋 Règles par Type

| Type        | Max               | Format                               |
| ----------- | ----------------- | ------------------------------------ |
| Chat        | 6 lignes          | [constat] [cause] [action]           |
| Docs        | 15 lignes/section | Sections standard                    |
| Walkthrough | 8 steps           | Step N: [action]. [result].          |
| Task        | -                 | TASK {id}: {goal} \| File \| Status  |
| Plan        | 25 lignes         | Goal/Files/Deps/Tests                |
| Commit      | 72 chars          | {type}({scope}): {action} - {reason} |

---

## 🗺️ IDE Supportés (24)

Claude Code, Codex, Gemini, Cursor, Windsurf, Cline, Copilot, Aider, Kiro, Zed, Antigravity, Trae, Warp, Codeium, Continue, Cody, Roo Code, Devin, Mistral Vibe, Qwen Code, OpenCode, JetBrains Junie, Replit Agent, Amazon Q Developer.

**Détection automatique :**
```bash
bash Axiom-scaffold/scripts/detect-ide.sh
```

---

## 📖 Documentation

- **Config** : `Axiom-scaffold/config/caveman-rules.yaml`
- **IDE mapping** : `Axiom-scaffold/config/ide-mapping.yaml`
- **Skill** : `Axiom-scaffold/skills/built-in/caveman-mode.md`
- **Constitution** : `Axiom-scaffold/specs/rules/constitution.md`
- **Rapport** : `Axiom-scaffold/reports/CAVEMAN_IMPLEMENTATION_COMPLETE.md`

---

## 📈 Métriques

- **Économie tokens (sorties)** : 65-75%
- **Économie tokens (entrées)** : ~46% (avec caveman-compress)
- **Perte précision** : 0%
- **Précision technique** : 100%

---

**Version** : 1.0.0  
**Source** : https://github.com/JuliusBrussee/caveman  
**Licence** : MIT
