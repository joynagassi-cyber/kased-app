/**
 * Google Auth Bridge for KASED-APP (v7)
 *
 * Features:
 * - Audience validation (Android Client ID)
 * - Provider tracking (google vs email)
 * - Generic error reporting
 * - Salted internal password
 * - Automatic Profile creation
 * - InsForge anon key header on ALL auth requests
 *
 * CHANGELOG v7:
 * - Add provider: 'google' to user creation to distinguish from email auth
 * - Use Android Client ID for EXPECTED_CLIENT_ID
 * - Store Google sub as metadata for cross-device linking
 */

// Android Client ID Google — must match serverClientId in auth_service.dart
const EXPECTED_CLIENT_ID = '535496831713-eqn2k8iasrmbfuk7r91nn43bnoenkma7.apps.googleusercontent.com';
const INTERNAL_SALT = 'KASED_SECURE_SALT_2026_v1';

module.exports = async function(request) {
  try {
    const body = await request.json();
    const idToken = body.idToken;

    if (!idToken) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // 1. Validate Google Token
    const googleRes = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!googleRes.ok) {
      return new Response(JSON.stringify({ error: 'Invalid authentication source' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const googleData = await googleRes.json();

    // 2. Security Check: Audience validation
    if (googleData.aud !== EXPECTED_CLIENT_ID) {
      console.error(`Security Alert: Audience mismatch. Expected: ${EXPECTED_CLIENT_ID}, Got: ${googleData.aud}`);
      return new Response(JSON.stringify({ error: 'Security validation failed' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const email = googleData.email;
    const name = googleData.name || 'Utilisateur Google';
    const googleId = googleData.sub;
    // Password dérivé du Google ID + sel — unique par utilisateur
    const password = `GAuth_${googleId}_${INTERNAL_SALT.substring(0, 8)}`;

    const baseUrl = 'https://pu74z8pe.us-east.insforge.app';

    // InsForge exige la clé anon sur CHAQUE requête.
    const bridgeHeaders = {
      'Content-Type': 'application/json',
      'apikey': '__INSFORGE_ANON_KEY__',
      'Authorization': 'Bearer __INSFORGE_ANON_KEY__'
    };

    // 3. Login or Signup — with provider: 'google'
    let authData;
    const loginRes = await fetch(`${baseUrl}/api/auth/sessions?client_type=mobile`, {
      method: 'POST',
      headers: bridgeHeaders,
      body: JSON.stringify({
        email,
        password,
        provider: 'google', // CRITIQUE: identifie le provider comme Google
        app_metadata: {
          google_id: googleId,
          name: name
        }
      })
    });

    if (loginRes.ok) {
      authData = await loginRes.json();
    } else if (loginRes.status === 401) {
      // User not found — create account with provider: google
      const signUpRes = await fetch(`${baseUrl}/api/auth/users?client_type=mobile`, {
        method: 'POST',
        headers: bridgeHeaders,
        body: JSON.stringify({
          email,
          password,
          name,
          provider: 'google', // CRITIQUE: provider explicitement défini
          app_metadata: {
            google_id: googleId,
            picture: googleData.picture
          }
        })
      });

      if (signUpRes.ok) {
        authData = await signUpRes.json();
      } else {
        const errorData = await signUpRes.json();
        const errorMsg = errorData.message || errorData.msg || '';

        // Check for email collision (if the user already signed up with password)
        if (signUpRes.status === 409 || signUpRes.status === 422 ||
            errorMsg.toLowerCase().includes('already registered') ||
            errorMsg.toLowerCase().includes('already exists')) {
          return new Response(JSON.stringify({
            error: 'ACCOUNT_EXISTS_WITH_PASSWORD',
            message: 'Un compte existe déjà avec cet email. Veuillez vous connecter avec votre mot de passe.',
            details: errorData
          }), {
            status: 409,
            headers: { 'Content-Type': 'application/json' }
          });
        }

        return new Response(JSON.stringify({ error: 'Account provisioning failed', details: errorData }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    } else {
      return new Response(JSON.stringify({ error: 'Login service unavailable' }), {
        status: loginRes.status,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const accessToken = authData.access_token || authData.accessToken;
    const userId = authData.user.id;

    // 4. Profile Management (Upsert) — link Google ID to profile
    await fetch(`${baseUrl}/api/database/records/profiles`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
        'apikey': accessToken,
        'Prefer': 'resolution=merge-duplicates'
      },
      body: JSON.stringify([{
        id: userId,
        email: email,
        provider: 'google',
        google_id: googleId
      }]),
    });

    return new Response(JSON.stringify({
      ...authData,
      role: 'authenticated',
      provider: 'google', // CRITIQUE: retourne le provider pour le client
      source: 'google-bridge-v7'
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
