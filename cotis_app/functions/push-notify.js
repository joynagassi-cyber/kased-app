/**
 * Push Notify Bridge for KASED-APP (v2)
 *
 * Rôle : relayer vers OneSignal les notifications push multi-utilisateurs
 * quand un utilisateur crée/modifie/supprime un membre, une cotisation ou
 * un culte. L'app appelle cette fonction (fire-and-forget) après chaque
 * mutation réussie, sur `${INSFORGE_BASE_URL}/functions/push-notify`.
 *
 * Flux :
 *   1. L'app envoie : { event, actorEmail, actorName, entityLabel, extra }
 *      avec les headers `apikey` (clé anon InsForge) et
 *      `Authorization: Bearer <token de session de l'utilisateur>`.
 *   2. La fonction liste les emails de tous les utilisateurs
 *      (`/api/database/records/profiles`) et exclut l'acteur : celui-ci
 *      reçoit déjà une notification locale côté app.
 *   3. Elle cible ces emails via include_aliases.external_id
 *      (external ID OneSignal = email, défini par OneSignal.login(email)).
 *   4. Si la liste des profils est indisponible, repli sur un ciblage par
 *      tag `user_email` (défini par l'app), puis sur l'ensemble des
 *      abonnés : une notification est toujours envoyée.
 *
 * Clé REST OneSignal : injectée au déploiement par
 * `scripts/deploy-insforge-functions.sh` (placeholder ci-dessous). Elle ne
 * doit JAMAIS être commitée ni embarquée dans l'app Flutter.
 */

const ONESIGNAL_API_URL = 'https://api.onesignal.com/notifications';
const INSFORGE_BASE_URL = 'https://pu74z8pe.us-east.insforge.app';

// App ID public OneSignal « Kased » (pas un secret).
const DEFAULT_ONESIGNAL_APP_ID = 'cd2949d4-8ab7-4ad0-8c32-e5599e1a9bd3';

// Remplacé au déploiement par la vraie clé REST (voir en-tête).
const ONESIGNAL_REST_API_KEY_INLINE = '__ONESIGNAL_REST_API_KEY__';

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

function restApiKey() {
  const fromEnv = getEnv('ONESIGNAL_REST_API_KEY', '');
  if (fromEnv) return fromEnv;
  return ONESIGNAL_REST_API_KEY_INLINE.startsWith('__')
    ? ''
    : ONESIGNAL_REST_API_KEY_INLINE;
}

function jsonResponse(data, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

function header(request, name) {
  if (request.headers && request.headers.get) {
    return request.headers.get(name) || '';
  }
  return (request.headers && request.headers[name]) || '';
}

// Emails de tous les utilisateurs enregistrés (table `profiles`, alimentée
// par le trigger auth.users → profiles).
async function fetchAllUserEmails(token, apiKey) {
  const url = `${INSFORGE_BASE_URL}/api/database/records/profiles?select=email`;
  const res = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token || apiKey}`,
      'apikey': apiKey || token,
      'Content-Type': 'application/json',
    },
  });
  if (!res.ok) {
    throw new Error(`GET profiles → ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  const rows = Array.isArray(data) ? data : (data && data.data) || [];
  return rows
    .map((r) => (r && r.email ? String(r.email).trim().toLowerCase() : ''))
    .filter((e) => e.length > 0 && e.includes('@'));
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
    const { event, actorEmail, actorName, entityLabel, extra } = body || {};

    const messageTemplate = EVENT_MESSAGES[event];
    if (!messageTemplate) {
      return jsonResponse({ error: `Événement inconnu: ${event}` }, 400);
    }

    const apiKey = header(request, 'apikey');
    if (!apiKey) {
      return jsonResponse({ error: 'Header apikey manquant' }, 401);
    }

    const rawAuth = header(request, 'authorization');
    const bearerToken = rawAuth.startsWith('Bearer ')
      ? rawAuth.slice('Bearer '.length)
      : rawAuth;

    const restKey = restApiKey();
    if (!restKey) {
      return jsonResponse(
        { error: 'ONESIGNAL_REST_API_KEY non configurée sur la fonction' },
        500,
      );
    }

    const actor = (actorEmail || '').trim().toLowerCase();

    // Ciblage : tous les utilisateurs sauf l'acteur.
    let targeting = null;
    let recipients = 0;
    let strategy = '';
    try {
      const allEmails = await fetchAllUserEmails(bearerToken, apiKey);
      const others = allEmails
        .filter((email) => email !== actor)
        .filter((email, index, arr) => arr.indexOf(email) === index);
      if (others.length > 0) {
        targeting = { include_aliases: { external_id: others } };
        recipients = others.length;
        strategy = 'external_id';
      } else if (allEmails.length > 0) {
        return jsonResponse(
          { sent: false, reason: 'no_recipients' },
          200,
        );
      }
    } catch (e) {
      console.error('[push-notify] Listing profiles failed:', e.message || e);
    }

    // Repli : ciblage par tag, puis diffusion générale.
    if (!targeting) {
      strategy = actor ? 'tag_filter' : 'all_subscriptions';
      targeting = actor
        ? {
            filters: [
              { field: 'tag', key: 'user_email', relation: '!=', value: actor },
            ],
          }
        : { included_segments: ['Total Subscriptions'] };
    }

    const heading = messageTemplate.heading;
    const content = messageTemplate.content
      .replace('{actor}', actorDisplayName(actorName, actorEmail))
      .replace('{entity}', entityLabel || 'un élément');

    const payload = Object.assign(
      {
        app_id: getEnv('ONESIGNAL_APP_ID', DEFAULT_ONESIGNAL_APP_ID),
        target_channel: 'push',
        headings: { en: heading, fr: heading },
        contents: { en: content, fr: content },
        data: {
          event: event,
          entityLabel: entityLabel || '',
          actorEmail: actorEmail || '',
          extra: extra || '',
        },
      },
      targeting,
    );

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
      console.error('[push-notify] OneSignal error:', oneSignalRes.status, responseBody);
      return jsonResponse(
        { error: 'Erreur OneSignal', status: oneSignalRes.status, details: responseBody },
        502,
      );
    }

    console.log(`[push-notify] "${event}" via ${strategy} → ${responseBody}`);
    return jsonResponse(
      {
        sent: true,
        event,
        strategy,
        recipients,
        oneSignal: responseBody ? JSON.parse(responseBody) : {},
      },
      200,
    );
  } catch (err) {
    console.error('[push-notify] Exception:', err);
    return jsonResponse({ error: 'Service error', details: String(err) }, 500);
  }
};
