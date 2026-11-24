This is the scope document of the project: 



Custom Property Management

Software - BRD & FRD

Project Overview

Creative Property Management is seeking a custom-built, full-stack web & mobile

application to streamline its property management operations. The platform will

consolidate residential and commercial management into a single system, providing

enhanced digital workflows over existing industry tools such as Building Stack and Yardi.

The goal is to digitize operations, increase tenant satisfaction, and provide an efficient

interface for all stakeholders including admins, property managers, tenants, and owners.

Business Requirements Document (BRD)

Business Objectives

- Automate lease lifecycle and rent collection.

- Centralize communication and service requests.

- Provide transparent access to owners and tenants.

- Reduce manual work and administrative overhead.

- Support scalability for future property expansion.

Stakeholders

- Sponsor: Creative Property Management – Provides overall vision and funding.

- Admin Users: Internal administrative team – Full access to manage system.

- Property Managers: Manage assigned properties and tenants.

- Tenants: Interact via the tenant portal.

- Owners: Monitor property performance and view financial reports.



canvas



Key Business Requirements

- Central dashboard for property lifecycle management.

- Admin portal with role-based access.

- Automated rent collection and reminder notifications.

- Lease tracking and e-signature capabilities.

- Maintenance request system with tracking.

- Financial tools integrated with third-party accounting platforms.

Success Criteria

- 90% reduction in manual paperwork and emails.

- Secure handling of payments and documents.

- Improved communication and ticket resolution time.

- Increased tenant and owner satisfaction.

Functional Requirements Document (FRD)

User Roles and Permissions

- Admin: Full control of system including properties, users, and settings.

- Property Manager: Manages assigned properties and related operations.

- Tenant: Access to their unit details, payments, maintenance requests.

- Owner: View-only access to owned property reports and financials.

Core Modules and Functionalities

Property Listings Management

Property Listings Management module allows the admin and property managers to add,

edit, and manage multiple types of properties such as apartments, commercial offices, or

retail spaces. Each property can have multiple units (e.g., different apartments or offices

within the building). Detailed information for each property and unit includes:



canvas



• Property name and type (residential/commercial)

• Exact location and address

• High-quality images and floor plans

• Amenities and facilities available (e.g., parking, gym, security)

• Unit-specific data like size, number of bedrooms/bathrooms, availability status,

and rental rates

This system ensures that listings shown to tenants and owners are accurate, up-to-date,

and comprehensive.

Tenant Management

• When a new tenant rents a unit, the property manager creates a detailed tenant

profile with contact information, emergency contacts, and identification

documents.

• The tenant is assigned to a particular unit with associated lease details such as

start and end dates, rent amount, and special conditions.

• Throughout the tenancy, the property manager tracks payments, late fees, and any

maintenance requests logged by the tenant.

• Tenant activity logs keep a record of all interactions such as payment

submissions, complaints, document downloads, or communication history, which

can be referenced if needed.

.

Online Rental Application

• A prospective tenant visits the property management website or app and selects a

property/unit they wish to apply for.

• They fill out an online application form with personal details, employment

information, rental history, and upload required documents such as ID proof, pay

stubs, or references.

• Admin receives notification of the new application, reviews the details, runs

background and credit checks if integrated, and approves or rejects the

application.

• The applicant receives status updates throughout the process and can upload

additional documents if requested.

• Upon approval, the system automatically moves the applicant to tenant status and

prompts them to complete digital lease signing.



canvas



Lease Management

• After tenant approval, property managers generate a digital lease agreement

tailored to the specific unit and terms.

• The lease document is sent to tenants via the tenant portal or email for electronic

signature.

• The system tracks the signing status and stores signed copies securely.

• Lease expiration dates are monitored; automated reminders notify tenants and

managers ahead of renewals.

• If lease terms are modified, new versions are created with full version history and

older versions archived for reference.

Online Rent Collection

• Tenant makes a payment via the app or website to the admin’s account.

• The admin dashboard reflects received payments and outstanding balances.

• The system automatically calculates the owner’s portion of the rent based on

predefined revenue sharing or commission rules.

• Owner dashboards update with expected payouts, and payments are disbursed

automatically (via bank transfer or accounting reconciliation).

• Admin and owner both receive notifications of payment receipts and distributions.

Maintenance Request Management

• A tenant notices a leaking faucet or broken appliance in their unit and submits a

maintenance ticket via the tenant app or portal.

• Tenant can attach photos to visually communicate the problem.

• Admin receives the ticket, reviews details, and assigns it to the appropriate

maintenance staff or contractor.

• Contractor completes a maintenance job assigned via the system.

• Contractor uploads and submits an invoice for the completed work through a

dedicated portal or via email integration.

• Property manager/admin reviews the invoice, verifies job completion, and

approves the payment.

• Admin processes the payment through integrated financial systems or manual

recording.

• The payment and invoice status are updated in the dashboard, maintaining clear

financial and task records.

• Notifications are sent to contractors confirming payment status.



canvas



Document Management

• Admin uploads lease agreements, legal notices, and financial documents

associated with a property or tenant.

• Tenants can securely access and download relevant documents such as signed

leases and payment receipts via their portal.

• Property managers update legal documents and track changes through version

control.

• Expiring download links ensure that shared documents are accessible only for a

limited time, maintaining confidentiality.

Owner Dashboard

Secure portal for owners to access occupancy rates, rent income, expense breakdowns,

downloadable statements and reports.

• Property owners log in to their secure dashboard anytime to review how their

properties are performing.

• They check occupancy rates to understand unit availability and tenant retention.

• Review detailed breakdowns of rent income, expenses (maintenance, management

fees), and net profits.

• Download monthly, quarterly, or annual financial statements and reports for tax

and accounting purposes.

• Receive notifications or alerts for lease renewals, upcoming expenses, or

important property updates.

Accounting and Financial Tools

• Property managers log rent income, maintenance expenses, management fees, and

other transactions manually or through automated integrations.

• The system generates comprehensive financial reports summarizing income,

expenses, and net profits for each property or portfolio.

• Profit distribution mechanisms allocate earnings to owners after deducting fees or

commissions.

• QuickBooks sync ensures accounting data stays consistent across platforms.

• Financial ledgers and reports can be exported in formats like CSV or Excel for

external use.

.

Communication and Notifications

• Property managers send bulk notifications about rent due dates, policy updates, or

emergency announcements to all tenants.



canvas



• Tenants receive automated reminders for upcoming rent payments or maintenance

request status changes.

• Important notices, such as building maintenance schedules or safety alerts, are

posted on a digital notice board accessible to tenants and owners.

• All sent messages and communication threads are stored and accessible in the

admin dashboard for auditing.

Reports and Dashboard

• Admins access the dashboard daily to monitor occupancy levels across properties

and identify vacancies.

• Payment summaries help track total rent collected, pending dues, and late

payments.

• Active maintenance and service requests are displayed for quick action and

workload management.

• Exportable reports support monthly accounting, owner reporting, and strategic

planning

Settings and Configuration

• Admins define user roles such as Admin, Property Manager, Accountant,

Maintenance Staff, and Tenant, assigning specific access rights.

• Pricing templates standardize rent calculations and additional fees across

properties or unit types.

• Fee rules automate charges like late fees, security deposits, and recurring

maintenance fees.

• Notification settings control how often tenants and staff receive reminders and

alerts via email or SMS.

Responsive UI and UX

• Tenants can easily browse property listings, submit maintenance requests, and pay

rent from any device.

• Property managers efficiently manage operations and communicate via mobile or

desktop without UI glitches.

• Owners access dashboards and reports on-the-go with a clear and consistent

design reflecting the company brand.



canvas



Non-Functional Requirements

1. Security

• HTTPS Everywhere:

All data exchanges between clients (web browsers, mobile apps) and servers will

be encrypted using HTTPS (SSL/TLS) to prevent interception and man-in-the-

middle attacks.

• Encrypted Storage:

Sensitive data like user credentials, financial details, and documents will be

encrypted both at rest (in databases/storage) and in transit to protect against

unauthorized access.

• Role-Based Access Control (RBAC):

The system will implement strict RBAC ensuring users only access data and

features relevant to their roles (Admin, Property Manager, Tenant, Owner,

Contractor). This limits exposure and enhances security.

• Authentication & Authorization:

Use secure authentication mechanisms (password hashing, multi-factor

authentication optionally) and session management to prevent unauthorized

logins.

• Data Privacy Compliance:

Adhere to applicable data protection laws (e.g., GDPR) including user consent,

data minimization, and secure deletion policies.

2. Scalability

• Modular Architecture:

The system will be designed using modular components and services, enabling

independent scaling of modules (e.g., payment processing, document

management) as demand grows.



canvas



• Load Balancing and Caching:

Use load balancers to distribute traffic evenly and caching strategies (e.g., Redis,

CDN) to reduce server load and improve response times.

• Database Scalability:

Design database schemas for efficient querying and support horizontal scaling or

sharding if needed.

• Cloud Readiness:

Architected to be deployable on scalable cloud platforms (AWS, Azure, etc.)

allowing resource adjustments based on load.

• Asynchronous Processing:

Use message queues and background jobs for heavy tasks like report generation,

email sending to avoid blocking user interactions.

3. Audit Logs

• Comprehensive Activity Tracking:

Log all critical user activities including logins, data changes (create, update,

delete), payments, and configuration changes.

• Immutable Logs:

Store audit logs securely and immutably to prevent tampering and support

forensic investigations.

• User Identification:

Logs will capture user identity, timestamp, affected resources, and action details.

• Access to Logs:

Authorized admins can review logs via the dashboard for monitoring, compliance,

and troubleshooting.

• Retention Policies:

Define retention periods for logs according to compliance and storage policies.

Additional Considerations

• Maintainability: Codebase and infrastructure should be easy to update and

debug.

• Usability: Interfaces should be intuitive and accessible.

.



canvas



Third-Party Integrations

1. Payment Gateways

• Stripe & Paystack:

• Integrate Stripe and Paystack to securely process online payments

including rent collections, fees, and contractor payments.

• Support multiple payment methods: credit/debit cards, bank transfers

(ACH), mobile wallets.

• Handle payment status updates (success, failure, pending) via webhooks

for real-time syncing.

• Provide refund and dispute management capabilities.

• Ensure PCI DSS compliance for secure handling of payment data.

2. Accounting Software

• QuickBooks Integration:

• Sync income, expenses, invoices, and payments automatically with

QuickBooks to maintain consistent accounting records.

• Support two-way data flow if applicable for updates and reconciliation.

• Automate generation of financial reports and tax documents.

• Reduce manual bookkeeping errors and improve financial accuracy.

3. Communication Services

• Twilio (SMS & Voice):

• Enable SMS notifications for rent reminders, maintenance updates, alerts,

and two-factor authentication (2FA).

• Optionally support voice calls for notifications or customer support.



canvas



• Mailgun & SendGrid (Email):

• Reliable email delivery services for bulk and transactional emails such

as payment receipts, announcements, and system alerts.

• Support email templates, tracking delivery status, and managing

bounces/spam.

• Enable scheduling and automation of emails.

4. E-signature Providers

• HelloSign & DocuSign:

• Facilitate digital signing of lease agreements, contracts, and other legal

documents.

• Provide legally binding e-signature workflows compliant with relevant

regulations.

• Track signature status and send reminders to signatories.

• Store signed documents securely with version control.

Technology Stack & API Details

Programming Language & Framework

- Backend Framework: Laravel (PHP)

- Frontend: Blade templating with Bootstrap for responsive design

- Server-side logic and business rules implemented using Laravel’s MVC architecture

Database

- Database Engine: MySQL 8.x

- ORM: Eloquent ORM (Laravel’s built-in ORM for interacting with MySQL)



canvas



API Architecture

- RESTful API design following Laravel best practices

- Versioned API routes (e.g., /api/v1/)

Authentication & Authorization

- Authentication via Laravel Passport (OAuth2-based token authentication)

- Role-Based Access Control (RBAC) for Admin, Property Manager, Owner, and Tenant roles

- Secure login/logout, forgot password, and password reset endpoints

- Protected routes using Passport middleware

Notification System

- Email: Using Mailgun or SendGrid integration via Laravel Notifications

- SMS: Using Twilio API for rent reminders, alerts, maintenance updates

- All notifications are configurable and queued for performance using Laravel Queues

Mobile Application Overview

The mobile application will offer users the ability to manage properties, payments, and

maintenance requests directly from their smartphones. It will be designed for both Android

and iOS platforms using a single codebase.

Technology Stack for Mobile App

- Framework: Flutter (for cross-platform development)

- Programming Language: Dart

- Backend Communication: RESTful APIs (Laravel)

- Authentication: OAuth2 (Laravel Passport)

- Push Notifications: Firebase Cloud Messaging (FCM)

- Secure Storage: Flutter Secure Storage / Encrypted Shared Preferences

- State Management: Provider / GetX / Bloc

Key Features of Mobile App

- User authentication for Tenants, Owners

- Dashboard with upcoming rent, maintenance alerts

- Online rent payments with integrated payment gateways



canvas



- Property and unit details with media display

- Maintenance request submission with photo/video attachments

- Push notifications for reminders and status updates

Data Syncing

- Automatic background sync when internet is available

- Background fetch for notifications and updates

Mobile App Deployment

- Android: Release via Google Play Store with internal testing support

- iOS: Apple App Store via TestFlight for testing





but client sent these messages in feedback check exactly which point is the part of scope and what point is not 

Hi Eeman, some additional comments: 

Hi Team,

I completed a second review of the software, including the mobile layout and several of the newer features. Please implement the following updates. The goal is to improve usability and organization without unnecessarily rebuilding features that already work.

1. Mobile Tables / Responsive Design

This is the biggest mobile issue I noticed. Many tables are being compressed to fit the phone screen, causing headings to display vertically one letter at a time.

Please make all tables mobile responsive. On smaller screens, tables should either:

* Scroll horizontally; or
* Convert each row into a mobile-friendly card/list.

Do not compress columns until the text becomes vertical or unreadable.

Please apply this consistently throughout the software, including Lease Overview, Lease Tracker, Rentals, Lease Renewals, Owner Distribution Reports, Work Orders/reports and other tables.

2. Property & User Assignment

When someone creates a property, they should automatically be assigned to that property based on their applicable role.

For example:

* Landlord creates property → automatically assigned as Landlord.
* Property Manager creates property → automatically assigned as Property Manager.

Landlords and Property Managers should then be able to assign appropriate users to the property, including each other, tenants, staff, etc., subject to permissions.

There should be a clear Assigned Users / Property Access area within each property so it is easy to see who has access.

3. Property/Unit Types

Please ensure the property and unit setup supports both residential and commercial real estate.

Residential examples include apartment, townhouse, house, etc.

Commercial options should include office, retail, industrial, warehouse, commercial condominium, land, mixed-use, outside storage and other/custom.

The terminology should also adapt appropriately. For example, commercial properties may use Unit / Suite / Space rather than only “Unit.”

4. Repair Request Priority

Tenant repair requests should continue to allow:

* Low
* Medium
* High

For tenants, please add the following wording beside/under the priority selection:

“High Priority should only be selected for urgent repair issues requiring prompt attention. Landlord and/or the Property management will review the request and may adjust the priority based on the nature of the issue.”

Landlords and Property Managers must be able to change the tenant-selected priority after reviewing the request, including downgrading a High request to Medium or Low.

Please retain both:

Tenant Submitted Priority and Current/Management Priority

This creates a record of what the tenant originally selected while allowing management to properly triage requests.

If management changes the priority, record the change in the activity/history log.

5. Repair Requests → Work Orders → Contractors

The existing workflow allowing a tenant repair request to generate a work order should remain.

The intended workflow should be:

Tenant Repair Request → Management Review/Priority → Create Work Order → Assign/Send to Contractor → Contractor Communication → Completion → Record/History

Contractors added to the system should be selectable when creating/sending work orders.

The existing ability to communicate with contractors and send RFPs should remain and be connected to the relevant property/work order where applicable.

6. Lease Renewals

The Lease Renewals dashboard is useful and should remain.

Please make sure the upcoming/expiring lease information can be filtered by property, tenant, date/window and status.

The dashboard should help management identify leases requiring action rather than only displaying information.

7. Lease Overview / Lease Tracker

Please review whether Lease Overview, Lease Tracker and Lease Renewals contain unnecessary duplication.

They can remain separate if each has a clear purpose, but navigation and terminology should make the difference obvious.

Lease records should ideally connect the property/unit, tenant, start date, end date, rent, status, signed agreement/document and renewal history.

8. Roles & Permissions

Please clean up the existing roles.

For example, Land Owner and Land Lord appear to be unnecessarily separate and should generally be standardized as Landlord/Owner unless there is a technical reason to keep both.

Roles should include appropriate options such as:

* Landlord/Owner
* Property Manager
* Tenant
* Staff
* Superintendent
* Contractor
* Admin/Super Admin

Custom staff roles can continue to be created where required.

Permissions should control both what a user can do and what properties/documents/information they can access.

9. Notices & Communications

Please rename the existing Announcement section to:

Notices & Communications

Keep the general existing structure but change it to:

* Send Notice / Communication
* Communication History
* Delivery Report
* Documents

Please replace references to “Announcement” throughout this section with “Notice” or “Communication” where appropriate.

10. Send Notice / Communication

Rename Bulk Announcement to Send Notice / Communication.

Keep the existing ability to select recipients and properties.

Users should be able to send to:

* All applicable users
* Selected property/properties
* Selected units/spaces
* Tenants
* Landlords/Owners
* Property Managers
* Staff
* Contractors
* Specific users

Continue allowing Email and/or SMS and document attachments.

Add two sending options:

○ Send Now

○ Schedule Send

If Schedule Send is selected, show Date and Time fields.

Scheduled communications should be editable/cancellable before being sent.

Instead of displaying technical date validation errors, simply display:

“Please select a future date and time.”

11. Communication History & Delivery

Rename SMS Alert Log under the current Announcement area to Communication History.

This should maintain a permanent management record of formal notices/communications sent through the system.

Include date/time, subject, property, recipient(s), sender, communication method and delivery status.

Where possible, allow:

View | Duplicate/Resend

Keep Delivery Report, but allow it to show Sent, Delivered, Failed, Scheduled/Pending and Cancelled communications.

12. Documents

Add Documents as a subcategory under Notices & Communications.

Documents should be associated with a property and, where applicable, a specific unit/space or user.

Examples include:

* Building Rules
* Tenant Forms
* Notices
* Policies
* Move-In/Move-Out Forms
* Elevator Reservation Forms
* Party/Amenity Room Forms
* Parking Forms
* Staff/Superintendent Work Schedules
* Contractor Work Schedules
* RFP Documents
* Contractor Instructions/Specifications
* Emergency Information
* Other/Custom

Most importantly, document access must be permission-based.

When uploading a document, management should be able to choose who can access it, such as:

* Management Only
* Landlords/Owners
* Property Managers
* All Tenants at Property
* Selected Tenant(s)/Unit(s)
* Staff
* Selected Staff/Superintendent
* Contractors
* Selected Contractor(s)
* Custom Access

For example, a superintendent’s work schedule should only be visible to the applicable staff/management, while an RFP or contractor work schedule could be shared only with the selected contractor.

Tenants, staff and contractors should only see documents specifically made available to their role/account/property.

When sending a Notice/Communication, also provide an optional:

☐ Publish to Documents

This allows important notices to remain accessible in the appropriate user’s document portal after they are sent.

An optional expiry/display-until date can remove an old notice from the user’s portal while retaining it permanently in management’s Communication History.

13. SMS Box

After further review, please keep SMS Box separate from Notices & Communications.

SMS is currently being used for automated/system text messages such as account creation, activation and other system notifications.

The SMS Logs should clearly show the recipient, message, date/time, type/reason and delivery status.

Where possible, distinguish between:

System/Automated SMS and Manually Sent SMS.

14. Messenger

Please also keep Messenger separate.

Messenger serves a different purpose: two-way/direct conversations between users.

The distinction should therefore be:

Notices & Communications = formal notices, bulk/property communications and documents.

SMS Box = automated/system SMS and SMS records.

Messenger = two-way/direct conversations between users.

Messenger conversations should be associated with the users involved and, where applicable, their property.

15. General Mobile Review

Finally, please complete a mobile-responsive review of all pages. The software should be easy to operate from a phone since landlords, property managers, superintendents, tenants and contractors will frequently access it from mobile devices.

Please specifically check tables, buttons, dropdowns, forms, navigation, text wrapping, date/time selectors and pop-ups on mobile.

The main objective with these changes is to keep the functionality already developed, while simplifying the interface and creating a clear workflow between properties → users → tenants → repair requests → work orders → contractors → communications → documents and records.









Hi Eeman, I have some more comments I tried to add the property for the client I am working with and ran into some issues. I’ve used chatGPT to summarize how I would like the add property feature to be:



Property Module – Required Revisions



Please revise the existing Property module. The current setup appears to contain several fields/functions that are more applicable to a generic real estate sales platform rather than property management.



The software needs to support both residential and commercial property management, including mixed-use properties.



The basic structure should be:



Property → Unit/Space → Tenant → Lease



Advertising should be a separate module.



⸻



1. Remove Existing Fields/Functions



Please remove the following from the current Property module:



* Completion

* Vacant checkbox at Property level

* Feature on Home Page

* Drawing Dining Combined

* Bedroom

* Bathroom

* Rent Amount

* Rent/Sell

* Flat No.

* Reject

* Video Verification

* Any other residential sales-specific fields



Video Verification should be removed entirely from the Property action menu.



The existing Categories such as Public Transportation, Toiletries, Haircut, Sports, Concerts, Movies, Entertainment, etc. should also be removed/replaced with property-management-specific amenities.



⸻



2. Add Property



The Add Property page should only collect information relating to the overall property.



Property Information



* Property Name

* Property Category:

    * Residential

    * Commercial

    * Mixed Use

* Number of Units/Spaces

* Property Size – optional

* Comments/Notes – optional

* Property Photos – optional



Do not include bedrooms, bathrooms or rent at the Property level.






3. Address



Please integrate Google Maps/Places address autocomplete.



The user should begin typing the address, select the correct Google result and have the system automatically populate:



* Street Address

* City

* Province/State

* Country

* Postal Code



Please change Post Code to Postal Code.



The current Country dropdown works, but Province/State and City do not appear to populate correctly. Google address autocomplete should eliminate most manual address entry.



⸻



4. Property Amenities



Replace the existing Categories with relevant property amenities.



Examples:



* Elevator

* Laundry

* Gym

* Pool

* Visitor Parking

* EV Charging

* Security/Cameras

* Concierge

* Bicycle Storage

* Loading Area

* Shipping/Receiving

* Outdoor Space

* Other



Please allow:



+ Add Custom Amenity



Amenities should be optional and multiple amenities can be selected.



⸻



5. Parking & Storage



Parking – Optional



* Does the property have parking? Yes/No

* Total number of parking spaces

* Option to create individual parking spaces (P1, P2, P3, etc.)

* Individual spaces can be assigned to Units/Spaces

* Parking fees can be recorded



The user should also be able to simply record the total number of parking spaces without individually identifying them.



Storage – Optional



* Does the property have storage? Yes/No

* Total number of lockers/storage spaces

* Option to create individual lockers/storage spaces

* Individual lockers can be assigned to Units/Spaces

* Storage fees can be recorded



The user should also be able to simply record the total number of storage spaces without individually identifying them.



Neither parking nor storage should be mandatory.



⸻



6. Property Assignment & User Roles



Currently, the system indicates that a property must be assigned, but there does not appear to be a clear way to assign it.



Please change this so:



The user who creates a property is automatically assigned to that property.



Their role should be identified as:



* Landlord/Owner

* Property Manager



A property can have:



* Multiple Landlords/Owners

* Multiple Property Managers



Landlord/Owner Permissions



Can:



* Add/manage their properties

* Assign/remove Property Managers

* Add/assign tenants



Property Manager Permissions



Can:



* Add/manage assigned properties

* Assign Landlords/Owners

* Add/assign tenants

* Manage Units/Spaces

* Manage leases



Tenant Permissions



Tenants should be assigned to their specific Unit/Space and Lease and receive tenant-level permissions only.



Roles should be property-specific.



For example, the same user could be:



Owner → Property A

Property Manager → Property B



⸻



7. Add Unit / Space – New Function



Once a property is created, there should be:



+ Add Unit/Space



The user first selects:



Unit/Space Category



* Residential

* Commercial

* Land



The system should then display fields relevant to that selection.



Residential



Types:



* Apartment

* Townhouse

* House

* Other



Fields:



* Unit Number/Name

* Bedrooms

* Bathrooms

* Unit Size – optional

* Parking Assignment – optional

* Storage Assignment – optional

* Notes – optional



Commercial



Types:



* Retail

* Office

* Industrial

* Warehouse

* Flex

* Medical

* Restaurant

* Commercial Condominium

* Other



Commercial fields should adapt depending on the selected type and can include:



* Unit/Suite Number

* Square Footage

* Floor

* Clear Height

* Drive-In Doors

* Truck-Level Doors

* Shipping Doors

* Office Area

* Retail Area

* Warehouse/Industrial Area

* Parking

* Storage

* Notes



These fields should generally be optional so users are not forced to enter irrelevant information.



Land



Land should be supported without requiring a traditional unit.



Fields:



* Acreage

* Lot Size

* Frontage

* Depth

* Zoning

* Outside Storage – Yes/No

* Notes



⸻



8. Unit/Space Status



Vacancy and occupancy should be tracked at the Unit/Space level, not Property level.



Status options:



* Vacant

* Occupied

* Notice Given

* Available Soon

* Offline/Unavailable



The overall property’s occupancy should then be calculated automatically from its Units/Spaces.



Example:



20 Units



* 18 Occupied

* 1 Vacant

* 1 Notice Given



Please also add:



Bulk Unit Creation



Example:



Create Units 101–120



This avoids manually creating 20 units.



CSV/Excel Import



Allow landlords/property managers to import existing unit lists for larger properties.



⸻



9. Tenant & Lease Assignment



Tenants should be assigned to a specific Unit/Space, rather than simply to the overall property.



Structure:



Property → Unit/Space → Tenant → Lease



Multiple tenants should be allowed on the same Unit/Space and lease.



Residential Lease Information



* Tenant(s)

* Lease Start Date

* Lease End Date

* Monthly Rent

* Parking Fee

* Storage Fee

* Other Recurring Charges

* Deposits – where applicable

* Lease Notes



Commercial Lease Information



Also support:



* Base Rent

* Rent per Square Foot

* Additional Rent / TMI / CAM

* Percentage Rent – optional

* Security Deposit

* Renewal/Extension Options

* Other Recurring Charges



Please keep:



Current Lease Rent



and



Asking Rent



as separate fields.



Current Lease Rent = what the existing tenant is actually paying.



Asking Rent = what a vacant/available Unit/Space is being marketed for.



⸻



10. Property Dashboard – Redesign



Based on the current Property screen, please simplify the dashboard.



The current table contains too much information and requires horizontal scrolling, particularly on mobile.



Instead, each property should display a simple summary/card.



Example:



200 Brown’s Line

Mixed Use

7 Units/Spaces

6 Occupied | 1 Vacant

Etobicoke, ON



Actions:



View Property

Manage Units/Spaces

Edit

Manage Users



Delete can remain available but should not be a prominent action to avoid accidental deletion.



Please remove from the Property dashboard:



* Reject

* Video Verification

* Rent/Sell

* Bedrooms

* Bathrooms

* Flat No.

* Individual Unit Rent



Those items either are unnecessary or belong within the Unit/Space level.



⸻



11. Property Detail Page



When the user selects View Property, create a clean Property Detail/Dashboard page.



At the top show:



* Property Name

* Address

* Property Category

* Number of Units/Spaces

* Occupied

* Vacant

* Property Manager(s)

* Owner(s)



Then provide sections/tabs such as:



Overview | Units/Spaces | Tenants | Leases | Parking | Storage | Documents | Users



This should become the central location for managing the property.



For example:



200 Brown’s Line



Overview

→ Property information and occupancy summary



Units/Spaces

→ All residential/commercial spaces



Tenants

→ Tenants associated with the property



Leases

→ Active/past leases



Parking

→ Parking inventory and assignments



Storage

→ Locker/storage inventory and assignments



Documents

→ Property-level documents



Users

→ Owners/Property Managers assigned to the property



This will be much easier to navigate than trying to place everything into the main Property table.



⸻



12. Mobile Design



Please ensure the Property module is designed mobile-first/responsive.



The current Property table requires horizontal scrolling and information is cut off on mobile.



Avoid wide tables wherever possible.



For mobile:



* Use property cards/summary rows

* Stack important information vertically

* Use clear action buttons

* Keep secondary information inside View Property

* Avoid horizontal scrolling

* Forms/dropdowns should fit properly within the mobile screen



The desktop version can display more information, but the underlying navigation should remain consistent.



⸻



13. Mixed-Use Properties



Mixed-use properties need to support different types of Units/Spaces within the same property.



Example:



200 Brown’s Line – Mixed Use



→ Unit 1 – Retail

→ Unit 2 – Residential Apartment

→ Unit 3 – Residential Apartment

→ Unit 4 – Residential Apartment



The overall property is Mixed Use.



Each Unit/Space then has its own category and type.



Therefore, do not make “Commercial” the final classification.



Example:



Property Category: Mixed Use



Unit/Space Category: Commercial



Space Type: Retail



This structure will allow the software to accommodate virtually any combination of residential and commercial uses.



⸻



14. Advertising – Separate Module



Remove Feature on Home Page from Add Property.



Create a separate main menu:



Advertise



Then:



+ Add Advertisement



The user selects:



Property → Unit/Space



The system should automatically pull existing information such as:



* Address

* Property information

* Unit/Space information

* Bedrooms/Bathrooms where applicable

* Square footage

* Amenities

* Parking

* Storage

* Photos



The user should not have to enter this information again.



Advertisement Fields



* Property

* Unit/Space

* Asking Rent

* Available Date

* Minimum Lease Term

* Maximum Lease Term – optional

* Parking availability/cost

* Storage availability/cost

* Rent Incentive – optional

* Advertisement Description/Comments

* Photos

* Contact Information

* Status:

    * Draft

    * Active

    * Inactive



Residential Utilities



Allow Included / Extra for:



* Hydro

* Water

* Gas

* Hot Water Tank

* Other + description



Commercial Advertising



Allow:



* Asking Net Rent

* Additional Rent/TMI

* Asking Rent per Square Foot

* Available Square Footage

* Zoning

* Available/Possession Date

* Lease Term



Only an Active Advertisement should appear on the public-facing website/homepage.



⸻



15. Avoid Duplicate Data Entry



This is important throughout the software.



Information should only need to be entered once and then reused.



PROPERTY



Address

Property Category

Amenities

Parking/Storage Inventory

Owners/Property Managers



↓



UNIT / SPACE



Unit/Suite

Residential/Commercial Type

Physical Characteristics

Parking/Storage Assignment



↓



TENANT / LEASE



Tenant

Actual Rent

Additional Charges

Lease Terms



↓



ADVERTISEMENT



Select Property + Unit/Space

Automatically pull existing information

Add Asking Rent + Marketing Information

Publish



⸻



Overall Goal



The Property module should be flexible enough to manage:



* Single residential rental properties

* Apartment buildings

* Townhouse complexes

* Retail plazas

* Office buildings

* Industrial buildings

* Multi-tenant industrial properties

* Commercial condominiums

* Mixed-use properties

* Land



The user should only see fields relevant to the type of Property or Unit/Space they are working with.



The goal is to make the software simple for a small landlord managing a few units while still scalable for a professional property manager managing hundreds of residential and commercial units/spaces.