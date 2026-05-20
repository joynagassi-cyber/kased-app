/**
 * Google Auth Bridge for KASED-APP (v5)
 * 
 * Features:
 * - Audience validation (Firebase Web Client ID)
 * - Generic error reporting
 * - Salted internal password
 * - Automatic Profile creation (No roles)
 * 
 * CHANGELOG v5:
 * - EXPECTED_CLIENT_ID updated to Firebase Web Client (4ol3...)
 *   to match serverClientId set in the Flutter GoogleSignIn constructor
 */

// Firebase Web Client ID — must match serverClientId in auth_service.dart
const EXPECTED_CLIENT_ID = '535496831713-4ol3svlekn919034dp509bbi6i9j0ndo.apps.googleusercontent.com';
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
    const password = `GAuth_${googleId}_${INTERNAL_SALT.substring(0, 8)}`; 

    const baseUrl = 'https://pu74z8pe.us-east.insforge.app';
    
    // 3. Login or Signup
    let authData;
    const loginRes = await fetch(`${baseUrl}/api/auth/sessions?client_type=mobile`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    if (loginRes.ok) {
      authData = await loginRes.json();
    } else if (loginRes.status === 401) {
      const signUpRes = await fetch(`${baseUrl}/api/auth/users?client_type=mobile`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, name })
      });

      if (signUpRes.ok) {
        authData = await signUpRes.json();
      } else {
        const errorData = await signUpRes.json();
        
        // Check for email collision (if the user already signed up with password)
        // InsForge / Supabase usually returns 422 or 400 with a specific message for existing emails.
        const errorMsg = errorData.message || errorData.msg || '';
        if (signUpRes.status === 409 || signUpRes.status === 422 || errorMsg.toLowerCase().includes('already registered') || errorMsg.toLowerCase().includes('already exists')) {
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

    // 4. Profile Management (Upsert)
    await fetch(`${baseUrl}/api/profiles`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
        'Prefer': 'resolution=merge-duplicates'
      },
      body: JSON.stringify([{
        id: userId,
        email: email
      }]),
    });

    return new Response(JSON.stringify({
      ...authData,
      role: 'authenticated',
      source: 'google-bridge-v5'
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
