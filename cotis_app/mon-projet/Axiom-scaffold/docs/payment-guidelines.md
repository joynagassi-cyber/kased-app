# Payment Guidelines — Axiom-Scaffold

## Introduction

Ce document décrit les règles et politiques de gestion des paiements dans Axiom-Scaffold. Il s'applique à toutes les intégrations de paiement, notamment avec **Stripe**.

## Règles de Sécurité

### PCI-DSS Compliance

Toutes les transactions de paiement doivent respecter les normes **PCI-DSS** (Payment Card Industry Data Security Standard).

**Exigences :**
- ✅ Ne jamais stocker les numéros de carte en clair
- ✅ Utiliser HTTPS pour toutes les communications
- ✅ Tokeniser les informations de paiement
- ✅ Logger tous les événements de paiement

### Idempotency Key

**Règle obligatoire** : Chaque requête de création de session de paiement doit inclure une **clé d'idempotence** unique.

**Objectif** : Éviter les doubles paiements en cas de retry réseau.

**Implémentation** :
```typescript
// ✅ Correct
const session = await stripe.checkout.sessions.create({
  // ... params
}, {
  idempotencyKey: `checkout_${userId}_${timestamp}`
});

// ❌ Incorrect (pas de clé d'idempotence)
const session = await stripe.checkout.sessions.create({
  // ... params
});
```

**Fichiers concernés** :
- `src/payment/checkoutSession.ts`
- `src/payment/refund.ts`

## Stripe Integration

### Scopes Requis

Pour créer une session de paiement, l'application doit avoir le scope OAuth suivant :

- `write:checkout_sessions`

### Webhook Events

Les événements Stripe suivants doivent être gérés :

| Événement                       | Handler                   | Description                  |
| ------------------------------- | ------------------------- | ---------------------------- |
| `checkout.session.completed`    | `handleCheckoutCompleted` | Session de paiement terminée |
| `payment_intent.succeeded`      | `handlePaymentSuccess`    | Paiement réussi              |
| `payment_intent.payment_failed` | `handlePaymentFailed`     | Paiement échoué              |
| `charge.refunded`               | `handleRefund`            | Remboursement effectué       |

### Gestion des Erreurs

**Politique de retry** :
- Retry automatique : 3 tentatives avec backoff exponentiel
- Délai initial : 1 seconde
- Facteur de multiplication : 2

**Codes d'erreur à gérer** :
- `card_declined` : Carte refusée
- `insufficient_funds` : Fonds insuffisants
- `expired_card` : Carte expirée
- `processing_error` : Erreur de traitement

## Refund Policy

### Règles de Remboursement

1. **Délai maximum** : 30 jours après le paiement
2. **Montant** : Remboursement partiel ou total autorisé
3. **Raison obligatoire** : Chaque remboursement doit avoir une raison documentée

### Workflow de Remboursement

```
Utilisateur demande remboursement
    ↓
Vérification éligibilité (< 30 jours)
    ↓
Validation manuelle (si > 100€)
    ↓
Création du refund Stripe
    ↓
Notification utilisateur
    ↓
Mise à jour du statut de commande
```

## Monitoring

### Métriques à Surveiller

- **Taux de succès des paiements** : > 95%
- **Temps de réponse API Stripe** : < 2 secondes
- **Taux de refund** : < 5%
- **Erreurs de webhook** : 0 par jour

### Alertes

Configurer des alertes pour :
- Taux de succès < 90%
- Temps de réponse > 5 secondes
- Webhook en échec > 3 fois

## Références

- [Stripe API Documentation](https://stripe.com/docs/api)
- [PCI-DSS Standards](https://www.pcisecuritystandards.org/)
- [OWASP Payment Security](https://owasp.org/www-community/vulnerabilities/Payment_Card_Industry_Data_Security_Standard)

## Changelog

- **2026-05-09** : Création du document
- **2026-05-09** : Ajout des règles d'idempotence

---

**Auteur** : Axiom-Scaffold Team  
**Version** : 1.0.0  
**Statut** : ✅ Approuvé
