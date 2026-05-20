---
title: "Debugging"
domain: "general"
complexity: "beginner"
triggers: ["debug", "debugger", "erreur", "bug", "problème", "error"]
priority: 7
source: "axiom-scaffold"
---

# Skill : Debugging

## Méta-données

- **Domaine** : Général
- **Complexité** : Débutant
- **Déclencheurs** : debug, debugger, erreur, bug, problème, error
- **Source** : axiom-scaffold

---

## Objectif

Ce skill explique comment déboguer efficacement du code en utilisant une approche méthodique.

---

## Processus

### Étape 1 : Reproduire le Bug

1. **Identifier les conditions** : Quand le bug se produit-il ?
2. **Créer un cas de test** : Écrire un test qui reproduit le bug
3. **Vérifier la reproductibilité** : Le bug se produit-il à chaque fois ?

```typescript
// Exemple de test qui reproduit un bug
describe('calculateTotal', () => {
  it('should handle negative numbers', () => {
    const result = calculateTotal([-10, 20, 30]);
    expect(result).toBe(40); // Échoue si le bug existe
  });
});
```

### Étape 2 : Isoler la Cause

1. **Utiliser le debugger** : Placer des breakpoints
2. **Inspecter les variables** : Vérifier les valeurs à chaque étape
3. **Réduire le scope** : Éliminer les parties qui fonctionnent

```typescript
// Utiliser le debugger
function calculateTotal(numbers: number[]): number {
  debugger; // Le debugger s'arrête ici
  
  let total = 0;
  for (const num of numbers) {
    debugger; // Inspecter num à chaque itération
    total += num;
  }
  
  return total;
}
```

### Étape 3 : Corriger et Vérifier

1. **Appliquer le fix** : Corriger le code
2. **Vérifier le test** : Le test doit passer
3. **Vérifier les régressions** : Tous les autres tests doivent passer

```typescript
// Fix : gérer les nombres négatifs
function calculateTotal(numbers: number[]): number {
  return numbers.reduce((sum, num) => {
    // Validation : ignorer les nombres invalides
    if (typeof num !== 'number' || isNaN(num)) {
      return sum;
    }
    return sum + num;
  }, 0);
}
```

---

## Anti-patterns

### ❌ Ne Pas Faire

1. **Modifier le code au hasard** : "Essayer des trucs" sans comprendre
2. **Ignorer les tests** : Ne pas écrire de test pour reproduire le bug
3. **Utiliser console.log partout** : Préférer le debugger
4. **Corriger sans comprendre** : Appliquer un fix sans comprendre la cause
5. **Ne pas vérifier les régressions** : Oublier de lancer tous les tests

### ✅ Faire

1. **Approche méthodique** : Suivre les étapes
2. **Écrire un test** : Reproduire le bug dans un test
3. **Utiliser le debugger** : Inspecter les variables
4. **Comprendre la cause** : Identifier la racine du problème
5. **Vérifier les régressions** : Lancer tous les tests

---

## Exemple de Code

### Avant (avec bug)

```typescript
function calculateDiscount(price: number, percentage: number): number {
  // Bug : ne vérifie pas les valeurs négatives
  return price - (price * percentage / 100);
}

// Problème : accepte des valeurs négatives
calculateDiscount(-100, 10); // Retourne -90 (incorrect)
```

### Après (corrigé)

```typescript
function calculateDiscount(price: number, percentage: number): number {
  // Validation des entrées
  if (price < 0) {
    throw new Error('Price cannot be negative');
  }
  if (percentage < 0 || percentage > 100) {
    throw new Error('Percentage must be between 0 and 100');
  }
  
  return price - (price * percentage / 100);
}

// Test
describe('calculateDiscount', () => {
  it('should throw error for negative price', () => {
    expect(() => calculateDiscount(-100, 10)).toThrow('Price cannot be negative');
  });
  
  it('should calculate discount correctly', () => {
    expect(calculateDiscount(100, 10)).toBe(90);
  });
});
```

---

## Vérification

### Comment vérifier que le résultat est correct ?

1. **Le test passe** : Le test qui reproduisait le bug doit maintenant passer
2. **Tous les tests passent** : Aucune régression
3. **Le code est plus robuste** : Validation des entrées ajoutée
4. **La cause est documentée** : Commentaire expliquant le fix

### Checklist

- [ ] Bug reproduit dans un test
- [ ] Cause identifiée
- [ ] Fix appliqué
- [ ] Test passe
- [ ] Tous les tests passent
- [ ] Code review effectuée
- [ ] Documentation mise à jour

---

## Outils Recommandés

### Debugger

- **VS Code** : Debugger intégré
- **Chrome DevTools** : Pour le frontend
- **Node.js Inspector** : Pour le backend

### Logging

- **Winston** : Logging structuré (Node.js)
- **Pino** : Logging performant (Node.js)
- **Console** : Pour le développement uniquement

### Monitoring

- **Sentry** : Tracking d'erreurs en production
- **Datadog** : Monitoring et APM
- **LogRocket** : Session replay

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2026-05-07
