# Entra ID Application Registration — Request Guide & Intake Form

> **Page Owner:** Identity & Access Management  
> **Audience:** All staff requesting application integrations; Exchange/M365 team  
> **Last Reviewed:** {{REVIEW_DATE}}  
> **Related SNOW Catalog Item:** [Entra ID App Registration Request]({{SNOW_CATALOG_URL}})

---

## Purpose / Overview

This page explains what an Entra ID application registration is, when you need one, and how to submit a complete request so that your integration can be configured with minimal back-and-forth.

**What this team does:**
- Configures application registrations in Entra ID (our cloud identity platform)
- Sets up the trust relationship between your application and Microsoft's identity system
- Grants the permissions your application needs to reach Microsoft services

**What this team does NOT do:**
- Configure settings inside Exchange Online, Teams, SharePoint, Power BI, or other Microsoft 365 services — those are handled by the Exchange/M365 team
- Create or manage on-premises service accounts (handled by Active Directory/desktop teams)
- Configure application-side settings (your vendor or app team handles that)

If your request involves **email, mailboxes, distribution groups, calendar resources, or anything inside Exchange Online or Microsoft 365**, your request will be reviewed jointly and partially routed to the Exchange/M365 team. This is expected — see [Routing Logic](#routing-logic) below.

---

## Background: What Is an Application Registration? (Plain Language)

Think of an **application registration** as an ID badge for a piece of software.

When a system, tool, or automated process needs to connect to Microsoft services (like reading emails, posting to Teams, or pulling calendar data), it needs a way to prove who it is and what it is allowed to do. An application registration creates that identity in our organization's directory.

Once registered, your application receives:
- A **Client ID** — like a username for the application
- A **Secret or Certificate** — like a password, used to prove the app is who it says it is
- **Permissions** — a specific list of what the app is allowed to access

Without an application registration, the software has no authorized identity in our environment and cannot connect.

---

## Background: The Two Environments (Read This First)

We operate **two completely separate Entra ID tenants.** They cannot communicate with each other, and an application registered in one **will not work** in the other.

| Environment | Purpose | Domain |
|---|---|---|
| **QA** | Testing and pre-production validation | {{QA_DOMAIN}} |
| **Production** | Live business operations | {{PROD_DOMAIN}} |

**You must specify which environment you need.** If you need both, you must submit two separate requests. Do not assume that registering in QA means it will automatically exist in Production — it will not.

---

## Background: On-Premises Accounts vs. Cloud-Only Service Principals

Applications authenticate to Microsoft services in one of two ways. This matters because it changes what kind of permissions are needed and how your request is processed.

### Option A — Synchronized Service Account (Hybrid)
An Active Directory service account that has been synced from on-premises to the cloud via Entra Connect. The account already exists in AD and appears in Entra ID as a user object.

- **Use this when:** The application is hosted on-premises, the vendor explicitly requires a user-context account, or the integration needs to act as a specific named user (delegated access)
- **Key point:** The account still lives in AD. IAM manages the sync. A separate AD team may need to create the account first.

### Option B — Service Principal (Cloud-Only)
A cloud-native application identity created directly in Entra ID with no corresponding AD account. This is the most common pattern for modern integrations.

- **Use this when:** The application runs in the cloud, runs as a background service with no user interaction, or the vendor's documentation says to create an "App Registration" or "Service Principal"
- **Key point:** This is what the IAM team creates. No AD account needed.

**If you are unsure which applies:** Check your vendor's setup documentation. If it says "register an application in Azure AD / Entra ID," it is Option B.

---

## Background: Delegated Permissions vs. Application Permissions

This is one of the most common points of confusion. Here is the plain-language version:

### Delegated Permissions — "Acting as a User"
The application acts **on behalf of a signed-in user.** It can only do what that specific user is allowed to do. The user must log in for the app to work.

- **Example:** A portal that reads your own calendar when you log in
- **Requires:** A real user to authenticate each time
- **Common with:** Synchronized service accounts (Option A above)

### Application Permissions — "Acting as Itself"
The application acts **entirely on its own**, with no user logged in. It has direct access to whatever permissions it was granted, regardless of who (if anyone) is using it at the time.

- **Example:** An automated nightly process that reads all email logs across the organization
- **Requires:** Admin consent (an IAM or M365 administrator must explicitly approve)
- **Common with:** Service principals (Option B above), background services, scheduled jobs

**Why does this matter for your request?** Application permissions are broader and higher-risk. They require more scrutiny and take longer to approve. Delegated permissions are more limited. Knowing which model your application uses helps us process your request correctly and ask the right questions.

---

## Background: Microsoft 365 Services and Why They Are Different

Microsoft 365 services (Exchange Online, Teams, SharePoint, Power BI, etc.) are not just files on a server — they are complex platforms with their own access models on top of Entra ID.

**Important:** Granting an application access to Exchange email at the Entra ID layer can mean access to **every mailbox in the organization**, not just one. The same is true for SharePoint sites and Teams. This is why:

1. Requests touching M365 services are reviewed more carefully
2. The Exchange/M365 team is involved for anything touching email, calendar, Teams, or SharePoint
3. We may apply additional restrictions (mailbox-scoped policies, Sites.Selected permissions) to limit what the app can actually reach, even after the Entra registration is in place

The IAM team sets up the identity and permissions at the Entra layer. The Exchange/M365 team handles configuration within the service itself (e.g., scoping a mailbox policy, granting access to specific SharePoint sites).

---

## ServiceNow Intake Form — Field Reference

The following documents every field in the **Entra ID App Registration Request** catalog item. For each field, the purpose and help text shown to the requester are included.

---

### Section 1: Request Basics

---

**1.1 — Requested Environment**
*Field type: Single-select (required)*

| Option | Label |
|---|---|
| `qa` | QA / Pre-Production |
| `prod` | Production |
| `both` | Both Environments (creates two linked requests) |

> **Help text shown to requester:**
> Select the environment where this application needs to connect. If you are unsure, ask your vendor. If your application needs to work in both testing and live production, select "Both Environments" — this will generate two separate work items, one per environment.
>
> ⚠️ These are completely separate systems. An app registered in QA will not work in Production and vice versa.

**IAM team note:** If `both` is selected, clone the ticket on intake and process QA first. Production requires explicit re-approval.

---

**1.2 — Application / Integration Name**
*Field type: Short text (required)*

> **Help text:** Enter the name of the application, tool, or system being integrated. Use the official product name if possible (e.g., "Workday HR System", "Vendor XYZ Reporting Tool"). This is how the registration will appear in our directory.

---

**1.3 — Business Owner / Sponsor**
*Field type: People picker (required)*

> **Help text:** Who in the business is responsible for this application? This person will be listed as the owner and contacted if there are issues, security reviews, or renewal requirements. Must be a full-time employee.

---

**1.4 — Technical Contact**
*Field type: People picker (required)*

> **Help text:** Who is the technical point of contact for this integration? This may be a vendor representative, an internal developer, or your application support team. This person will receive configuration details (Client ID, redirect URIs, etc.) once the registration is set up.

---

**1.5 — Vendor-Provided Setup Documentation**
*Field type: File attachment + text field (optional but strongly recommended)*

> **Help text:** Does your vendor provide instructions for connecting to Microsoft Azure AD / Entra ID? If yes, please attach those instructions here (PDF, Word doc, link, screenshots — anything helps).
>
> Common names for this documentation include: "Azure AD Integration Guide", "SSO Setup for Microsoft", "Service Account Requirements", "OAuth2 Configuration Guide".
>
> If you have this documentation, providing it will significantly speed up your request. Without it, we will need to ask follow-up questions.

**IAM team note:** If vendor docs are provided, review them during intake to pre-identify permission requirements before the requester has to answer Section 4.

---

**1.6 — Describe What This Application Needs to Do**
*Field type: Long text (required)*

> **Help text:** In plain language, describe what this application will do and why it needs access to our Microsoft environment. Examples:
>
> - "This is a third-party HR reporting tool that needs to read employee profile data to generate org charts."
> - "This is an automated monitoring script that sends alerts to a Teams channel when a server goes down."
> - "This is our vendor's SaaS platform. When users log in, it should use our company credentials instead of a separate username and password."
>
> There are no wrong answers here — we just need to understand the use case so we can configure the right type of access.

---

### Section 2: Identity / Account Type

---

**2.1 — How Will This Application Authenticate?**
*Field type: Single-select (required)*

| Option | Label |
|---|---|
| `service_principal` | It will use a cloud application identity (most common — vendor said to create an App Registration) |
| `sync_account` | It will use an existing on-premises service account that is synchronized to the cloud |
| `user_login` | End users will log in with their own credentials (Single Sign-On / SSO) |
| `unsure` | I'm not sure — I need help figuring this out |

> **Help text:**
> - **Cloud application identity:** Choose this if your vendor said to "register an application in Azure AD" or "create a Service Principal." This is the most common option for automated integrations.
> - **Synchronized service account:** Choose this if the application was previously using an Active Directory service account and you need it to also work in the cloud.
> - **User login / SSO:** Choose this if the goal is for your employees to log into a vendor application using their company email and password, instead of a separate set of credentials.
> - **Not sure:** We will help you figure it out — just describe what the application needs in field 1.6.

**Routing note:** `user_login` responses typically indicate an Enterprise Application / SSO configuration request (SAML or OIDC), which is a separate workflow. Flag on intake.

---

**2.2 — Does This Application Run Automatically Without a User Logged In?**
*Field type: Single-select (required if 2.1 = `service_principal` or `sync_account`)*

| Option | Label |
|---|---|
| `yes` | Yes — it runs on a schedule, as a background service, or without any user interaction |
| `no` | No — it only runs when a specific person logs in or triggers it |
| `both` | Both — some functions run automatically, others are triggered by users |

> **Help text:** An example of "runs automatically" would be a nightly data export, a monitoring agent, or an integration that polls for new records every few minutes. An example of "requires user interaction" would be an app where employees log in and see their own data.
>
> This affects what type of permissions we configure.

---

### Section 3: Microsoft 365 Service Access

---

**3.1 — Does This Application Need to Access Any Microsoft 365 Services?**
*Field type: Single-select (required)*

| Option | Label |
|---|---|
| `yes` | Yes |
| `no` | No — it only needs to authenticate users or access non-M365 data |
| `unsure` | Not sure |

> **Help text:** Microsoft 365 services include: Exchange Online (email), Outlook calendar, Teams, SharePoint, OneDrive, Power BI, Viva, Planner, and other Microsoft workplace tools. If you're not sure, answer "Not sure" and describe the use case in Section 1.6.

**Routing note:** If `yes` or `unsure` is selected, Section 3.2 becomes required and the Exchange/M365 team is added as a co-assignee on the ticket.

---

**3.2 — Which Microsoft 365 Services Does This Application Need to Access?**
*Field type: Multi-select (required if 3.1 = `yes`)*

| Option | Service | Routing flag |
|---|---|---|
| `exchange_email` | Exchange Online — Send or read email | → Exchange/M365 team |
| `exchange_calendar` | Exchange Online — Calendar access | → Exchange/M365 team |
| `exchange_contacts` | Exchange Online — Contacts | → Exchange/M365 team |
| `exchange_mailbox_mgmt` | Exchange Online — Mailbox provisioning or management | → Exchange/M365 team (primary) |
| `teams_messaging` | Microsoft Teams — Post messages or read conversations | → Exchange/M365 team |
| `teams_calls` | Microsoft Teams — Calling or meeting data | → Exchange/M365 team |
| `sharepoint` | SharePoint Online — Read or write site content | → Exchange/M365 team |
| `onedrive` | OneDrive — Read or write files | → Exchange/M365 team |
| `power_bi` | Power BI — Read reports or push data | → Exchange/M365 team |
| `user_profile` | User profile / directory data (name, email, department) | IAM team |
| `group_membership` | Microsoft 365 group membership | IAM team |
| `other_m365` | Other Microsoft 365 service — describe in notes | Review on intake |

> **Help text:** Check everything that applies. If you are not sure what service you need, describe what the application is trying to do in the notes field and we will determine the right permissions.

---

**3.3 — What Level of Access Does This Application Need to the Selected Services?**
*Field type: Multi-select (required if 3.1 = `yes`)*

| Option | Label |
|---|---|
| `read_own` | Read only — limited to the data belonging to the user who logged in |
| `read_all` | Read only — all records across the organization (e.g., all mailboxes, all files) |
| `write_own` | Write/modify — limited to the logged-in user's own data |
| `write_all` | Write/modify — all records across the organization |
| `send_mail` | Send email on behalf of a mailbox |
| `admin` | Administrative functions (create/delete users, manage groups, manage service settings) |
| `unsure` | I'm not sure — see description in 1.6 |

> **Help text:** Select everything your application needs to do.
>
> ⚠️ "All records across the organization" means the application can access **every** mailbox, file, or calendar in the company — not just yours. Only select this if your vendor explicitly requires it. We will verify before approving.

---

**3.4 — Additional Notes on Data Access Scope**
*Field type: Long text (optional)*

> **Help text:** If you know which specific mailboxes, SharePoint sites, or Teams channels this application needs to access, list them here. Limiting access to specific resources is more secure and faster to approve than organization-wide access.
>
> Example: "This app only needs to read the shared mailbox: reports@{{DOMAIN}}"
> Example: "This app only needs access to the SharePoint site: Finance Reports (https://{{DOMAIN}}/sites/financereports)"

**IAM team note:** If specific resources are named here, flag for Exchange team to configure Application Access Policy (mailbox scoping) or Sites.Selected (SharePoint scoping) after the registration is created.

---

### Section 4: Authentication Configuration

---

**4.1 — Does This Application Have a Redirect URI / Callback URL?**
*Field type: Single-select + text (conditional on 2.1 = `user_login`)*

| Option |
|---|
| Yes — I have the redirect URI(s) |
| No / Not applicable |
| I don't know what this is |

> **Help text:** A redirect URI is the web address that Microsoft sends users back to after they log in. Your vendor will provide this — it usually looks like `https://yourapp.vendor.com/auth/callback` or similar. If your vendor gave you a setup checklist, the redirect URI is often listed there.

*If yes, text field:* **Redirect URI(s)** — one per line

---

**4.2 — What Type of Credential Will This Application Use?**
*Field type: Single-select (required if 2.1 = `service_principal`)*

| Option | Label |
|---|---|
| `secret` | Client Secret (password-style credential — easier to set up, expires periodically) |
| `certificate` | Certificate (more secure — your application team must manage the certificate) |
| `managed_identity` | Managed Identity (Azure-hosted workloads only — most secure, no credential management) |
| `unsure` | I'm not sure — my vendor will tell me |

> **Help text:** This is the "password" your application uses to prove its identity to Microsoft. Your vendor's documentation will specify which type they require. If unsure, select "Not sure" — we will confirm with you before proceeding.
>
> ⚠️ Client secrets expire. If you choose a secret, your team will be responsible for renewing it before it expires (typically every 12–24 months) or your integration will stop working.

---

**4.3 — What Accounts Should Be Able to Log In to This Application?**
*Field type: Single-select (required if 2.1 = `user_login`)*

| Option | Label |
|---|---|
| `org_only` | Only accounts from our organization (employees / staff) |
| `multi_tenant` | Accounts from any organization (vendor portal used by multiple companies) |
| `personal_ok` | Personal Microsoft accounts also allowed |
| `unsure` | Not sure |

> **Help text:** In most cases, you want "Only accounts from our organization." If this is a vendor-hosted portal that multiple companies use, select the multi-tenant option. Personal Microsoft accounts (Outlook.com, Xbox, etc.) are almost never appropriate for business integrations.

---

### Section 5: Risk and Compliance Context

---

**5.1 — Does This Application Access Sensitive or Regulated Data?**
*Field type: Multi-select (required)*

| Option |
|---|
| Personal Identifiable Information (PII) — names, SSNs, addresses, etc. |
| Financial data — account numbers, transaction records, etc. |
| Health / medical information |
| Confidential business information |
| None of the above |
| I'm not sure |

> **Help text:** This helps us determine the appropriate level of review. Selecting sensitive data categories does not mean your request will be denied — it means additional care will be taken in how permissions are scoped.

---

**5.2 — Is This Application Managed by a Third-Party Vendor?**
*Field type: Single-select (required)*

| Option |
|---|
| Yes — it is a vendor-provided SaaS application |
| Yes — it is a vendor-managed on-premises application |
| No — it is developed and managed internally |
| Mixed — vendor platform with internal customizations |

---

**5.3 — Has a Security / Risk Assessment Been Completed for This Application?**
*Field type: Single-select (required)*

| Option |
|---|
| Yes — reference number: [text field] |
| In progress |
| Not yet — this request may initiate one |
| Not required (explain in notes) |

> **Help text:** Many applications that access sensitive data require a vendor risk assessment or information security review before they can be integrated into our environment. If you are unsure whether this applies, your manager or the Information Security team can advise.

---

**5.4 — Expected Integration Lifetime**
*Field type: Single-select (required)*

| Option |
|---|
| Permanent (ongoing production integration) |
| Project-based — estimated end date: [date picker] |
| Proof of concept / temporary (90 days or less) |

> **Help text:** Temporary and PoC registrations will be configured with expiring credentials and reviewed at the stated end date. Selecting "permanent" does not prevent future decommissioning — it just means we will not automatically schedule a review.

---

### Section 6: Supplemental Notes

---

**6.1 — Anything Else We Should Know?**
*Field type: Long text (optional)*

> **Help text:** Use this field for anything that didn't fit elsewhere — vendor support case numbers, escalation context, related change requests, known constraints, or timeline requirements.

---

## Routing Logic

The following table defines how submitted requests are assigned based on the answers provided.

| Condition | Routing Action |
|---|---|
| 2.1 = `user_login` | Flag as potential SSO/SAML request — may be separate catalog item |
| 3.1 = `yes` or `unsure` AND any `exchange_*` or `teams_*` selected in 3.2 | Add Exchange/M365 team as co-assignee; IAM team remains primary for Entra work |
| 3.2 includes `exchange_mailbox_mgmt` | Exchange/M365 team becomes primary assignee; IAM is reviewer only |
| 3.3 includes `read_all`, `write_all`, or `admin` | Requires IAM lead review before processing; flag as elevated-privilege request |
| 5.1 includes any sensitive data category | Route to Information Security for awareness (informational copy, not blocking) |
| 1.3 target tenant = `prod` AND 1.2 target tenant was previously `qa` | Require QA validation evidence before creating production registration |

---

## How the Exchange/M365 Team Handoff Works

When your request involves Microsoft 365 services, two teams work on it:

| Step | Team | What Happens |
|---|---|---|
| 1 | IAM | Creates the application registration in Entra ID, assigns the appropriate API permissions |
| 2 | Exchange/M365 | Configures access within the M365 service itself (scoping mailbox policies, granting site access, etc.) |
| 3 | IAM | Provides Client ID and any required configuration values to the technical contact |
| 4 | Exchange/M365 | Provides service-specific configuration values to the technical contact |
| 5 | Requester | Provides both sets of values to the vendor/application team to complete setup |

Neither team can complete the configuration without the other. Expect that M365-touching requests will involve both teams and may take additional time.

---

## Exchange/M365 Team — Recommended Entra ID Role Assignment

> **This section is for IAM team internal reference only and is not visible to end users.**

The Exchange/M365 team has requested the ability to create and manage application registrations in Entra ID for integrations that connect exclusively to Exchange Online and M365 services, without requiring IAM involvement for every request.

### What They Need to Do

- Create new app registrations in Entra ID
- Configure API permissions scoped to Exchange Online, Teams, SharePoint, and other M365 services
- Grant admin consent for those permissions
- Manage credentials (secrets/certificates) on those registrations

### What They Must NOT Be Able to Do

- Create app registrations or grant permissions to non-M365 resources (Azure subscriptions, custom APIs, third-party services)
- Modify user objects, group membership, or directory settings
- Assign Entra ID roles to users or service principals
- Access or modify any registrations they did not create (unless assigned as owner)

### Role Recommendation

**Do not assign Global Administrator.** It is not needed and creates significant risk.

The closest built-in role is **Cloud Application Administrator**, which allows full management of app registrations and enterprise apps and can grant admin consent for delegated and application permissions — with one important limitation:

> ⚠️ **Built-in limitation:** Cloud Application Administrator and Application Administrator both **cannot grant admin consent for Microsoft Graph application permissions**. Microsoft Graph is the primary API surface for M365 services. This means the Exchange team would be blocked from consenting to permissions like `Mail.Read`, `Calendars.ReadWrite`, or `Sites.ReadWrite.All` on their own — those still require a Privileged Role Administrator or Global Admin to consent.

This is actually a useful security control for your environment, but it does mean IAM retains an approval role in the process even with delegation. Evaluate whether this is acceptable.

**Recommended approach — layered delegation:**

| Role | Scope | Rationale |
|---|---|---|
| `Cloud Application Administrator` | Tenant-wide | Allows creating registrations and managing all aspects except Graph consent |
| IAM team remains approver | Graph application permissions only | Exchange team submits; IAM consents after review |

**Alternative — custom role (requires Entra ID P1):**

If tighter scope is needed, a custom role can be created that grants only:
- `microsoft.directory/applications/create` — create new registrations
- `microsoft.directory/applications/credentials/update` — manage secrets/certs
- `microsoft.directory/applications/permissions/update` — update permission requirements
- `microsoft.directory/servicePrincipals/create` — create the corresponding service principal
- `microsoft.directory/oAuth2PermissionGrants/create` — grant delegated permissions

**Key constraint:** Custom roles cannot be scoped to "only M365 API permissions." The technical enforcement of M365-only is an operational/process control, not a native Entra feature. You cannot create a role that prevents someone from adding Graph permissions to non-M365 resources — that boundary is enforced through your review process (IAM as reviewer on every Exchange-team-created registration) rather than through the role itself.

### Recommended Operating Model

1. Exchange team creates registrations using their delegated role
2. Exchange team submits a SNOW request for IAM to grant admin consent on Graph permissions
3. IAM reviews the permission set, confirms it is M365-scoped and least-privilege, grants consent
4. IAM is listed as an automatic Watcher on any app registration the Exchange team creates (enforced via Entra audit alerts)
5. Quarterly review: IAM audits all registrations owned by the Exchange team for scope creep

This keeps the Exchange team unblocked for 90% of their work while retaining IAM oversight on the highest-risk action (Graph consent).

---

## References

| Resource | URL |
|---|---|
| Microsoft Learn — App registration overview | https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app |
| Microsoft Learn — Permissions and consent overview | https://learn.microsoft.com/en-us/entra/identity-platform/permissions-consent-overview |
| Microsoft Learn — Delegated vs application permissions | https://learn.microsoft.com/en-us/troubleshoot/entra/entra-id/app-integration/application-delegated-permission-access-tokens-identity-platform |
| Microsoft Learn — Custom role permissions for app registrations | https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/custom-available-permissions |
| Microsoft Learn — Delegate app registration permissions | https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/delegate-app-roles |
| Microsoft Learn — Exchange RBAC for Applications | https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac |
| Microsoft Learn — Graph permissions reference | https://learn.microsoft.com/en-us/graph/permissions-reference |
| Microsoft Learn — Sites.Selected for SharePoint | https://learn.microsoft.com/en-us/graph/permissions-selected-overview |
| Internal — Entra Connect Sync documentation | {{CONFLUENCE_ENTRA_CONNECT_PAGE}} |
