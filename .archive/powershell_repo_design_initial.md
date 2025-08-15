### Overview

## Purpose
The intent of this repo is to hold all scripting used connect to three cloud platforms in order to get all IAM resource data, attributes, memberships, use, policy, and metadata. The cloud platforms are AWS, Azure/EntraID, and GCP

This data is used to populate an inventory of cloud access in order to generete audit evidencing reports, make access descisions, map access to cloud services and resources, and identify areas of improvement. 

Cloud access needs to follow NIST, CSA Star, and FFIEC CAT frameworks so this data will also be used to evaluate how the IAM resources deployed to the platforms follow the best practices of these frameworks. In addition to that we are following all well archtected frameworks of the cloud platforms themselves to ensure even more security is being followed as we move to the ideals of least privileged access, just in time access evelvation, single sign on federation, and regular access lifecycle management with certification of access.

To meet this we need to ensure all access follows strict metadata requirements which this repo is intended to evaluate.

### Tech Stack
## Cloud Platforms
# AWS
- Control Plane (Web Console)
AWS platform follows application specific design with each AWS account representing a single application or a specific function supporting multiple applications hosted within the cloud platform. Each application/fucntion has multiple AWS accounts tied to it. Often there is a dev, qa, uat, and prod account meaning 4 per application/function hosted in AWS. There is a master AWS Account with all other accounts reporting into the master as part of the OU structure of AWS organizations. This means IAM is largely siloed within each account with some being deployed across everything like team focused IAM roles, or tooling that needs visiability into every account via IAM Users and access keys. Users assume roles to log into AWS portal via AD groups which are fed to a federation IDP and mapped to the corrusponding AWS role to assume. Identify center is not used at this time but is being evaluated. User access is only through federation and no IAM users are granted password credentials meaning IAM Users are only build to support service account functions. By default Users only have read access to the platform and rarely are granted write or admin access outside of core IT roles. IAM resources are deployed through Terraform via IaC with a 2 approval code review system in place where IAM and security evaluates manually through code review to ensure security standards and best practicies. Developers submit PRs against a core-IAM repository holding all IAM code.

- Data Plane (Cloud Services (Example Redshift))
For some deployed services such as databases and others which have IAM within the service abstracted from the control plane roles are built at the control plane to support IAM access within the data plane. This means that some roles are built within the console but do not grant console access, skiping past that to grant access directly within the service itself. An example of this is roles built out within databases users will assume the role when signing in directly to the Database and access to tables + data must be explicity granted within the database itself. This means that there is little visiability or access control monitoring within the services and essentially relies on the service administrators of IT to proove that access is following our strict standards.

# Azure/EntraID
- Control Plane
We have 3 distinct tenants for Azure/EntraID.
- 1 Production tenant supporting the modern organization
- 1 Production tenant supporting the legacy organization (organization was aquired and tenant exists until it can be merged into modern organization)
- 1 QA tenant used for testing and proof of concept SDLC processes before they move on to the production implementations
These are all largely greenfield implementations with a lot of legacy and unmanaged design technical debt to unwrap and build resolutions for. There is very little on the Azure side built out but a new Azure implementation is currently in flight to build out a new landing zone which consists of a tenant root management group / at least 2 subscriptions under that tenant root (prod & non-prod) / and various resource groups/ resources within those subscriptions. Entra ID is the source of most IAM acess for the Azure access and also plays a part in building access to M365 via application registrations / service principals. For azure access is assigned by taking on-prem AD groups synced to Entra ID via Entra Connect and applying them to the roles within access control scopes. Users get membership to the groups to get their Azure access in place. Sailpoint managed the AD group connection and access to Entra roles so certification and metadata is stored within Sailpoint as the source of record. All access to Azure/EntraID is built manually in the console at this time with plans to move towards a IaC delivery model via Hashicorp Cloud Platform

# GCP
- Control Plane
GCP has only one use case which is to support 1 on-prem appllication which was aquired by google who forced the need to implement GCP so application support tickets could be submitted. This means there is very little access use of the platform and likely will never grow but we need to monitor the activity to ensure nothing is ever added, modified, or changed without following the processes of SDLC.

## On-Prem Tools
- Terraform | Hosted on prem and managed by the IT Cloud Operations team.
- GitLab | The current repo implementation used to store terraform code, manage CI/CD pipelines, and trigger terraform deployments.
- SailPoint | The IDQ governance tool for all access in the organization. SailPoint has no visability via connectors or other products to cloud access at this time. User access to cloud is all through AD groups across each platform which Sailpoint manages. Service access is all cloud native (IAM Users, ServicePrincipals, etc) and Sailpoint has no control or visiability on them
- Okta | Federation tool for Azure/EntraID + GCP Will be the default source of federation for AWS after a future migration
- PING Federate | Legacy current federation tool for managing SAML access to AWS. This will eventually be replaced by Okta
- Active Directory | On-Prem standard directory implementation, managed by Sailpoint which is the front door
- CyberArk | On-Prem PSM vault that holds all account credentials including user secondary accounts

### Repo Design
This repo struture is intended to be a central version control of all cloud scripting used to pull IAM data. The scripting language that will be used is PowerShell. Directory structure will be as follows:

## Key Directories

* **`Modules`**: Contains custom PowerShell modules. Each module should reside in its own subdirectory. This is for reusable, shareable code.
* **`Scripts`**: Holds standalone scripts that perform specific tasks. These aren't designed to be modules.
* **`Docs`**: A dedicated folder for detailed documentation, like architecture diagrams or in-depth guides.
* **`Tests`**: Stores **Pester** tests to validate that your scripts and modules work as expected, preventing regressions.
* **`Examples`**: Provides examples showing how to use the repo's scripts and modules.
* **`.gitlab`**: Used for CI/CD configuration files to automate testing and publishing.

***

## Documentation Files

* **`README.md`**: The primary entry point for the repo. It explains the project's purpose, how to get started, and provides a quick overview.
* **`CHANGELOG.md`**: Documents all changes, including new features, bug fixes, and breaking changes, to help users track updates.
* **`.gitignore`**: Specifies which files and directories Git should ignore, like temporary files or binaries, to keep the repo clean.

### Scripting Requirements
Below you will find all the required conventions that need to be followed to ensure strong documentation and maintaince:

- All scripts must follow a verb-noun naming convention per Microsoft's design
- Scripts must include detailed comments to ensure strong understanding persiting between developers. Comments should follow best practices per microsoft's standards and version numbering to track changed. Scripts should also include inline comments to show what each block is doing
- Modules (.psm1) must always have a manifest file (.psd1)
- README.md file must always be updated when new changes are introduced to ensure an accurate index of the repo
- CHANGLOG.md must always be updated with each major version introduced
- Scripts should include test cases to ensure they are functioning correctly and assist with debugging
- All scripts must include error handling on runs that builds logs via a central logging module
- Never repeat writing functions. Functions which are used in multiple scripts should be moved to a module.
- Modules/scripts should be split by subdirectories to show what the modules/scripts serves (example: utility directory for ultitily modules, application directories for application modules, etc)
- Scripting and modules needs to ensure there are checks for missing modules requires for the run that also installs what is required scoped to the current user and not the client
- All scripts should include progress bars for loops, writes to the terminal to show user what is running, and color coding for terminal writes to make the messages visually stand out
- Powershell modules should be installed to one central location that can be migrated if the user ever changes clients.
- CONTRIBUTING.md must always be updated with each change that affects how users can add to the repo following the requirements laid out here
- Process documentaton must accompany each new script explaining what the script does, what it is used for, a detailed step by step guide on running it that a non-technical user can follow to completion.
- Scriptings should always have an example output defined to show the user what it should look like and validate success or failures that errors cannot show.
- All documentation must be written in markdown format for easy transfers to other documentation programs like confluence and MS word
- Visual workflow diagrams should accompany process flows to provide a visual explination at a high level of what is occuring. (format can be visio or draw.io) 

### MVP Design
Starting out we need to build scripting that targets scripting for Azure/Entra ID first before building AWS and GCP scripting. We need scripts the solves the following needs:

## General
- Scripting than handles updating of PowerShell module paths to environment variables ensuring that users can migrate to new clients as needed without have to fiddle with the module install paths


## Azure
- Getting all scope information including all properties (Management groups, subscriptions, and resource groups). Resources are not needed at this time
- Getting all roles available in each scope's access control (built in and Custom roles) including all properties of each object
- Getting all memberships mapped to each role in each scope (groups and direct assignments) including all properties of each object
- Getting all role policy permissions for each role including all properties of each object

## Entra
- Getting all role information including all properties of each object. We also need to know which roles are labeled privileged using microsoft privileged labling (this is in preview at this time)
- Getting all group information including all properties of each object
- Getting all application registrations and their mapped service principals including all properties of each object
- Getting all service principals the do not mapp to a registered application including all properties of each object
- Getting all service principals access policy and API connections including all properties of each object
- Getting all user role memberships with all properties of each object that also shows roles which have no memberships with a column that indicates this
- Getting all user group memberships to non-syncronized groups (meaning only exist in Entra and not synced via Entra Connect) including all properties of each object

## Modules
- Logging module to handle all run information and error tracking
- Export module that handles all data exports to Excel .xlsx files
- Module to support connecting to the Azure/EntraID tenants and storing repeatable functions that will be used across all specific scripting. Connection authentication function should support being able to input and store tenant ID's and prompting the user to choose which to log into. It should also check for active session and prompt the user if they want to keep the active session or reconnect. Finally the connection would ideally be able to bypass the need to login via the browser as some tenants will require the user to open a incognito session in order to bypass the clients stored credentials as the divices are not hardware joined to both tenants.

## Required Modules from PSGallary
- ImportExcel | Used to create xlsx files rather than csv
- Microsoft.Grape Modules | Scoped to the specific submodule being used instead of installing the entire Microsoft.Graph PS module suite
- Az | Scoped to the specific submodule being used instead of installing the entire AZ PS module suite
