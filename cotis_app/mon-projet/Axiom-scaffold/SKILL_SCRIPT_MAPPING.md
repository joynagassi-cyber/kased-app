# 🔗 Mapping Skills → Scripts

Ce document liste tous les skills Axiom et les scripts qu'ils déclenchent.

---

## 📋 Skills Built-in

| Skill | Trigger | Script | Statut |
|:------|:--------|:-------|:-------|
| **bootstrap** | `/axiom-bootstrap` | `scripts/bootstrap.sh` | ✅ |
| **caveman-mode** | `/axiom-caveman` | Lit `config/caveman-rules.yaml` | ✅ |
| **flex-mode** | `/axiom-flex` | Mode flexible (pas de script) | ✅ |
| **focus-mode** | `/axiom-focus` | `scripts/focus-mode.sh` | ✅ |
| **linear-sync** | `/axiom-linear` | `scripts/linear-sync.sh` | ✅ |
| **memory-update** | `/axiom-memory` | `scripts/index-memory.sh` | ✅ |
| **plan-template** | `/axiom-plan` | Template (pas de script) | ✅ |
| **quick-scan** | `/axiom-scan` | `scripts/quick-scan.sh` | ✅ |
| **stack-research** | `/axiom-research` | `scripts/stack-research.sh` | ✅ |
| **task-template** | `/axiom-task` | Template (pas de script) | ✅ |
| **visualization-update** | `/axiom-visualize` | `scripts/build-visualizer.sh` | ✅ |
| **walkthrough-template** | `/axiom-walkthrough` | Template (pas de script) | ✅ |

---

## 🔧 Scripts Utilitaires

| Script | Description | Appelé par |
|:-------|:------------|:-----------|
| `after-agent.sh` | Hook post-développement | Automatique |
| `check-all.sh` | Vérification scripts | Manuel |
| `detect-ide.sh` | Détection IDE/CLI | `bootstrap.sh` |
| `inject-context.sh` | Injection contexte | `bootstrap.sh` |
| `test-workflow.sh` | Test workflow complet | Manuel |
| `validate-code.sh` | Validation code | `after-agent.sh` |
| `validate-specs.sh` | Validation specs | Manuel |
| `security-scan.sh` | Scan sécurité | Manuel |

---

## 📝 Vérification des Chemins

### bootstrap.md
```yaml
trigger: /axiom-bootstrap
script: Axiom-scaffold/scripts/bootstrap.sh
```

### memory-update.md
```yaml
trigger: /axiom-memory
script: Axiom-scaffold/scripts/index-memory.sh
```

### visualization-update.md
```yaml
trigger: /axiom-visualize
script: Axiom-scaffold/scripts/build-visualizer.sh
```

### linear-sync.md
```yaml
trigger: /axiom-linear
script: Axiom-scaffold/scripts/linear-sync.sh
```

### stack-research.md
```yaml
trigger: /axiom-research
script: Axiom-scaffold/scripts/stack-research.sh
```

### focus-mode.md
```yaml
trigger: /axiom-focus
script: Axiom-scaffold/scripts/focus-mode.sh
```

### quick-scan.md
```yaml
trigger: /axiom-scan
script: Axiom-scaffold/scripts/quick-scan.sh
```

---

## ✅ Validation

Pour vérifier que tous les mappings sont corrects :

```bash
# Vérifier que tous les scripts existent
bash Axiom-scaffold/scripts/check-all.sh

# Tester le workflow complet
bash Axiom-scaffold/scripts/test-workflow.sh
```

---

## 🔄 Workflow Complet

```
1. User: /axiom-bootstrap
   ↓
2. Agent lit: skills/built-in/bootstrap.md
   ↓
3. Agent exécute: scripts/bootstrap.sh
   ↓
4. bootstrap.sh appelle:
   - detect-ide.sh
   - inject-context.sh
   - index-memory.sh (optionnel)
   ↓
5. Hook automatique: after-agent.sh
   ↓
6. after-agent.sh appelle:
   - index-memory.sh
   - build-visualizer.sh
   - learn.sh
   - validate-code.sh
```

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-09

