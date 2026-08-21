/**
 * Fonction de rappel dominical Kased
 *
 * Déclenchée chaque dimanche à 9h par le cron schedule.
 * Envoie une notification push à tous les utilisateurs
 * pour leur rappeler de valider leurs paiements.
 */

module.exports = async function(request) {
  try {
    const body = await request.json();
    const baseUrl = 'https://pu74z8pe.us-east.insforge.app';

    // Récupérer tous les membres actifs
    const membresRes = await fetch(
      `${baseUrl}/api/database/records/membres?is_active=eq.true&is_deleted=eq.false&order=prenom.asc&limit=100`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'apikey': request.headers.get('apikey') || '__INSFORGE_ANON_KEY__',
          'Authorization': `Bearer ${request.headers.get('apikey') || '__INSFORGE_ANON_KEY__'}`,
        },
      }
    );

    if (!membresRes.ok) {
      console.error('Erreur récupération membres:', membresRes.status);
      return new Response(JSON.stringify({ error: 'Failed to fetch membres' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const membres = await membresRes.json();

    if (!Array.isArray(membres) || membres.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: 'No active members' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Envoyer une notification push à chaque membre via OneSignal
    let sent = 0;
    for (const membre of membres) {
      const email = membre.user_id; // externalId = user_id
      if (!email) continue;

      try {
        await fetch(`${baseUrl}/functions/push-notify`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': request.headers.get('apikey') || '__INSFORGE_ANON_KEY__',
            'Authorization': `Bearer ${request.headers.get('apikey') || '__INSFORGE_ANON_KEY__'}`,
          },
          body: JSON.stringify({
            event: 'dom_reminder',
            entityLabel: `Rappel culte - ${membre.prenom} ${membre.nom}`,
          }),
        });
        sent++;
      } catch (e) {
        console.error(`Erreur push vers ${email}:`, e.message);
      }
    }

    return new Response(JSON.stringify({
      sent,
      total: membres.length,
      message: `Rappel dominical envoyé à ${sent} utilisateur(s)`
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (err) {
    console.error('Bridge Exception:', err);
    return new Response(JSON.stringify({ error: 'Service error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
