Here are the concrete vendor docs that back up each critical part of the design we discussed (SailPoint as SoR, Entra cloud-first groups, Cloud Sync writeback to AD, multi-tenant scale).

I’ll map **claim → supporting source(s)** so you can show this to architects and auditors.

---

## 1. SailPoint can fully manage Microsoft Entra ID groups (including Microsoft 365 groups)

**Claim:** SailPoint can be the authoritative lifecycle engine for Entra groups (security + Microsoft 365), using its Entra ID connector.

**Evidence:**

* SailPoint’s “Integrating SailPoint with Microsoft Entra ID” guide explicitly states that the **Microsoft Entra ID connector manages users and groups** and uses Microsoft Graph APIs to manage users, groups, and licenses. ([SailPoint Documentation][1])

* The “Account – Group Management” page for the Azure Active Directory (now Entra ID) connector shows that the connector **supports managing Microsoft 365 groups, security groups, mail-enabled security groups, and distribution lists as entitlements and as separate group objects**. ([SailPoint Documentation][2])

Together these show that SailPoint can create, modify, and deprovision Entra security groups and Microsoft 365 groups, and treat them as entitlements in its governance model.

---

## 2. SailPoint can fully manage on-premises Active Directory groups across domains/forests

**Claim:** SailPoint can be SoR for on-premises Active Directory groups (including multi-domain / multi-forest).

**Evidence:**

* “Integrating SailPoint with Active Directory” states that the **SailPoint Active Directory connector offers complete management of your Active Directory infrastructure, which can be distributed across multiple domains/multiple forests**, and explicitly lists **groups** (alongside users, contacts, Exchange mail objects, etc.) as managed objects. ([SailPoint Documentation][3])

This backs the idea that SailPoint can govern group lifecycles in all AD forests you integrate, not just a single domain.

---

## 3. Microsoft supports making Entra ID the source of authority for groups (cloud-first) and still projecting them to AD

**Claim:** You can convert on-premises groups to be **cloud-managed in Entra ID** (Group SOA), then write them back to AD, or create new cloud groups and provision them down – enabling a cloud-first governance model that still supports legacy AD apps.

**Evidence:**

* The **“Embrace cloud-first posture: Convert Group Source of Authority to the cloud”** article describes Group SOA as a feature that **converts the source of authority of AD DS groups to Microsoft Entra ID**, allowing you to manage them directly in the cloud. It explicitly says you can either:

  * Convert existing on-prem groups and **provision them back to AD DS**, or
  * Create new cloud security groups in Entra ID and **provision them to AD DS as Universal groups**, potentially nesting them under existing AD groups. ([Microsoft Learn][4])

* The same article states that after Group SOA conversion, **Microsoft Entra Connect Sync stops synchronizing the object from AD DS**, and you can “perform all operations available for a cloud group” (edit, delete, change membership) in Entra ID. ([Microsoft Learn][4])

This is exactly the pattern we’re using: treat Entra as the operational home for the group while keeping a copy in AD for legacy access.

---

## 4. Microsoft Entra Cloud Sync can write back cloud (or SOA-converted) security groups to AD DS for governance

**Claim:** Entra Cloud Sync can provision cloud-native or SOA-converted Entra security groups back into AD DS, so those groups can be used for Kerberos/LDAP apps while being governed in the cloud.

**Evidence:**

* “Group writeback with Microsoft Entra Cloud Sync” states that **cloud sync can provision groups directly to your on-premises Active Directory environment** and that you can then **use identity governance features to govern access to AD-based applications**, e.g., by including the group in an entitlement management access package. ([Microsoft Learn][5])

* The same article makes it explicit that **only cloud-native or SOA-converted security groups are supported** for provisioning back to AD DS, and that these groups are written back as **Universal groups**. ([Microsoft Learn][5])

* The article also references the scenario **“Govern on-premises Active Directory based apps (Kerberos) using Microsoft Entra ID Governance”**, where AD applications use groups that are provisioned from and managed in the cloud, while Entra ID Governance handles access reviews and lifecycle. ([Microsoft Learn][5])

This is the Microsoft-blessed pattern for “cloud-governed, AD-consumed” groups.

---

## 5. Group writeback v2 in Entra Connect is deprecated; Cloud Sync is the current best practice

**Claim:** The older Group Writeback v2 approach in Azure AD / Entra Connect is deprecated, and Microsoft recommends Cloud Sync for security group writeback. Group writeback V1 remains for Microsoft 365 groups only.

**Evidence:**

* “Group writeback for Microsoft 365 groups” explicitly states that **Group Writeback v2 in Microsoft Entra Connect Sync is deprecated and no longer supported**, and that you should **use Microsoft Entra Cloud Sync to provision cloud security groups to AD DS**. It also notes that Group writeback V1 is still supported for Microsoft 365 groups and is being replaced by Cloud Sync group provisioning to AD. ([Microsoft Learn][6])

This supports our decision to use **Cloud Sync for security groups** and reserve **Connect group writeback V1 just for Microsoft 365 groups** where needed.

---

## 6. Microsoft Entra group best practices support cloud-first, governed groups

**Claim:** Microsoft recommends a cloud-first, governance-heavy approach to group management (dynamic membership, access reviews, access packages), which aligns with making Entra the operational home of your groups.

**Evidence:**

* “Learn about groups, group membership, and access” describes Entra security and Microsoft 365 groups and lists **“Best practices for managing groups in the cloud”**, including:

  * Dynamic membership for automation,
  * Periodic access reviews via Entra Identity Governance,
  * Access packages to manage multiple group memberships,
  * Group-based licensing,
  * Multiple group owners, and RBAC controls. ([Microsoft Learn][7])

* The Group SOA article itself reiterates that **you can continue to create new groups directly in the cloud** and govern them through Microsoft Entra ID Governance. ([Microsoft Learn][8])

This underpins the design of treating Entra groups as the main control surface and letting SailPoint orchestrate membership into them.

---

## 7. Multi-tenant model and future acquisitions: Microsoft-native patterns

**Claim:** Microsoft provides a native way to group and coordinate multiple Entra tenants owned by one organization and to synchronize identities across them, which we can pair with SailPoint’s multi-connector capabilities.

**Evidence:**

* “What is a multitenant organization in Microsoft Entra ID?” explains that the **multitenant organization capability lets you define a boundary around the Entra tenants your organization owns**, with cross-tenant access and cross-tenant identity synchronization as core concepts. It highlights that tenants in an MTO are “a collaboration of equals,” each with its own cross-tenant access settings and synchronization policies. ([Microsoft Learn][9])

* “Multitenant organization identity provisioning for Microsoft 365” describes how **each tenant contributes and synchronizes users outbound and accepts shared users inbound**, using either Microsoft 365 synchronization or cross-tenant synchronization. ([Microsoft Learn][10])

In parallel, SailPoint’s Active Directory connector and Entra ID connector both explicitly support **multiple domains and multiple forests** or tenants, giving you a unified governance layer across many back-ends. ([SailPoint Documentation][3])

Together, this shows that your future “many tenants / many forests” world can be handled by:

* Microsoft for **identity plumbing and cross-tenant sync**, and
* SailPoint for **centralized entitlement governance**.

---

## 8. SailPoint can participate in Entra ID Governance / Cloud Governance scenarios

**Claim:** SailPoint can understand and manage Entra Governance-related constructs (licenses, some cloud governance attributes) where licensed.

**Evidence:**

* The Entra ID connector’s **Service Plan Management** page states that the connector supports **assigning different Azure service licenses** and models `assignedPlans` or `assignedLicenses` as entitlements that can be requested and managed via SailPoint. ([SailPoint Documentation][11])

* “Group Attributes for Azure Cloud Objects” notes that to manage certain **Azure Management Objects** for Cloud Governance (Management Groups, Subscriptions, Resource Groups, Azure Role Assignments) via the Entra connector, **you must purchase a SailPoint CIEM license**. This ties SailPoint’s connector directly into Microsoft’s cloud governance constructs. ([SailPoint Documentation][12])

This backs the statement that SailPoint can sit above Entra Governance as a central SoR and entitlement broker where you choose to license that capability.

---

## 9. Summary: How these sources together “prove” the pattern

Putting it all together:

1. **SailPoint connectors**

   * Entra ID connector manages **users, groups, and licenses** in the Entra tenant (including Microsoft 365 groups). ([SailPoint Documentation][1])
   * Active Directory connector manages **users and groups across multiple domains/forests**. ([SailPoint Documentation][3])

2. **Microsoft cloud-first group model**

   * Group SOA allows you to **convert AD groups to be cloud-managed in Entra** and either provision them back to AD or replace them with new cloud groups provisioned to AD. ([Microsoft Learn][4])

3. **Writeback mechanism**

   * Entra Cloud Sync **provisions cloud or SOA-converted security groups to AD DS**, with support for Entra ID Governance scenarios for on-premises apps. ([Microsoft Learn][5])
   * Group Writeback v2 is **deprecated**; Cloud Sync is the recommended mechanism for security groups; group writeback V1 remains for Microsoft 365 groups. ([Microsoft Learn][6])

4. **Best-practice governance**

   * Entra’s own guidance promotes dynamic groups, access reviews, and access packages for group governance – exactly what you get when you treat Entra as the operational surface and let SailPoint orchestrate memberships. ([Microsoft Learn][7])

5. **Multi-tenant future**

   * Microsoft defines a first-class **multitenant organization** capability with cross-tenant sync; SailPoint connectors support multiple domains/forests/tenants, giving you a credible model for future acquisitions. ([Microsoft Learn][9])

None of this is a “pattern from a blog”; it is all **directly described or implied by Microsoft Learn and SailPoint’s official connector documentation**. The architecture we outlined is essentially:

* **SailPoint** = master of “who should be in what group” across Entra and AD.
* **Entra** = operational owner of cloud security / M365 groups and the governance platform.
* **Cloud Sync (and limited Connect writeback)** = plumbing to ensure those cloud-managed groups are present in AD where needed.

If you want, next step I can turn this into a short, audit-ready “Evidence Pack” you can attach to a design document or RFC (just the key excerpts, each tied to a requirement).

[1]: https://documentation.sailpoint.com/connectors/microsoft/entra_id/help/integrating_entra_id/introduction.html "Integrating SailPoint with Microsoft Entra ID"
[2]: https://documentation.sailpoint.com/connectors/microsoft/azure_ad/help/integrating_azure_active_directory/account_group_management.html "Account - Group Management"
[3]: https://documentation.sailpoint.com/connectors/active_directory/help/integrating_active_directory/intro.html "Integrating SailPoint with Active Directory"
[4]: https://learn.microsoft.com/en-us/entra/identity/hybrid/concept-source-of-authority-overview "Embrace cloud-first posture and convert Group Source of Authority (SOA) to the cloud - Microsoft Entra ID | Microsoft Learn"
[5]: https://learn.microsoft.com/en-us/entra/identity/hybrid/group-writeback-cloud-sync "Group writeback with Microsoft Entra Cloud Sync - Microsoft Entra ID | Microsoft Learn"
[6]: https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-group-writeback-enable "Group Writeback for Microsoft 365 Groups - Microsoft Entra ID | Microsoft Learn"
[7]: https://learn.microsoft.com/en-us/entra/fundamentals/concept-learn-about-groups "Learn about groups, group membership, and access"
[8]: https://learn.microsoft.com/en-us/entra/identity/hybrid/concept-source-of-authority-overview "Convert Group Source of Authority to the cloud"
[9]: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-overview "What is a multitenant organization in Microsoft Entra ID? - Microsoft Entra ID | Microsoft Learn"
[10]: https://learn.microsoft.com/en-us/entra/identity/multi-tenant-organizations/multi-tenant-organization-microsoft-365 "Multitenant organization identity provisioning for Microsoft 365 - Microsoft Entra ID | Microsoft Learn"
[11]: https://documentation.sailpoint.com/connectors/microsoft/entra_id/help/integrating_entra_id/managing_licenses.html "Service Plan Management (Managing Licenses)"
[12]: https://documentation.sailpoint.com/connectors/microsoft/entra_id/help/integrating_entra_id/cam_enabled_schema_attribute_objects.html "Group Attributes for Azure Cloud Objects"
