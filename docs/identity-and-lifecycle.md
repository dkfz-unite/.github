# Identity, permissions, tokens, and account lifecycle

Last updated: 2026-10-12.

The owner explained Identity's responsibility during onboarding. Selected local
code confirms the instance modes, JWT construction, root bootstrap, sessions,
and saved-data cleanup. Complete cross-service authorization and project
privacy enforcement remain separate verification tasks.

## Responsibility and instance access

`unite-identity` authenticates users, manages accounts and sessions, and issues
authorization tokens. The exact setting is `UNITE_INSTANCE_PUBLIC`:

| Setting | Instance access |
| --- | --- |
| `true` | Users can register and log in without an administrator adding their email to the access list |
| `false` | Only users whose email has been added by an administrator can register/use the instance |

The current option defaults to `false` when unset. The reviewed registration
endpoint selects `AddPublic` or `AddPrivate` accordingly. The main identity
providers are described below; deployment-specific provider choices still
need verification.

**Instance access** is different from **project visibility**. A public instance
allows registration; it does not make private-project data public or remove
authentication from biomedical data APIs. The owner described data APIs as
authenticated, with login/registration as public entry points. Some additional
identity endpoints, such as password-reset availability, are explicitly
anonymous in code; do not interpret the owner's overview as an exhaustive
endpoint inventory.

See [Search and access](search-and-access.md) for personal project scope.

## Identity providers and SMTP mail

The owner confirmed that Identity includes both the standard provider and an
LDAP provider. LDAP authenticates credentials against the organization's LDAP
server and is used alongside the standard login.

The reviewed `LdapIdentityService` finds the LDAP user, requires an active
matching UNITE user for the LDAP provider, and performs an LDAP bind with the
supplied credentials. Successful login still creates the ordinary UNITE session
and JWT; LDAP credential checking does not replace UNITE permissions or project
visibility. Do not infer automatic registration of all directory users from
the presence of LDAP authentication.

`UNITE_LDAP_ACTIVE` enables the LDAP provider. Other `UNITE_LDAP_*` settings
cover its label/priority, server host/port, target OU, and directory service
account. `RootWorker` creates/updates provider records and the active-provider
endpoint lists them by priority.

LDAP runs **alongside** the standard login; this is the intended setup (owner,
2026-10-12). The standard provider cannot be disabled or hidden:
`DefaultProviderOptions.Active` always returns `true` because the root
administrator exists only in the standard provider and must always be able to
log in. Do not add an option to disable it.

The repository also contains **`Unite.Post`**, an internal mail project used by
Identity Web, rather than a separate deployed service. The owner described it
as the current email sender. The reviewed `MailService` sends password-reset
emails through `MailClient`, which uses SMTP settings supplied by Identity's
`SmtpOptions`.

The `UNITE_SMTP_*` settings configure the host, port, connection/authentication
options, sender, and credentials. Identity's existing README documents the
full settings and reset behavior; credentials belong in installation
configuration, not shared onboarding. SMTP is optional in the current code:
without a configured host, the password-reset endpoints return 503. This is
the intended behavior (owner, 2026-10-12): without SMTP, users are told that
reset is unavailable and an administrator recreates the account; other reset
mechanisms are out of scope for now. Passwords are stored as salted
`PasswordHasher` hashes; old MD5 hashes are not migrated. unite-env's
Identity Compose hard-codes `UNITE_SMTP_HOST: ""` and sets no `UNITE_LDAP_*`
variables, so a standard deployment has neither password reset nor LDAP unless
that file is edited.
`UNITE_INSTANCE_HOST` supplies the portal base URL for reset links.

## Permissions and root administrator

The owner identified two permissions used by the application:

- `Data.Read`: standard data-reading permission; current default permissions
  contain this value.
- `Data.Write`: permits data changes, including submission of new data and
  deletion. This does not change the standard submission-review workflow.

Other permissions, if present in enums, are not in active use according to the
owner. Do not infer an implemented role/workflow from enum membership alone.
Endpoint policy and project scope must be checked in their consuming services;
having a valid signature alone does not establish a caller's authorization.

The root administrator can perform all administrative operations; it is the
only administrator (Identity's admin endpoints require role `Root`, and the
portal should use the same rule). The owner
configures its credentials in the installation's `.env.secrets`
(`UNITE_ADMIN_USER`/`UNITE_ADMIN_PASSWORD`), which Identity's Compose passes
to the service. `RootWorker`
creates the configured root account if it is absent, with the `Root` role and
root permission set. This bootstrap does not reset an existing account on each
startup. Root is excluded from inactivity cleanup and self-deletion.

No actual credentials or secret-file contents belong in shared onboarding.

## JWT authentication and service tokens

After successful user authentication, Identity issues a JWT with identity and
permission claims. Internal services use the shared `UNITE_API_KEY` to validate
it. The reviewed implementation uses an HMAC-SHA256 **signature**, not JWT
payload encryption. Validation checks the signing key and token lifetime;
authorization then uses the actor/role/permission claims and endpoint policies.

The current key option requires a 32-character string and converts it to ASCII
bytes. The old "32 bit string" wording in source errors/docs is misleading;
it is not a 32-bit cryptographic key. This document records the implementation,
not a key-rotation or deployment procedure.

User access JWTs last 15 minutes, hard-coded in `TokenHelper`
(`TOKEN_EXPIRY_MINUTES`; no environment variable). Identity maintains sessions
separately and can refresh authorization tokens. The password-reset token
lifetime is configurable through `UNITE_RESET_TTL` (minutes, default 30). A session
record and a JWT have different lifetimes and cleanup behavior.

The administrator can issue a **worker/token** JWT with a longer configured
expiry and selected permissions for external services. `unite-data-source`
uses such a token to access UNITE. Worker in this context means an authenticated
service caller, distinct from submission/indexing/analysis background workers.

Reviewed worker token claims contain actor `Worker`, token name, token key
(`Sid`), and permissions. They do not automatically contain the root role or a
human user's project memberships just because an administrator issued them.
The owner confirmed that private-project scope for these tokens is **not yet
defined**. Currently only `unite-data-source` uses the token, issuance is
administrator-only, and broader service use is not established. Keep this as
an explicit design decision for private-project work; do not assume all-data,
public-only, or assigned-project access from the current usage pattern.
Token management has expiry/revocation/active-status support. The portal checks
it: for `Worker` tokens its JWT handler asks Identity `api/token/{key}/active`
(cached for a minute) and drops the `Authorization` header of inactive tokens
before proxying, so revoked worker tokens are rejected at the portal. The
services behind it verify only the signature.

The user-claim helper emits `NameIdentifier` with the integer Identity user ID
(commit `b44712f`, 2026-08-06, on `main` and `dev`), which Composer's and
Analysis' personal criteria read. A token without it gets no project-scoped
data. Worker tokens never carry `NameIdentifier` or a role.

Identity's `GET api/users` (root only) lists all users except the caller and the
configured admin. Composer forwards the caller's token to it when listing
project users, so that listing works only for root callers.

## Sessions, inactivity, and account deletion

The owner confirmed that Identity removes expired sessions, deletes users after
an inactivity retention period, and accepts user-requested account deletion.
Deleting an account also deletes its saved datasets and analyses.

Selected implementation details:

- `AccountWorker` runs expired-session and inactive-account cleanup after a
  startup delay, then pauses 24 hours between passes.
- `UNITE_RETENTION_PERIOD` is in days (a `byte`, so at most 255) and defaults
  to 90. Non-root users whose `LastActive` predates the cutoff are selected for
  account cleanup. `LastActive` is set on creation and updated on token refresh
  (and should be on login too). An access-list entry that is not registered
  within the period is removed as well; the owner confirmed this is intended. Do not interpret this as a separate 90-day TTL for every
  analysis or dataset.
- unite-env's root `.env` sets it to `90` days and Identity's Compose passes
  it through. Until 2026-10-12 it was labeled as months and set to `3`, so
  deployments with that `.env` deleted inactive accounts after 3 days.
- `AccountService.Delete` invokes user-data cleanup before deleting the user.
  Inactive-account cleanup calls that same account-deletion method.
  Admin deletion (`DELETE api/user/{id}`) currently removes only the user row,
  leaving datasets and analyses (tracked in Jira).
- `UserDataService` removes the user's Mongo dataset/analysis records and
  corresponding SQL analysis tasks, matching record `UserId` against email.
- The portal's explicit delete-account flow first calls Composer's dataset
  delete-all endpoint and Analysis's analysis delete-all endpoint, then Identity.
  The Analysis endpoint also calls per-method file deletion.

Removing Mongo records/SQL tasks and removing analysis files are distinct
operations. Identity's own cleanup does not delete shared analysis directories,
so inactivity cleanup leaves analysis files behind. The portal path deletes
files through Analysis, except CNV-profile directories (no branch in its
cleanup). Identity also does not touch the domain database's `DataUser` and
`ProjectUser` rows, which remain after account deletion; they should be
removed too (owner, 2026-10-12; tracked in Jira). The
owner's intended behavior is complete removal of the account's datasets and
analyses.

Analysis results otherwise remain until deletion, as described in
[Analysis pipeline](analysis-pipeline.md). Account deletion/inactivity cleanup
is an additional lifecycle trigger. Idle Cell-x-Gene viewer removal is a third,
separate mechanism and does not by itself delete the analysis result.

## Code navigation and references

Reviewed locally; `main` links are navigation aids, not immutable revisions.

- [Instance options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/InstanceOptions.cs), [account controller](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Controllers/AccountController.cs), and [AccountService](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Services/AccountService.cs).
- [Default/root permissions](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Constants/Permissions.cs), [root bootstrap](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Workers/RootWorker.cs), and [admin options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/AdminOptions.cs).
- [Identity deployment script](https://github.com/dkfz-unite/unite-env/blob/main/applications/unite-identity/deploy.sh): secret-field to environment-variable mapping; inspect the relevant installation checkout.
- [JWT generation](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Helpers/TokenHelper.cs), [claims](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Helpers/ClaimsHelper.cs), [validation](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Extensions/AuthenticationExtensions.cs), and [API key option](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/ApiOptions.cs).
- [Login/refresh controller](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Controllers/IdentityController.cs), [token management](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Controllers/TokenController.cs), and [Composer claim extraction](https://github.com/dkfz-unite/unite-composer/blob/main/Unite.Composer.Web/Extensions/PersonalizationExtensions.cs).
- [LDAP identity service](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Services/LdapIdentityService.cs), [directory lookup/bind](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Services/Ldap/LdapService.cs), [LDAP options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/LdapProviderOptions.cs), and [Default options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/DefaultProviderOptions.cs).
- [Mail service](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Post/MailService.cs), [mail client](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Post/MailClient.cs), and [SMTP options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/SmtpOptions.cs).
- [Account cleanup worker](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Workers/AccountWorker.cs), [retention options](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity.Web/Configuration/Options/RetentionOptions.cs), and [session cleanup](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Services/SessionService.cs).
- [Identity saved-data cleanup](https://github.com/dkfz-unite/unite-identity/blob/main/Unite.Identity/Services/UserDataService.cs), [portal account deletion](https://github.com/dkfz-unite/unite/blob/main/Unite.Web/Client/src/identity/api/index.js), and [Analysis delete-all](https://github.com/dkfz-unite/unite-analysis/blob/main/Unite.Analysis.Web/Controllers/AnalysesController.cs).

## Remaining questions

The `unite-identity` repository was reviewed with the owner on 2026-10-12;
defects found are tracked in Jira. Worker-token private-project scope is an
acknowledged open design decision. Complete account cleanup (analysis files,
project memberships) is tracked in Jira.
