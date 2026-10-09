# Customer Google sign-in

The storefront uses the existing Supabase project `vpgexijihrozwugqqagy`.
The public login page is `https://denziphone.com/login.html`; successful sign-in
returns to `https://denziphone.com/account.html`.

## Google Cloud configuration

Use the existing Google Cloud project `denziphone`.

- Consent-screen app name: `Denz iPhones`.
- Audience: External, because customers use their own Google accounts.
- Support and developer contact email: choose the business owner's monitored email.
- OAuth client type: Web application.
- Suggested client name: `Denz iPhones website`.
- Authorized JavaScript origin: `https://denziphone.com`.
- Authorized redirect URI: `https://vpgexijihrozwugqqagy.supabase.co/auth/v1/callback`.
- Request only basic sign-in scopes: `openid`, email and profile.

Google's required policy acceptance must be completed by the account owner or
explicitly approved at the point of acceptance. Creating credentials also requires
the browser workflow's approval. The client secret belongs in Supabase's Google
provider settings; never put it in frontend code, Git, screenshots, or chat.

For general customer access, the Google application's audience must be In
production. Testing mode limits access to configured test users. Do not add
sensitive Google API scopes or an offline-access request for simple sign-in.

## Supabase configuration

- Site URL: `https://denziphone.com`.
- Redirect URLs: `https://denziphone.com/account.html` and
  `https://denziphone.com/login.html?reset=1` for the existing email reset flow.
- Authentication > Sign In / Providers > Google: enable Google and configure the
  matching Google OAuth client ID and client secret.
- Keep nonce checks enabled and require an email address.
- Keep owner access restricted by `denz_admin_emails` and existing database policies.

The frontend uses Supabase's public publishable key. Supabase stores the Google
client secret and exchanges OAuth responses. The browser persists and refreshes
the Supabase session. Google profile names are escaped before they are displayed.

## Verification

1. Confirm Supabase's public `/auth/v1/settings` reports `external.google: true`.
2. Click Continue with Google on the production login page.
3. Complete Google's account selection and consent, then confirm the account page
   shows the signed-in customer's email.
4. Refresh the account page and confirm the session persists.
5. Sign out and confirm the storefront returns to guest access.
6. Test a customer account outside the owner allowlist; owner tools must deny it.

Automated mocks verify frontend callback/error handling and account controls, but
cannot establish a successful live Google OAuth round trip or database policy
enforcement. Those checks require the configured provider and a real test account.

References:
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/guides/auth/redirect-urls
