/**
 * Google Auth Bridge for KASED-APP (v8 - CORRECTED)
 *
 * CRITICAL FIX: All internal InsForge API calls now include the 'apikey' header.
 * Previous version was missing apikey on /api/auth/sessions and /api/auth/users calls,
 * causing 500 errors.
 */

const EXPECTED_CLIENT_ID = '535496831713-4ol3svlekn919034dp509bbi6i9j0ndo.apps.googleusercontent.com';
const INTERNAL_SALT = 'KASED_SECURE_SALT_2026_v1';
const INSFORGE_BASE_URL = 'https://pu74z8pe.us-east.insforge.app';
// Get anon key from environment variables (set in InsForge dashboard)
const INSFORGE_ANON_KEY = Deno.env.get('INSFORGE_ANON_KEY') || '';

export default async function (request) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  try {
    const body = await request.json();
    const idToken = body?.idToken;

    if (!idToken) {
      return new Response(
        JSON.stringify({ error: 'Authentication required', message: 'idToken is missing' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Validate Google ID Token
    const googleVerifyUrl = `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`;
    const googleRes = await fetch(googleVerifyUrl);

    if (!googleRes.ok) {
      console.error('Google token validation failed:', await googleRes.text());
      return new Response(
        JSON.stringify({ error: 'Invalid authentication source', message: 'Google token validation failed' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const googleData = await googleRes.json();

    // 2. Audience validation
    if (googleData.aud !== EXPECTED_CLIENT_ID) {
      console.error(`Security Alert: Audience mismatch. Expected: ${EXPECTED_CLIENT_ID}, Got: ${googleData.aud}`);
      return new Response(
        JSON.stringify({ error: 'Security validation failed', message: 'Invalid client ID' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const email = googleData.email;
    const name = googleData.name || 'Utilisateur Google';
    const googleId = googleData.sub;

    // Create a secure password from Google ID
    const password = `GAuth_${googleId}_${INTERNAL_SALT.substring(0, 8)}`;

    console.log(`Processing auth for: ${email}`);

    // CRITICAL FIX: Headers communs pour tous les appels internes - DOIT inclure apikey
    const internalHeaders = {
      'Content-Type': 'application/json',
      'apikey': INSFORGE_ANON_KEY,
    };

    // 3. Try to login first
    let authData;
    let loginRes;
    try {
      loginRes = await fetch(
        `${INSFORGE_BASE_URL}/api/auth/sessions?client_type=mobile`,
        {
          method: 'POST',
          headers: internalHeaders,  // CRITICAL: includes apikey
          body: JSON.stringify({ email, password }),
        }
      );

      if (loginRes.ok) {
        authData = await loginRes.json();
        console.log(`Login successful for: ${email}`);
      }
    } catch (loginErr) {
      console.error('Login error:', loginErr.message);
    }

    // 4. If login fails (401 = user doesn't exist), try signup
    if (!authData && loginRes?.status === 401) {
      let signUpRes;
      try {
        signUpRes = await fetch(
          `${INSFORGE_BASE_URL}/api/auth/users?client_type=mobile`,
          {
            method: 'POST',
            headers: internalHeaders,  // CRITICAL: includes apikey
            body: JSON.stringify({ email, password, name }),
          }
        );

        if (signUpRes.ok) {
          authData = await signUpRes.json();
          console.log(`New user created: ${email}`);
        } else {
          const errorData = await signUpRes.json().catch(() => ({}));
          const errorMsg = JSON.stringify(errorData).toLowerCase();

          // Check for email collision
          if (signUpRes.status === 409 || signUpRes.status === 422 ||
              errorMsg.includes('already') || errorMsg.includes('exists') ||
              errorMsg.includes('email')) {
            return new Response(
              JSON.stringify({
                error: 'ACCOUNT_EXISTS_WITH_PASSWORD',
                message: 'Un compte existe déjà avec cet email. Veuillez vous connecter avec votre mot de passe.'
              }),
              { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            );
          }

          console.error(`Signup failed for ${email}:`, errorData);
          return new Response(
            JSON.stringify({ error: 'Account provisioning failed', details: errorData }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }
      } catch (signUpErr) {
        console.error('Signup error:', signUpErr.message);
        return new Response(
          JSON.stringify({ error: 'Signup service error', message: signUpErr.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    if (!authData) {
      console.error('Failed to authenticate user:', email);
      return new Response(
        JSON.stringify({ error: 'Authentication failed', message: 'Unable to login or create account' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const accessToken = authData.access_token || authData.accessToken;
    const refreshToken = authData.refresh_token || authData.refreshToken;
    const userId = authData.user?.id;

    // 5. Sync profile if access token available
    if (accessToken && userId) {
      try {
        await fetch(
          `${INSFORGE_BASE_URL}/api/database/records/profiles`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${accessToken}`,
              'apikey': accessToken,
              'Prefer': 'resolution=merge-duplicates',
            },
            body: JSON.stringify([{ id: userId, email: email }]),
          }
        );
      } catch (profileErr) {
        console.warn('Profile sync failed (non-critical):', profileErr.message);
      }
    }

    return new Response(
      JSON.stringify({
        access_token: accessToken,
        refresh_token: refreshToken,
        user: {
          id: userId,
          email: email,
          name: name,
        },
        role: 'authenticated',
        source: 'google-bridge-v8-fixed',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Bridge Exception:', err);
    return new Response(
      JSON.stringify({ error: 'Service error', message: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}
