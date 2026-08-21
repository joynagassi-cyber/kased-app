/**
 * Fonction keepalive InsForge
 *
 * Déclenchée par le cron schedule toutes les 5 minutes
 * pour empêcher la mise en veille de l'instance.
 */

module.exports = async function(request) {
  return new Response(JSON.stringify({
    status: 'ok',
    timestamp: new Date().toISOString(),
    message: 'Instance keepalive - pas de mise en veille'
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
};
