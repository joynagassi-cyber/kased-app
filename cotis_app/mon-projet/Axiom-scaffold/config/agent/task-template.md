# Micro-Tâche — {{TASK_ID}}

**Plan Parent** : {{PLAN_ID}}  
**Phase** : {{PHASE_NUMBER}}  
**Date** : {{DATE}}  
**Statut** : 🔵 Todo | 🟡 En cours | 🟢 Terminé | 🔴 Bloqué

---

## Contexte (≤ 100 tokens)

<!-- Contexte minimal nécessaire pour comprendre la tâche -->
Cette tâche fait partie de {{FEATURE_NAME}}. Elle consiste à {{DESCRIPTION_COURTE}}.

**Dépendances** : {{TASK_DEPENDENCIES}}

---

## Objectif

<!-- Un seul objectif clair et mesurable -->
{{OBJECTIF_PRINCIPAL}}

---

## Scope

### Fichiers à Modifier
- `{{FILE_1}}` : {{MODIFICATION_1}}
- `{{FILE_2}}` : {{MODIFICATION_2}}

### Fichiers à Créer
- `{{NEW_FILE_1}}` : {{DESCRIPTION_1}}

### Estimation
- **Lignes de code** : ≤ 100 lignes
- **Durée** : {{DURATION}} minutes
- **Complexité** : 🟢 Faible | 🟡 Moyenne | 🔴 Élevée

---

## Implémentation

### Étape 1 : {{STEP_1_NAME}}
```typescript
// Code ou pseudo-code
```

### Étape 2 : {{STEP_2_NAME}}
```typescript
// Code ou pseudo-code
```

### Étape 3 : {{STEP_3_NAME}}
```typescript
// Code ou pseudo-code
```

---

## Tests

### Tests Unitaires
```typescript
describe('{{COMPONENT_NAME}}', () => {
  it('should {{BEHAVIOR}}', () => {
    // Arrange
    
    // Act
    
    // Assert
  });
});
```

### Critères de Validation
- [ ] Tous les tests passent
- [ ] Couverture ≥ 80% pour les nouveaux fichiers
- [ ] Pas de régression sur les tests existants
- [ ] Linting passe sans erreur

---

## Vérification

### Checklist Pré-Commit
- [ ] Code écrit et testé
- [ ] Tests unitaires créés
- [ ] `npm test` passe
- [ ] `npm run lint` passe
- [ ] `npm audit` ne montre pas de vulnérabilités high/critical
- [ ] Documentation mise à jour (si nécessaire)

### Commandes de Vérification
```bash
# Tests
npm test

# Linting
npm run lint

# Audit
npm audit --audit-level=high
```

---

## Résultat Attendu

### Comportement
<!-- Décris le comportement attendu après implémentation -->
{{EXPECTED_BEHAVIOR}}

### Preuve
<!-- Comment prouver que la tâche est terminée -->
- [ ] Tests unitaires passent
- [ ] Capture d'écran/vidéo (si UI)
- [ ] Log de test

---

## Notes

### Décisions Prises
- {{DECISION_1}}
- {{DECISION_2}}

### Difficultés Rencontrées
- {{DIFFICULTY_1}} : {{SOLUTION_1}}
- {{DIFFICULTY_2}} : {{SOLUTION_2}}

### Patterns Découverts
- {{PATTERN_1}}
- {{PATTERN_2}}

---

## Commit

### Message de Commit
```
{{COMMIT_TYPE}}({{SCOPE}}): {{COMMIT_MESSAGE}}

{{COMMIT_BODY}}

Refs: {{TICKET_ID}}
```

### Exemple
```
feat(auth): add JWT token validation

- Implement token validation middleware
- Add unit tests for token validation
- Update API documentation

Refs: AX-123
```

---

**Statut Final** : {{FINAL_STATUS}}  
**Durée Réelle** : {{ACTUAL_DURATION}} minutes  
**Commit SHA** : {{COMMIT_SHA}}
