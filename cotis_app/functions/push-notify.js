/**
 * Push Notify Bridge for KASED-APP (v1)
 *
 * Rôle : relayer vers OneSignal les notifications push multi-utilisateurs
 * quand un utilisateur crée/modifie/supprime un membre, une cotisation ou
 * un culte. L'app appelle cette fonction (fire-and-forget) après chaque
 * mutation réussie.
 *
 * Flux :
 *   1. L'app envoie : { event, actorEmail, actorName, entityLabel, extra }
 *      avec les headers `apikey` (clé anon InsForge) et
 *      `Authorization: Bearer <token de session de l'utilisateur>`.
 *   2. La fonction récupère la liste des emails de tous les utilisateurs
 *      (table `profiles` via l'API InsForge, avec le token de l'appelant).
 *   3. Elle exclut l'acteur de la liste (pas de notification à soi-même).
 *   4. Elle appelle l'API REST OneSignal avec include_aliases.external_id
 *      (external ID OneSignal = email, défini par OneSignal.login(email)
 *      dans l'app) pour notifier tous les autres appareils, même hors ligne.
 *
 * Variables d'environnement (à définir dans la console InsForge) :
 *   - ONESIGNAL_REST_API_KEY : clé REST OneSignal (SECRET — ne jamais
 *     embarquer dans l'app). Dashboard OneSignal → Settings → Keys & IDs.
 *   - ONESIGNAL_APP_ID : optionnel (défaut : App ID public du projet Kased).
 *
 * Limitation connue : la validation d'appel repose sur le header `apikey`
 * (clé anon, publique par nature). Pour une app de petite église, le risque
 * est acceptable ; une vraie protection nécessiterait une clé secrète
 * partagée côté serveur.
 */

const ONESIGNAL_API_URL = 'https://api.onesignal.com/notifications';
const INSFORGE_BASE_URL = 'https://pu74z8pe.us-east.insforge.app';

// App ID public OneSignal « Kased » (pas un secret).
const DEFAULT_ONESIGNAL_APP_ID = 'cd2949d4-8ab7-4ad0-8c32-e5599e1a9bd3';

// Whitelist des événements autorisés (un message par événement, en français).
const EVENT_MESSAGES = {
  membre_ajoute: {
    heading: 'Nouveau membre',
    content: '{actor} a ajouté {entity}',
  },
  membre_modifie: {
    heading: 'Membre modifié',
    content: '{actor} a modifié {entity}',
  },
  membre_supprime: {
    heading: 'Membre supprimé',
    content: '{actor} a supprimé {entity}',
  },
  cotisation_payee: {
    heading: 'Cotisation enregistrée',
    content: '{actor} a enregistré la cotisation de {entity}',
  },
  cotisation_modifiee: {
    heading: 'Cotisation modifiée',
    content: '{actor} a modifié la cotisation de {entity}',
  },
  cotisation_absente: {
    heading: 'Membre absent',
    content: '{actor} a marqué {entity} absent',
  },
  cotisations_bulk: {
    heading: 'Paiements mis à jour',
    content: '{actor} a marqué {entity}',
  },
  culte_cree: {
    heading: 'Nouveau culte',
    content: '{actor} a créé le culte du {entity}',
  },
  culte_modifie: {
    heading: 'Culte modifié',
    content: '{actor} a modifié le culte du {entity}',
  },
};

// Lecture d'une variable d'environnement (compatible Deno et Node).
function getEnv(name, fallback) {
  try {
    if (typeof Deno !== 'undefined' && Deno.env && Deno.env.get) {
      const value = Deno.env.get(name);
      if (value) return value;
    }
  } catch (_) { /* ignore */ }
  try {
    if (typeof process !== 'undefined' && process.env) {
      const value = process.env[name];
      if (value) return value;
    }
  } catch (_) { /* ignore */ }
  return fallback;
}

function jsonResponse(data, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Récupère la liste des emails de tous les utilisateurs enregistrés.
// Essaie l'endpoint REST `/api/profiles` (utilisé par google-auth-bridge),
// puis l'endpoint `/api/database/records/profiles`.
async function fetchAllUserEmails(token) {
  const headers = {
    'Authorization': `Bearer ${token}`,
    'apikey': token,
    'Content-Type': 'application/json',
  };

  const attempts = [
    `${INSFORGE_BASE_URL}/api/profiles?select=email`,
    `${INSFORGE_BASE_URL}/api/database/records/profiles?select=email`,
  ];

  let lastError = null;
  for (const url of attempts) {
    try {
      const res = await fetch(url, { headers });
      if (!res.ok) {
        lastError = `GET ${url} → ${res.status}`;
        continue;
      }
      const data = await res.json();
      const rows = Array.isArray(data) ? data : (data && data.data) || [];
      const emails = rows
        .map((r) => (r && r.email ? String(r.email).trim().toLowerCase() : ''))
        .filter((e) => e.length > 0 && e.includes('@'));
      if (emails.length > 0) return emails;
      lastError = `GET ${url} → liste vide`;
    } catch (e) {
      lastError = `GET ${url} → ${e && e.message ? e.message : e}`;
    }
  }
  throw new Error(`Impossible de lister les utilisateurs: ${lastError}`);
}

// Message par défaut si l'acteur n'a pas fourni de nom.
function actorDisplayName(actorName, actorEmail) {
  if (actorName && actorName.trim().length > 0) return actorName.trim();
  if (actorEmail && actorEmail.includes('@')) {
    return actorEmail.split('@')[0];
  }
  return 'Un utilisateur';
}

module.exports = async function (request) {
  try {
    const body = await request.json();
    const {
      event,
      actorEmail,
      actorName,
      entityLabel,
      extra,
    } = body || {};

    // 1. Validation de l'événement
    const messageTemplate = EVENT_MESSAGES[event];
    if (!messageTemplate) {
      return jsonResponse(
        { error: `Événement inconnu: ${event}` },
        400,
      );
    }

    // 2. Vérification minimale de l'appelant (clé anon comme google-auth-bridge)
    const apiKey = (request.headers && request.headers.get
      ? request.headers.get('apikey')
      : request.headers['apikey']) || '';
    if (!apiKey) {
      return jsonResponse({ error: 'Header apikey manquant' }, 401);
    }

    // Token de session de l'utilisateur (pour lister les profiles).
    const token = (request.headers && request.headers.get
      ? request.headers.get('authorization')
      : request.headers['authorization']) || '';
    const bearerToken = token.startsWith('Bearer ')
      ? token.slice('Bearer '.length)
      : token;

    // 3. Liste des destinataires = tous les utilisateurs sauf l'acteur
    let recipients = [];
    try {
      const allEmails = await fetchAllUserEmails(bearerToken);
      const actor = (actorEmail || '').trim().toLowerCase();
      recipients = allEmails
        .filter((email) => email !== actor)
        .filter((email, index, arr) => arr.indexOf(email) === index);
    } catch (e) {
      console.error('[push-notify] Listing users failed:', e.message || e);
      return jsonResponse(
        { error: 'Échec de la récupération des utilisateurs', details: e.message },
        502,
      );
    }

    if (recipients.length === 0) {
      return jsonResponse(
        { sent: false, reason: 'no_recipients', message: 'Aucun autre utilisateur à notifier' },
        200,
      );
    }

    // 4. Envoi via l'API REST OneSignal
    const restKey = getEnv('ONESIGNAL_REST_API_KEY', '');
    if (!restKey) {
      return jsonResponse(
        { error: 'ONESIGNAL_REST_API_KEY non configurée sur la fonction' },
        500,
      );
    }

    const appId = getEnv('ONESIGNAL_APP_ID', DEFAULT_ONESIGNAL_APP_ID);
    const actor = actorDisplayName(actorName, actorEmail);
    const entity = entityLabel || 'un élément';

    const heading = messageTemplate.heading;
    const content = messageTemplate.content
      .replace('{actor}', actor)
      .replace('{entity}', entity);

    const payload = {
      app_id: appId,
      include_aliases: { external_id: recipients },
      target_channel: 'push',
      headings: { en: heading, fr: heading },
      contents: { en: content, fr: content },
      data: {
        event: event,
        entityLabel: entityLabel || '',
        actorEmail: actorEmail || '',
        extra: extra || '',
      },
    };

    const oneSignalRes = await fetch(ONESIGNAL_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${restKey}`,
      },
      body: JSON.stringify(payload),
    });

    const responseBody = await oneSignalRes.text();
    if (!oneSignalRes.ok) {
      console.error(
        '[push-notify] OneSignal error:',
        oneSignalRes.status,
        responseBody,
      );
      return jsonResponse(
        {
          error: 'Erreur OneSignal',
          status: oneSignalRes.status,
          details: responseBody,
        },
        502,
      );
    }

    console.log(
      `[push-notify] Sent "${event}" to ${recipients.length} recipient(s):`,
      responseBody,
    );
    return jsonResponse({
      sent: true,
      event,
      recipients: recipients.length,
      oneSignal: responseBody ? JSON.parse(responseBody) : {},
    }, 200);
  } catch (err) {
    console.error('[push-notify] Exception:', err);
    return jsonResponse({ error: 'Service error', details: String(err) }, 500);
  }
};
