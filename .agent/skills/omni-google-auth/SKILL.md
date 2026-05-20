---
name: omni-google-auth
description: Guide for setting up secure, dynamic Google Authentication across platforms (Flutter, React Native, Next.js, Node.js, Rust) using Firebase, Google Cloud Console, and modern BaaS (InsForge, Supabase). Use when the user wants to integrate Google Sign-In, OAuth, or fix Google Auth issues.
---

# Omni Google Auth Master

This skill provides the ultimate workflow for implementing a secure, robust, and fluid Google Authentication system. It covers the end-to-end setup across various frontend frameworks and Backend-as-a-Service (BaaS) platforms, preventing common pitfalls like `ApiException: 10`, audience mismatches, and token hijacking.

## 0. Prerequisite: Dynamic Documentation Retrieval (CRITICAL)
Before generating any authentication code, **you MUST consult the official documentation** for the target BaaS to adapt to recent API changes:
- **For InsForge**: You MUST call the MCP tools `fetch-docs` (e.g., `auth-sdk-typescript`) or `fetch-sdk-docs` (e.g., `auth`, `swift`/`kotlin`/`typescript`).
- **For Supabase**: You MUST execute a web search (e.g., `site:supabase.com/docs google auth flutter` or `site:supabase.com/docs guides/auth/social-login/auth-google`).
- **For other platforms (Firebase Auth, Appwrite, etc.)**: Use available MCP docs or `search_web`.

## 1. Google Cloud Console (GCP) & Firebase Setup
The foundation of Google Auth requires strict alignment between GCP and Firebase.
1. **Firebase Project**: Create a Firebase project. This automatically creates a GCP project.
2. **Web Client ID**: In GCP Credentials, find the automatically generated "Web client (auto created by Google Service)". **This is your `serverClientId`**. You MUST use this ID in your frontend configuration and backend validation.
3. **Android Configuration**:
   - Add the Android app in Firebase.
   - Enter the package name and **both Debug and Release SHA-1 fingerprints**. (Extract via `./gradlew signingReport` or `keytool`).
   - Download the `google-services.json` file and place it exactly in `android/app/`.
4. **iOS/macOS Configuration**:
   - Add the iOS app in Firebase (using the bundle ID).
   - Download `GoogleService-Info.plist` and add it via Xcode to the runner.
   - Copy the `REVERSED_CLIENT_ID` into the URL Types in Xcode Info tab.

## 2. Destination Platform Configuration (BaaS)

### InsForge
1. Ensure the InsForge backend project is created.
2. If using the custom Edge Function bridge (like `google-auth-bridge`):
   - The edge function MUST validate the `idToken` via `oauth2.googleapis.com/tokeninfo`.
   - The edge function MUST verify `aud === EXPECTED_CLIENT_ID` (the Web Client ID).
   - Use the `mcp_insforge_update-function` tool to deploy the secure bridge.
3. If using direct SDK Auth, check the `fetch-sdk-docs` for `auth`.

### Supabase
1. Go to Authentication -> Providers -> Google in the Supabase Dashboard.
2. Enable Google.
3. Input the **Web Client ID** and **Web Client Secret** from GCP.
4. For native mobile sign-in (skipping the web browser), configure the Authorized Client IDs (Android and iOS Client IDs from GCP).

## 3. Frontend Implementation Guides

### Flutter (Mobile, Web, Desktop)
- **Package**: `google_sign_in` (and `supabase_flutter` or `@insforge/sdk` via bridge).
- **Security Rule**: For Android, you **MUST** pass the `serverClientId` to the `GoogleSignIn` constructor. Without this, the `idToken` will have an Android audience, causing backend validation to fail (often resulting in `ApiException: 10`).
  ```dart
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  ```

### React Native (Mobile)
- **Package**: `@react-native-google-signin/google-signin`.
- **Security Rule**: Call `GoogleSignin.configure({ webClientId: 'YOUR_WEB_CLIENT_ID' })`.
- Pass the resulting `idToken` to your BaaS provider.

### Next.js (React Web)
- **Package**: `@supabase/ssr` or `next-auth` (Auth.js) or InsForge SDK.
- Use the standard OAuth flow (PKCE). Mobile SDKs use `idToken`, but Web usually relies on standard OAuth redirection or popups.

### Node.js (Backend / Edge)
- **Package**: `google-auth-library` or standard `fetch` to Google endpoints.
- **Validation**: Always verify the `idToken`'s signature and audience before provisioning a session.

### Rust (Backend)
- **Crate**: `jsonwebtoken` (to verify Google certs) or `reqwest` to call tokeninfo endpoint.
- Ensure structs strictly map to Google's JWT claims (`iss`, `aud`, `exp`, `sub`, `email`).

## 4. Ultra-Security Checklist
- [ ] **Audience Check**: The backend MUST reject any token where the `aud` claim does not exactly match the Web Client ID.
- [ ] **No Hardcoded Secrets in App**: Never put the Client Secret in client-side code (Flutter, RN, frontend Web).
- [ ] **Expiration Check**: The backend MUST check if the token is expired.
- [ ] **Secure Storage**: Once authenticated, the BaaS session (JWT access/refresh tokens) MUST be stored securely (`flutter_secure_storage`, React Native Keychain, HTTP-only secure cookies on Web).
- [ ] **Duplicate Merging**: Handle scenarios where a user signs in with Google but already has an email/password account. Link the identities gracefully.

## 5. Agent Workflow for Applying This Skill
When tasked to create or fix a Google Auth integration:
1. **Analyze**: Identify the framework (Flutter/React/etc.) and the backend (InsForge/Supabase).
2. **Fetch Docs**: Use MCP or Web Search to get the latest implementation guide for the target BaaS.
3. **Verify Configs**: Ask the user to provide/confirm their SHA-1 keys and `google-services.json` status.
4. **Implement**: Write the frontend code with `serverClientId`/`webClientId` strictly enforced.
5. **Bridge/Backend**: Write the backend validation logic.
6. **Test**: Instruct the user to run on a physical device or emulator.
