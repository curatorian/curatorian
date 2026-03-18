# Curatorian Whitepaper
## A Community Platform for Every Curator in Indonesia

**Version:** 1.0
**Published:** March 2026
**Author:** Chrisna Adhi
**Contact:** hello@curatorian.id
**Website:** curatorian.id

---

> *"Sebuah koleksi yang tidak terkatalogisasi sama saja dengan tidak ada."*
>
> — Prinsip dasar ilmu perpustakaan

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [The Problem](#2-the-problem)
   - 2.1 [The Indonesian GLAM Landscape](#21-the-indonesian-glam-landscape)
   - 2.2 [Documented Pain Points](#22-documented-pain-points)
   - 2.3 [Why Existing Tools Fall Short](#23-why-existing-tools-fall-short)
3. [The Solution: Curatorian](#3-the-solution-curatorian)
   - 3.1 [What Curatorian Is](#31-what-curatorian-is)
   - 3.2 [The Two-Layer Promise](#32-the-two-layer-promise)
   - 3.3 [Who Built This and Why It Matters](#33-who-built-this-and-why-it-matters)
4. [Who We Serve](#4-who-we-serve)
   - 4.1 [Individual Curators](#41-individual-curators)
   - 4.2 [Non-Profit Community Institutions](#42-non-profit-community-institutions)
   - 4.3 [For-Profit Institutions](#43-for-profit-institutions)
5. [Platform Features](#5-platform-features)
   - 5.1 [Collection Management](#51-collection-management)
   - 5.2 [Community Layer](#52-community-layer)
   - 5.3 [Event & Webinar Platform](#53-event--webinar-platform)
   - 5.4 [Job Board](#54-job-board)
   - 5.5 [Freelance & Expert Marketplace](#55-freelance--expert-marketplace)
   - 5.6 [Shared Bibliographic Network](#56-shared-bibliographic-network)
   - 5.7 [Digital Exhibition Builder](#57-digital-exhibition-builder)
   - 5.8 [Institutional Crowdfunding](#58-institutional-crowdfunding)
   - 5.9 [Reading Program Manager](#59-reading-program-manager)
6. [Technical Architecture](#6-technical-architecture)
   - 6.1 [System Design Principles](#61-system-design-principles)
   - 6.2 [The Three-Layer Architecture](#62-the-three-layer-architecture)
   - 6.3 [Database Strategy](#63-database-strategy)
   - 6.4 [Authentication & Security](#64-authentication--security)
   - 6.5 [Bibliographic Data Strategy](#65-bibliographic-data-strategy)
   - 6.6 [Technology Stack](#66-technology-stack)
7. [Open Source Philosophy](#7-open-source-philosophy)
   - 7.1 [The Open Core Model](#71-the-open-core-model)
   - 7.2 [What Is Open and What Is Not](#72-what-is-open-and-what-is-not)
   - 7.3 [Why This Model Serves Indonesian GLAM](#73-why-this-model-serves-indonesian-glam)
8. [Business Model & Sustainability](#8-business-model--sustainability)
   - 8.1 [Philosophy](#81-philosophy)
   - 8.2 [Pricing Tiers](#82-pricing-tiers)
   - 8.3 [Revenue Streams](#83-revenue-streams)
   - 8.4 [The Path to Sustainability](#84-the-path-to-sustainability)
9. [Competitive Landscape](#9-competitive-landscape)
10. [Roadmap](#10-roadmap)
    - 10.1 [Phase 1 — Foundation (2026, Q1–Q2)](#101-phase-1--foundation-2026-q1q2)
    - 10.2 [Phase 2 — Community Launch (2026, Q2–Q3)](#102-phase-2--community-launch-2026-q2q3)
    - 10.3 [Phase 3 — Platform Expansion (2026, Q3–Q4)](#103-phase-3--platform-expansion-2026-q3q4)
    - 10.4 [Phase 4 — Marketplace & Depth (2027)](#104-phase-4--marketplace--depth-2027)
11. [Join the Movement](#11-join-the-movement)

---

## 1. Executive Summary

Indonesia is home to tens of thousands of curated collections — community reading gardens, school libraries, local museums, mosque archives, corporate knowledge centers, and personal book collections assembled by people who care deeply about knowledge and cultural heritage. The vast majority of these collections exist only in paper ledgers, handwritten registers, or someone's memory. They are invisible to the public, inaccessible to researchers, and impossible to manage systematically by the people who tend them.

The tools available to address this problem are inadequate. Self-hosted open source software requires technical knowledge most collection managers do not have. Foreign SaaS products are expensive, culturally mismatched, and not designed for Indonesian collection types. Spreadsheets scale poorly and cannot be shared. Nothing exists that is designed for the full spectrum of Indonesian curators — from an individual with two hundred personal books to a state-owned enterprise with a CSR library obligation.

**Curatorian** is a hosted, community-first platform that changes this.

Any curator in Indonesia — an individual collector, a Taman Bacaan Masyarakat (TBM) operator, a museum archivist, a corporate librarian — can sign up at `curatorian.id`, create their collection space, and have a publicly accessible digital catalog within thirty minutes. No server to maintain. No installation. No technical expertise required. Free, permanently, for non-profit and community institutions.

Beyond collection management, Curatorian is the professional home for Indonesian GLAM (Galleries, Libraries, Archives, Museums) practitioners: a community with a blog, follow system, and messaging; a venue for professional events and webinars; a job board for GLAM sector positions; and, in time, a marketplace connecting institutions that need specialized help with professionals who can provide it.

The platform is built on three layers of open source and proprietary software, developed by a practicing librarian who can code — a rare combination that ensures every feature decision is grounded in domain expertise rather than technical novelty.

The business model is community-first: permanently free for individuals and non-profits, subscription-based for commercial institutions, and sustained long-term by platform fees from events, job postings, and a freelance marketplace. Curatorian does not need to choose between being useful to the community and being financially sustainable. The model is designed so that one funds the other.

This whitepaper describes the problem in full, the solution in detail, the technical architecture, the open source strategy, the business model, and the roadmap for how this platform will grow.

---

## 2. The Problem

### 2.1 The Indonesian GLAM Landscape

GLAM — Galleries, Libraries, Archives, and Museums — is the collective term for institutions and individuals responsible for preserving, organizing, and making accessible cultural, historical, and scientific collections. In Indonesia, this sector is vast, deeply distributed, and profoundly underserved.

Consider what exists across the archipelago:

- **Taman Bacaan Masyarakat (TBM):** Over 13,000 registered community reading gardens, with an estimated equal number unregistered. Many are operated from someone's home, garage, or a small rented space. They serve as the primary reading infrastructure for communities that lack access to formal libraries.

- **School libraries:** Permendikbud (the Indonesian Ministry of Education and Culture) mandates that every accredited school maintain a library. Tens of thousands of school libraries exist as a result — many understaffed, underfunded, and managed by teachers who have been assigned the role rather than trained professionals.

- **Local museums and archives:** District-level museums, cultural archives maintained by local governments, community historical collections, and specialist archives (batik, puppetry, local manuscripts) exist across every province — most with minimal digitization and no online presence.

- **Religious institution libraries:** Mosque libraries (*perpustakaan masjid*), pesantren collections, and faith-based community reading programs maintain significant collections of religious and general texts, often with no catalog whatsoever.

- **Corporate and CSR libraries:** Indonesian regulation encourages — and for state-owned enterprises (*BUMN*), effectively mandates — corporate social responsibility programs that include community library facilities. These range from a shelf of books in a break room to dedicated reading rooms with thousands of volumes.

- **Individual collectors:** Researchers, academics, professionals, book enthusiasts, and cultural hobbyists who maintain personal collections that are meaningful, curated, and currently invisible to anyone outside their immediate circle.

Across all these contexts, the pattern is the same: collections exist, people care for them, and almost none of it is properly cataloged, accessible, or connected to anything.

### 2.2 Documented Pain Points

The following pain points are documented from direct experience and from research within the Indonesian GLAM practitioner community. They are organized by category.

#### Digital and Infrastructure Gaps

**Lack of digital readiness and no proper databases.**
Most Indonesian GLAM institutions — particularly TBM, small school libraries, and local archives — still rely on manual records: handwritten ledgers, simple index cards, or at best an unstructured spreadsheet. Finding a specific item requires knowing roughly where it is. Inventory is guesswork. Searching is impossible. A collection managed this way is, for all practical purposes, closed.

**Inadequate technological infrastructure.**
Limited budgets for hardware, software, and internet connectivity prevent most institutions from pursuing digital solutions even when they understand the need. A TBM operator may have a smartphone and a shared data plan. Asking them to configure a PostgreSQL server and install a web application is not a reasonable expectation.

**"Dead archives" — collections inaccessible to researchers and the public.**
Collections that are not discoverable might as well not exist for researchers, students, or members of the public who do not already know to look for them. The consequence reaches beyond local inconvenience: scholars studying Indonesian cultural and historical subjects have, in documented cases, traveled to archives in the Netherlands to access Indonesian materials that exist in Indonesia but are simply impossible to find.

**Poor accessibility compounds over time.**
An undocumented collection grows harder to manage with each addition. A new operator who inherits a collection with no records must start cataloging from scratch. Items are lost. Provenance is forgotten. The institutional memory of a collection is fragile when it exists only in a person's head.

#### Human Resource and Competency Gaps

**Limited staff competence in modern information management.**
Archivists, librarians, and collection managers in community settings often lack formal training in digital tools, metadata standards, and systematic preservation practices. Many school library "librarians" are teachers assigned the responsibility as a secondary duty. Many TBM operators are passionate community members, not information professionals. The tools available to them must be simpler than the skills they currently possess.

**Widespread copyright confusion.**
A pervasive misunderstanding of copyright law and open licensing leads many institutions to avoid sharing their collections online entirely. The fear is understandable but counterproductive: institutions that could make their collections discoverable choose not to because they are uncertain about what they are legally permitted to do. A practical, plain-language framework for collection rights is missing from most community practice.

**Low public awareness of cultural heritage value.**
When the general public does not understand the importance of collection preservation, it becomes difficult to justify funding, attract volunteers, or build donor support. A TBM operator or local archivist working without public recognition or institutional support is fighting an uphill battle that better tools alone cannot solve — but community visibility is a meaningful part of the solution.

#### Administrative and Institutional Barriers

**Chronic underfunding.**
The Indonesian GLAM community sector operates on minimal resources. The tools available to these institutions must be either free or very cheap. A subscription model priced for Western nonprofit organizations is simply inaccessible to most Indonesian community libraries.

**Information silos.**
Collection data almost universally remains within institutional walls. There is no easy mechanism for sharing catalog records across institutions, building shared bibliographic resources, or discovering what exists in nearby collections. Every institution independently catalogs the same widely-read Indonesian titles — hundreds of times over, across the country. This redundancy is waste that a networked platform can eliminate.

**Fear of digital openness.**
Some institutions resist putting their collections online out of a mistaken belief that online access will reduce physical visitors. This fear has been consistently contradicted by research across multiple countries and institution types: online discoverability drives physical engagement, not away from it. Overcoming this fear requires both education and tools that make privacy controls transparent and easy to configure.

**Isolation of practitioners.**
A TBM operator in Bandung and a school librarian in Manado face nearly identical challenges but have no shared infrastructure to learn from each other, ask questions, or find solidarity. The Indonesian library and GLAM community has professional organizations (IPI, ATPUSI) and active WhatsApp groups, but no shared digital home that connects their practical work to their professional development and their collections to each other.

### 2.3 Why Existing Tools Fall Short

**SLiMS (Senayan Library Management System)** is the most widely used library management system in Indonesia. It is free, open source, and genuinely functional. It is also self-hosted only — there is no cloud version. Installing SLiMS requires configuring a web server, a MySQL database, and PHP. Maintaining it requires ongoing technical attention. For a TBM operator or a school librarian without IT support, this is an insurmountable barrier. SLiMS also has no community layer, no public discovery mechanism, and no path to becoming anything other than a catalog system.

**International SaaS products** (LibraryThing, TinyCat, Koha Cloud, and others) are well-designed and feature-rich. They are also priced for Western markets, presented in English, designed for Western collection types and cataloging conventions, and built without Indonesian context. They do not accept QRIS or bank transfer payments. They have no community for Indonesian practitioners. They will not build these things for a market they do not prioritize.

**Spreadsheets and WhatsApp groups** are the real incumbent. Most small collections are managed through a combination of Google Sheets, paper, and informal communication. This "system" is free, familiar, and requires no learning curve. It is also unsearchable, not shareable in a structured way, prone to corruption, and unable to grow with the collection. The switching cost from spreadsheets to any formal system feels high — which is why Curatorian's onboarding is designed to deliver a working public catalog within thirty minutes and provides CSV import to migrate existing spreadsheet data with minimal friction.

**Nothing serves the full spectrum.** The deepest gap in the existing landscape is the absence of any tool designed for the range of curators who exist in Indonesia. A retired professor with 800 personal books has completely different needs from a corporate CSR library — but both need a hosted catalog solution that requires no technical setup. No existing product thinks about this spectrum together.

---

## 3. The Solution: Curatorian

### 3.1 What Curatorian Is

**Curatorian is a hosted, community-first platform where any curator in Indonesia — an individual with two hundred books, a Taman Bacaan Masyarakat, a museum archivist, or a company with a CSR library — can digitize their collection, manage it professionally, connect with other curators, and access tools that were previously only available to well-funded institutions.**

The platform is accessible at `curatorian.id`. Users sign up, create a node (their collection space), and begin cataloging. There is no software to install, no server to maintain, no database to configure. It works on any device with a web browser, including a smartphone on mobile data.

For non-profit and community institutions, the core platform is free, permanently. This is not a trial, a crippled tier, or a marketing tactic. It is a deliberate design choice grounded in the economics and values of the Indonesian GLAM community.

### 3.2 The Two-Layer Promise

Curatorian is deliberately two things at once. This dual nature is its core competitive advantage.

**Layer 1 — Collection Management Tool.**
A proper cataloging, circulation, and collection management system. Enter your items, track who has borrowed what, manage your patrons, generate reports for donors or accreditation bodies, and expose a publicly accessible catalog page. This is the immediate, practical reason someone signs up.

**Layer 2 — Professional Community.**
A community of practice for Indonesian GLAM workers. Follow other curators, publish to the community blog, attend or host professional events and webinars, find freelance work, post or discover job opportunities. This is why people stay, why the platform grows through word of mouth, and why switching to a competitor eventually feels costly in ways that go beyond data migration.

Neither layer alone creates a defensible platform. A collection management system without community is just another SLiMS — functional but not sticky. A community without collection tools is just another forum. Together, they create something that does not currently exist for Indonesian GLAM practitioners.

### 3.3 Who Built This and Why It Matters

Curatorian was initiated and is being built by **Chrisna Adhi**, a practicing librarian and software developer at Universitas Padjadjaran (Unpad) in Bandung, Indonesia.

This combination — librarian and coder — is rarer than it sounds, and it matters enormously for product quality. Most library software is built by developers who learn about libraries. Curatorian is built by a librarian who learned to develop. The difference shows in every feature decision: the choice to make ISBN optional (because small Indonesian publishers frequently do not register ISBNs); the integration of Indonesian bibliographic sources alongside international ones; the choice of Bahasa Indonesia as the primary language for all UI copy; the decision to make the free tier genuinely functional rather than a crippled demo.

The first version of Curatorian emerged from a real project: rebuilding the fragmented library management infrastructure at Unpad — twenty separate SLiMS databases across faculties, unified into a single Phoenix application with a shared catalog. That system is in production. Curatorian is the next step: taking the same architecture and opening it to every curator in Indonesia.

---

## 4. Who We Serve

Curatorian has three primary user segments with distinct needs, motivations, and economic relationships to the platform.

### 4.1 Individual Curators

**Bahasa Indonesia:** *Kurator Perorangan*

Individuals who maintain personal collections and want to catalog, organize, and share them properly. Book collectors. Film archivists. Comic enthusiasts. Researchers cataloging their personal reference libraries. People who have assembled something meaningful over years and want to manage it with more than a spreadsheet.

These users need a beautiful, friction-free cataloging interface; a public profile page that showcases their collection; and a way to discover others who share their interests. They have no interest in paying a monthly subscription for a personal catalog. They contribute to the platform not as payers but as community members — generating content, building the network, and demonstrating the platform's value to the institutional users who do pay.

The individual curator segment also provides an important conversion path: a TBM operator often begins as an individual user, exploring the platform personally before registering their institution. A school librarian who discovers Curatorian through a personal collection may subsequently introduce it to their school.

### 4.2 Non-Profit Community Institutions

**Bahasa Indonesia:** *Institusi Komunitas*

Taman Bacaan Masyarakat, community libraries, school libraries, university student association libraries, NGO archives, mosque and pesantren libraries, small local museums, neighborhood reading programs, and any institution that manages a collection for public or community benefit without commercial motivation.

This segment is the heartbeat of Indonesian reading culture. TBM operators run their facilities on mission, community belief, and frequently personal sacrifice. They are chronically underfunded and technically underserved. They need:

- A proper catalog system at zero cost — absolutely non-negotiable
- A public presence that makes their collection visible and discoverable
- Tools to demonstrate impact to donors, local government, and partner organizations
- Simple enough operation that a volunteer with no IT background can manage it
- Connection to other TBM and librarians for peer support and shared knowledge

The community features of Curatorian are not supplementary for this segment — they are central. A TBM operator wants to blog about their reading programs, follow established operators in other cities, receive encouragement and advice, and find solidarity with people facing identical resource constraints. Curatorian is a social infrastructure play as much as a software play.

This segment contributes to the platform's sustainability through voluntary donations and, more importantly, through word-of-mouth amplification. In the tight-knit Indonesian librarian and TBM community, a genuine recommendation from a respected operator reaches hundreds of potential users overnight.

### 4.3 For-Profit Institutions

**Bahasa Indonesia:** *Institusi Komersial*

Businesses and organizations that maintain collections for commercial, regulatory, or brand positioning reasons:

- **State-owned enterprises (BUMN)** and large corporations with CSR-mandated library facilities
- **Cafes and restaurants** that build book collections into their concept
- **Co-working spaces** with member reference libraries
- **Boutique hotels** with curated reading rooms
- **Private schools and universities** wanting a modern catalog beyond SLiMS
- **Law firms, clinics, and professional offices** with specialized reference collections
- **Corporate knowledge centers** managing internal documentation and resources

These institutions have operational budgets, clearer procurement processes, and someone with authority to approve a monthly subscription. The purchase decision is typically made by one or two people without lengthy institutional approval cycles — much simpler than selling to a public school where three stakeholders must sign off on any spending.

Their needs center on reliability, a polished public presence, reporting they can show to management or CSR audit committees, and priority support in Bahasa Indonesia. They do not need deep cataloging expertise — they need a system that a non-librarian staff member can operate without training.

This segment is the platform's primary commercial revenue source and the foundation of its long-term financial sustainability.

---

## 5. Platform Features

### 5.1 Collection Management

The core of what Curatorian does. Every curator on the platform has access to a complete, professional collection management system.

**Cataloging.** Items are created with flexible bibliographic metadata: title, subtitle, authors, publisher, year, edition, language, subject categories, physical format, condition, and location within the physical space. A customizable field system (EAV — Entity-Attribute-Value) means the same platform works equally well for books, museum objects, archive documents, film reels, and any other collection type. The schema does not privilege one GLAM discipline over another.

**ISBN Lookup and Bibliographic Cache.** When cataloging books, users can type or scan an ISBN. The system consults a prioritized chain of bibliographic sources — a local cache first, then Open Library, OpenAlex, Google Books, and the Perpustakaan Nasional catalog — and pre-fills the form with title, author, publisher, year, and cover image. Results are cached locally so subsequent lookups are instant. ISBN is always optional: many Indonesian books from small publishers do not have ISBNs, and the system works fully without one.

**Multiple Collections per Node.** An institution can organize items into multiple named collections within their node — "Koleksi Umum," "Koleksi Referensi," "Koleksi Anak" — each with its own privacy settings, access rules, and catalog display.

**Circulation.** For institutions that lend items to patrons: loan creation with configurable due dates, return processing with automatic fine calculation, fine payment recording, fine waivers, loan history per item and per patron, and overdue reports. Patron records include name, member ID, contact information, registration date, and loan history. Patron records are scoped to one institution — a patron of one school library is not automatically a patron of another.

**Public OPAC.** Every node on Curatorian automatically has a publicly accessible Online Public Access Catalog at `curatorian.id/[node-slug]/catalog`. This page is searchable by title, author, subject, and notes; filterable by collection, language, and availability; shareable with proper social media preview images; and embeddable via iframe in the institution's own website. The public OPAC is the most visible product of using Curatorian — it is what a donor, researcher, or patron sees when they discover the institution online.

**CSV Import.** Institutions migrating from spreadsheets can import their existing catalog via CSV with column mapping and import preview. SLiMS CSV export format is supported with automatic column mapping, reducing the friction of switching from the most common existing tool.

**Visitor Logging.** A simple visitor count for the public OPAC, providing TBM and community libraries with impact data they can share with funders and partner organizations.

**Analytics Dashboard.** Each node has access to a dashboard showing collection statistics, circulation activity, patron numbers, and OPAC visitor counts over time. Simple, honest metrics that answer the questions a library manager or CSR coordinator actually asks.

### 5.2 Community Layer

The professional community features that turn Curatorian from a tool into a platform.

**User Profiles.** Every registered user has a public profile at `curatorian.id/@username` showing their name, bio, institutional affiliation, their public collections, and their community activity. Individual curators showcase their collections here. Professional librarians list their skills and experience. The profile is the user's identity on the platform.

**Organization Profiles.** Every node has a public profile page showing the institution's name, description, location, contact information, and public catalog. This is how a TBM presents itself to the world — a single, shareable URL that contains everything someone needs to know about the collection and how to access it.

**Community Blog.** A publication system where users and institutions can write and publish articles. Intended uses include practical guides (cataloging techniques, preservation basics, copyright for collections), stories from the field (TBM program reports, digitization project journals), professional opinion pieces, and event announcements. This content builds the platform's reputation as a professional resource, attracts organic traffic, and creates reasons to return beyond collection management.

**Follow System.** Users and organizations can follow each other. A new TBM operator can follow an established one to learn from their published experience. A librarian can follow professional associations and peer institutions. The follow graph is visible enough to create connection and discovery, private enough that institutional following does not feel like surveillance.

**Community Messaging.** Direct and group messaging between platform users. Peer support conversations that currently happen through WhatsApp — fragmented, hard to search, lost when a phone changes — can happen in a proper, persistent, searchable environment.

### 5.3 Event & Webinar Platform

A complete event management system for the Indonesian GLAM professional community.

Webinars, workshops, and seminar series are central to GLAM professional development in Indonesia. IPI (Ikatan Pustakawan Indonesia), ATPUSI, university library associations, and TBM networks all run regular events, currently organized through a combination of Google Forms, WhatsApp blasts, and manual attendance sheets. Curatorian provides a native platform for the full event lifecycle.

**For organizers:** Create events with title, description, format (online/offline/hybrid), date, capacity, and price (free or paid). Manage registrations and attendee lists. Conduct QR code check-in at the event. Issue certificates of attendance with verification URLs. Connect their Zoom account via OAuth for automatic meeting creation. View revenue and attendance analytics.

**For attendees:** Browse upcoming events at `curatorian.id/events`. Register with a single form, paying via Midtrans for paid events. Receive a QR code ticket by email. Download a certificate of attendance after the event, with a verification URL (`curatorian.id/verify/[cert-code]`) that can be linked from a CV or LinkedIn profile.

**Platform fee:** 5% of paid event ticket revenue. Free events carry no fee.

### 5.4 Job Board

A dedicated job board for GLAM sector positions in Indonesia.

Fresh Library and Information Science graduates, freelance archivists, and information professionals have no sector-specific job board in Indonesia. LinkedIn is expensive for small institutions to post on and too broad for job seekers to filter effectively. Facebook groups are unstructured and ephemeral. Curatorian, with relevant employers and professionals already present, is the natural home for this function.

**For institutions:** Post positions with full details — title, employment type (full-time/part-time/volunteer/magang), location, salary range, requirements, and application method. For-profit institutions pay a small posting fee; non-profits post for free.

**For job seekers:** Browse and search listings with filters for location, type, and institution category. Apply in-platform or follow an external link, configurable per posting.

**Platform fee:** Rp 75,000 per posting for for-profit institutions. Free for non-profit and community institutions.

### 5.5 Freelance & Expert Marketplace

A matching platform for Indonesian GLAM project work.

Many institutions have collection management needs they cannot address with permanent staff: a cataloging backlog of two thousand unprocessed items, a digitization grant with no in-house technical skills, a collection audit required for an accreditation application. Many qualified professionals — recent LIS graduates, part-time archivists, freelance catalogers — have skills and availability but no channel to find this kind of project work.

The marketplace closes this gap.

**For professionals:** Create a profile listing skills (cataloging, digitization, metadata standards — MARC 21, Dublin Core, RDA — preservation, collection assessment), rates, portfolio, and availability. Offer fixed-price service packages with defined scope and delivery time. Examples: "Katalogisasi 500 buku dengan format standar — Rp 2.500.000, estimasi 2 minggu."

**For institutions:** Browse freelancer profiles and service listings. Post a project request to the request board. Book and pay through the platform with escrow protection — funds are held until the institution confirms satisfactory completion.

**Platform fee:** 10–12% commission on completed engagements. This is the long-term primary revenue engine of the platform — transaction fees compound with network growth in a way that subscription fees do not.

### 5.6 Shared Bibliographic Network

A cross-institutional catalog built from the aggregated records of all opted-in Curatorian nodes.

Once enough institutions are cataloging their collections on Curatorian, the platform itself becomes a bibliographic resource — particularly valuable for Indonesian materials not indexed in international databases: local publishers, regional-language texts, unpublished manuscripts, out-of-print Indonesian titles, community-produced educational materials.

Institutions opt individual items into the network. Opted-in records are aggregated into a searchable cross-institutional index. Any Curatorian user can search across all opted-in collections. Finding a record in the network, a user can copy it to their own collection in one click — pre-filling all available metadata and freeing them from re-entering data that another institution has already captured.

Over time, the Shared Bibliographic Network becomes the most comprehensive Indonesian-language bibliographic database in existence — built by the community, for the community, covering the long tail of Indonesian publishing that no commercial database addresses.

Each shared record credits the originating institution, building community reputation for well-maintained catalog records and giving institutions a visible reason to participate in the network.

### 5.7 Digital Exhibition Builder

A tool for creating and publishing thematic digital exhibitions from a node's collection.

Museums, archives, and libraries communicate their collections most powerfully through curated narrative presentations — exhibitions that tell a story through selected objects, with context and sequence. A collection of batik from various Javanese regions, presented with geographic annotations and historical narrative, is far more engaging than the same items as a raw catalog listing.

Institutions can create exhibitions by selecting items from their collection, arranging them, adding narrative text and per-item captions, and publishing at a dedicated URL. Exhibitions are shareable, embeddable, and live permanently at `curatorian.id/[node-slug]/pameran/[slug]`.

### 5.8 Institutional Crowdfunding

A fundraising tool for community institutions to accept donations or run time-limited campaigns.

TBM and community libraries regularly need community financial support — to buy books, fund reading programs, or cover digitization costs. Currently this happens through informal WhatsApp collections or external platforms that provide no context about the institution's work. A Curatorian crowdfunding page is linked to the institution's catalog and community profile, giving potential donors full context before contributing.

Institutions can maintain a permanent donation page or run campaigns with specific goals, deadlines, and progress tracking. Donors receive a digital supporter badge on their Curatorian profile.

**Platform fee:** 3–5% of funds raised, covering transaction costs.

### 5.9 Reading Program Manager

A structured tool for running, tracking, and reporting on reading programs.

Gerakan Literasi, reading challenges, and book club programs are central to TBM and school library missions. These programs are currently managed through paper sign-up sheets and manual tracking. Curatorian hosts the full program lifecycle: creation, participant enrollment, individual reading logs, progress visualization, completion certificates, and a public program page for reporting to funders and partner organizations.

---

## 6. Technical Architecture

### 6.1 System Design Principles

Every technical decision in Curatorian is guided by five principles.

**Hosted-first.** The entire platform is cloud-hosted. Users never touch a server, install software, or configure a database. This is not a convenience feature — it is the non-negotiable foundation that makes Curatorian accessible to the full range of Indonesian curators.

**GLAM-agnostic core.** The collection model is designed to work equally well for books, museum objects, archive documents, and film reels. The platform does not privilege any one GLAM discipline. An EAV (Entity-Attribute-Value) field system allows institutions to define the exact metadata that their collection type requires.

**Node-scoped data isolation.** Every institution's collection data is scoped to their node. An institution owns their records and can control who sees them. Cross-node sharing (the Shared Bibliographic Network) is always opt-in, never automatic.

**ISBN-optional.** The system works fully without ISBNs. Many Indonesian books from small publishers do not have ISBNs. Any system that requires an ISBN to function fails immediately for a significant portion of Indonesian collections.

**Indonesian-native.** The UI is in Bahasa Indonesia. Dates, currency, and cultural references are native. Payments use Indonesian methods (QRIS, bank transfer). Bibliographic sources include Indonesian-specific databases. This is not a translation of a foreign product — it is built in Indonesia, for Indonesia.

### 6.2 The Three-Layer Architecture

Curatorian is composed of three distinct software layers, each with a defined responsibility and an open/proprietary designation.

```
VOILE (open source, Apache 2.0)
  Compiled Elixir library — the core GLAM engine
  Provides: cataloging, circulation, patron management,
  node management, collection fields, transactions
  Repository: github.com/curatorian/voile
        │
        │  compiled into Curatorian as a mix.exs dependency
        ↓
CURATORIAN (open source)
  Phoenix LiveView application — the public platform
  Port 4000 — auth, community, public OPAC, all read routes
  DB: voile + public schemas
  Repository: github.com/curatorian/curatorian
        │
        │  Phoenix.Token cross-app authentication
        ↓
ATRIUM (proprietary)
  Phoenix LiveView application — the management dashboard
  Port 4001 — collection management, billing, events, marketplace
  DB: atrium schema
  Repository: private
```

**Voile** is the open source GLAM core library. It is a compiled Elixir dependency — not a running server — that provides the data models and business logic for collections, circulation, patron management, and node structure. Anyone can read, fork, and use Voile under Apache 2.0 terms.

**Curatorian** is the public-facing Phoenix application: user authentication, community features (blog, messaging, follow system), public OPAC pages, and all read-only routes. The repository is public. Institutions who want to self-host can do so by running Voile and Curatorian together.

**Atrium** is the proprietary management dashboard: collection management interface, subscription billing, event management, job board, marketplace, and analytics. This is the commercial layer that funds development and sustains operations.

Externally, only the name **Curatorian** exists. Users interact with Curatorian. The internal architecture — Voile and Atrium — is an implementation detail irrelevant to non-developer users.

### 6.3 Database Strategy

Both Curatorian and Atrium share one PostgreSQL database instance (`curatorian_prod`), separated by schemas:

```
curatorian_prod
├── voile schema    — Core GLAM tables
│   ├── users, nodes
│   ├── collections, items, collection_fields
│   ├── lib_transactions, lib_fines, lib_reservations
│   ├── patrons
│   └── mst_* (master/reference data)
│
├── atrium schema   — Platform management tables
│   ├── node_profiles, user_profiles
│   ├── subscriptions, payments, invoices, donations
│   ├── feature_flags, usage_snapshots
│   ├── events, event_registrations, event_certificates
│   ├── job_postings, job_applications
│   ├── freelance_listings, freelance_engagements
│   ├── bibliographic_cache, shared_bibliographic_entries
│   ├── analytics_events, visitor_logs
│   └── notifications, timeline_events
│
└── public schema   — Empty (intentionally unused)
```

Schema separation provides clean logical boundaries: Atrium's `search_path` is set to `atrium,voile,public`, preventing accidental cross-schema queries. Atrium's migrations live in the private Atrium repository and never appear in the public Curatorian repository, preserving the open source boundary at the code level.

No foreign key constraints cross schema boundaries. Cross-schema references are stored as plain `BIGINT` or `UUID` values — clean enough for the data access patterns required, preserving the ability to split into separate databases later if scaling demands it.

High-volume tables — `analytics_events`, `notifications`, `timeline_events` — are partitioned by month from the first deployment. This is a small upfront investment that prevents significant pain at scale.

### 6.4 Authentication & Security

All authentication is handled by Curatorian (port 4000). Atrium (port 4001) never manages login — it verifies identity from a signed token.

**Cross-app authentication flow:**

1. User logs in at Curatorian. Credentials are verified against the `users` table.
2. Curatorian signs a Phoenix.Token containing: `user_id`, `node_id`, `node_name`, `node_slug`, and `roles`.
3. The token is stored in a cookie: `_curatorian_cross_app_token`.
4. When the user accesses Atrium, the token is read from the cookie and verified using the shared `SECRET_KEY_BASE`.
5. A valid token assigns claims to the connection. An expired or tampered token redirects to the Curatorian login page.

Tokens are valid for 24 hours. Both applications use an identical salt (`"cross_app_user_auth"`) and an identical `SECRET_KEY_BASE` — rotating either requires updating both applications simultaneously. All sensitive Atrium queries are scoped by `node_id` or `user_id` from token claims — never by global `Repo.all()` calls.

All user-facing entities use soft deletion (`deleted_at` timestamp) rather than hard deletion. UUID primary keys throughout Atrium. Rate limiting is applied to authentication endpoints before any public launch.

### 6.5 Bibliographic Data Strategy

When a librarian enters or scans an ISBN, Curatorian consults a prioritized chain of sources:

1. **Local bibliographic cache** — instant, no external request
2. **Open Library** — no API key required, broad general coverage
3. **OpenAlex** — no API key required, strong academic coverage
4. **Google Books** — broad popular coverage, key required for high volume
5. **Perpustakaan Nasional catalog** — Indonesian-specific titles
6. **Manual entry** — always available, always the fallback

Results from any external source are cached locally. Once an ISBN has been looked up by any user anywhere on the platform, all subsequent lookups for that ISBN are served from the cache — instant and free.

OpenAlex provides a bulk data dump that can be imported to pre-populate the cache with millions of records before any user ever types an ISBN. This dramatically improves the first-use experience.

The bibliographic cache is a platform-level resource, not per-institution. A record cached by a school library in Bandung is immediately available to a TBM in Surabaya looking up the same book.

### 6.6 Technology Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Language | Elixir 1.17+ / Erlang OTP 27+ | Concurrency, fault tolerance, real-time at scale; BEAM VM runs reliably on minimal hardware |
| Framework | Phoenix 1.7+ / LiveView 1.0+ | Real-time UI without client-side JavaScript framework overhead; exceptionally efficient |
| Database | PostgreSQL 14+ | Robust, full-featured, handles the schema separation strategy cleanly |
| Frontend | Tailwind CSS + DaisyUI | Rapid consistent UI development; Voile Library (light) and Voile Night (dark) themes |
| Deployment | Nevacloud Jakarta / fly.io Singapore | Jakarta for latency; Singapore for Phoenix-native tooling |
| DNS & CDN | Cloudflare | DNS management, DDoS protection, object storage |
| Payments | Midtrans | Indonesian payment gateway with QRIS, bank transfer, e-wallet support |
| Email | Swoosh + Mailgun | Transactional email; free tier covers early stage |
| PDF Generation | ChromicPDF | HTML/CSS-based PDF for certificates, invoices, reports; maximum design control |
| Background Jobs | Oban | Reliable, database-backed async job processing; PDF generation, email, cache warming |
| ISBN Sources | Open Library, OpenAlex, Google Books, Perpusnas | Prioritized chain covering international and Indonesian bibliographic data |
| Image Storage | Cloudflare R2 | S3-compatible object storage for collection item cover images |

The choice of Elixir and Phoenix is intentional and significant. The BEAM virtual machine — the runtime underlying Elixir — is designed for concurrent, fault-tolerant systems. Phoenix LiveView enables real-time, collaborative UI (live catalog search, real-time check-in scanning, live circulation updates) without the complexity of a separate JavaScript frontend. Elixir applications compile to self-contained releases that run efficiently on modest hardware — relevant during early stages and important for any future self-hosted community editions.

---

## 7. Open Source Philosophy

### 7.1 The Open Core Model

Curatorian operates on an open core model — the same model that has sustained projects like GitLab, Plausible Analytics, Matomo, and Metabase. The foundational technology is open source. The commercial layer built on top of it is proprietary.

This is not a compromise between openness and commercial viability. It is a design that serves both simultaneously.

### 7.2 What Is Open and What Is Not

**Open Source (Apache 2.0):**

*Voile* — the core GLAM library. All cataloging data models, circulation logic, patron management, node structure, and collection field definitions. This is the engine that all collection management on Curatorian runs on. It can be used independently in any Elixir application under Apache 2.0 terms. Anyone can contribute, fork, and build on it.

*Curatorian* — the public-facing Phoenix application. Authentication, community features, public OPAC, and all read-only routes. The repository is public on GitHub. Any institution with technical capacity can self-host this application alongside Voile.

**Proprietary:**

*Atrium* — the management dashboard. Collection management UI, subscription billing, event management, job board, marketplace, analytics, and administrative tools. This is the commercial layer that generates revenue, funds development, and sustains the platform as a service. The repository is private.

The boundary is maintained at the code level. Atrium's database migrations live in the private Atrium repository and never appear in the public Curatorian repository, even though both applications share the same PostgreSQL database.

### 7.3 Why This Model Serves Indonesian GLAM

**Trust and freedom from vendor lock-in.** Indonesian institutions — particularly those that have been burned by software projects that disappear — are rightly cautious about depending on proprietary systems. An open source core means their catalog data is always accessible, the data model is documented, and they can migrate to a self-hosted configuration if circumstances change. This trust is not rhetorical. It is structural and verifiable.

**Genuinely free for community.** The free tier is not a crippled demo. Voile and Curatorian together provide a complete, functional collection management system that any institution can self-host at zero cost. When Curatorian offers this functionality as a hosted service for free, it is offering genuine value, not a marketing hook. This is how community trust is built.

**Developer community.** Open source attracts contributors. A librarian-developer who builds something on top of Voile improves the platform for every institution that uses it. A university computer science faculty that assigns Voile contributions as a project adds features without direct cost to the core team. Community contributions reduce the solo development burden over time and build the kind of diverse, distributed expertise that makes software robust.

**Sustainability through the commercial layer.** The proprietary Atrium funds the development of the open source Voile and Curatorian. This is a virtuous cycle: the more valuable the open source core becomes, the more attractive the hosted commercial layer is; the more successful the commercial layer, the more resources available to invest in the open source foundation.

---

## 8. Business Model & Sustainability

### 8.1 Philosophy

The business model reflects a specific belief about what kind of institution Curatorian needs to be to succeed in the Indonesian GLAM community.

The Indonesian library and GLAM community trusts tools built by practitioners, adopted freely, and sustained honestly. It is appropriately suspicious of aggressive commercial practices, opaque pricing, and foreign platforms that have no genuine investment in the Indonesian context. Curatorian earns trust by giving genuine value first, by charging only those with commercial means, and by being transparent about how it sustains itself.

This is not philanthropy. It is a commercial strategy that treats community trust as the primary asset and builds financial sustainability on top of it. Community trust, once earned, is very difficult for a competitor to replicate by simply offering a lower price.

### 8.2 Pricing Tiers

| Tier | Price | Who It Serves |
|------|-------|---------------|
| **Komunitas** | Free, permanently | Individual collectors, TBM, community libraries, non-profit institutions, school libraries |
| **Institusi** | Rp 150,000–250,000/month | For-profit businesses, commercial institutions, corporations with CSR libraries, private enterprises |

**Non-profit verification** is handled by self-declaration with a simple form. The platform does not aggressively gate access or demand documentation. The vast majority of TBM and community institutions genuinely qualify, and making a false declaration carries reputational risk in a community where people know each other. Trust first, enforcement when necessary.

### 8.3 Revenue Streams

**1. Institusi Subscriptions**
The foundational revenue stream. Monthly subscriptions from for-profit institutions provide the baseline that covers hosting and operational costs. At Rp 150,000–250,000 per month, the commitment is easily justifiable against the time saved in collection management and the compliance value delivered for CSR-obligated institutions.

**2. Voluntary Donations**
Free-tier users who find genuine value can contribute voluntarily at any amount. Donation prompts appear at natural moments: post-signup, after generating a report or certificate, and on the About page. No guilt, no pressure, no feature restrictions for non-donors. Donations are framed honestly: "Curatorian gratis dan akan tetap gratis. Kalau mau bantu operasional, boleh donasi seiklasnya."

**3. Event Platform Fees**
5% of paid event ticket revenue. Free events carry no fee. Organizers use their own Zoom accounts; Curatorian provides registration, ticketing, and certificate infrastructure.

**4. Job Board Posting Fees**
Rp 75,000 per posting for for-profit institutions. Free for non-profit and community institutions. A small, recurring revenue stream from active hiring institutions.

**5. Freelance Marketplace Commission**
10–12% commission on completed freelance engagements, processed through Midtrans escrow. This is the highest-potential revenue stream because it scales with the volume and total value of work facilitated, not just with the count of subscribing institutions. A mature marketplace with hundreds of active engagements per month generates significant revenue at no additional infrastructure cost.

**6. Crowdfunding Platform Fee**
3–5% of funds raised through institutional donation campaigns. Covers transaction costs and contributes to platform operations.

### 8.4 The Path to Sustainability

**Phase 1 — Donation-Based (Launch through Month 6).**
All features free. Operations funded by voluntary donations. The goal of this phase is community trust, not revenue. Getting 50 active nodes using the platform with genuine satisfaction is more valuable at this stage than getting five paying customers through aggressive marketing. Social proof within the GLAM community is the most powerful commercial signal available.

**Phase 2 — Freemium (Month 4–8).**
Institusi paid tier introduced once 50+ active free nodes demonstrate the platform delivers real value. Event and job board fees begin as those features launch. The community by this point is large enough that new commercial users see an active, legitimate platform, not a ghost town.

**Phase 3 — Marketplace (Month 9+).**
Freelance marketplace commissions become the primary revenue source. Subscription revenue continues to grow linearly. Marketplace revenue grows with network activity — faster than linear at scale. At this point the platform is self-sustaining and can invest in growth and deeper features.

**Break-even target: Month 3.**
Initial donations combined with the first two or three commercial subscribers are expected to cover hosting costs by Month 3. The platform is designed to reach operational sustainability before requiring any significant outside funding.

---

## 9. Competitive Landscape

### The Tools People Use Today

**SLiMS (Senayan Library Management System)** is the dominant existing solution in Indonesian school and academic libraries. It is genuinely functional, free, and well-known in the librarian community. Its critical limitation is that it requires self-hosting: a web server, MySQL, and PHP installation. For the majority of Indonesian community institutions, this barrier is insurmountable. SLiMS has no cloud version, no community platform, and no public discovery mechanism for collections. Curatorian is not competing to replace SLiMS in institutions where SLiMS works — it is serving the far larger population of institutions where SLiMS was never an option.

**Foreign SaaS platforms** (LibraryThing, TinyCat, Koha Cloud) serve their markets well. They are priced in USD, primarily in English, designed for Western cataloging conventions, and built without Indonesian context. They will not build local payment support, Bahasa Indonesia interfaces, or community features for Indonesian GLAM practitioners. The market they serve and the market Curatorian serves barely overlap.

**PoMS and similar newer tools** are legitimate alternatives for basic cataloging in some segments. The response to this competition is not a feature race — it is the platform depth that a pure catalog tool cannot become. A community with events, a job board, a freelance marketplace, and a shared bibliographic network creates switching costs that go far beyond data migration.

**Spreadsheets and WhatsApp groups** are the actual status quo for most Indonesian small collections. They are the product Curatorian most needs to displace. The approach is not to criticize them but to make the transition from them as frictionless as possible: CSV import handles existing spreadsheet data, and the onboarding flow delivers a working public catalog in thirty minutes.

### The Strategic Moat

Individual features can be replicated. Three things cannot be replicated without years of community building:

**1. The Shared Bibliographic Network.** As more institutions catalog their collections on Curatorian, the network's value grows for everyone. A competitor starting today would need to build both the platform and the catalog simultaneously. Curatorian builds the catalog as a byproduct of building the community.

**2. The community itself.** An active blog, event calendar, job board, and follow network creates reasons to be present on the platform that have nothing to do with catalog management. Switching away means leaving a professional community, not just migrating a database.

**3. Domain expertise embedded in the product.** A practicing librarian building this platform makes decisions that purely technical builders miss. This expertise is not a marketing claim — it shows in every feature choice, every metadata field, every piece of UI copy. It cannot be quickly acquired by a competitor who decides to enter this market.

---

## 10. Roadmap

The roadmap below describes what is being built, in what order, and why. Features are built only when demand signals are confirmed — either because they are foundational to the platform, or because real users have asked for them. This discipline is not a limitation of ambition but a protection against the common failure mode of building for hypothetical users.

### 10.1 Phase 1 — Foundation (2026, Q1–Q2)

**Status: In progress.**

The goal of this phase is to complete the minimum viable platform: any curator can sign up, catalog their collection, and have a working public page. Everything in this phase is blocked by something a real user will encounter within their first thirty minutes.

**Collection management** — Full create-read-update-delete workflow for items through the Atrium dashboard, including ISBN lookup, cover images, flexible metadata fields, and collection organization.

**Circulation and patron management** — Loan tracking, return processing, fine management, and patron records for institutions that lend to patrons.

**Public OPAC** — Publicly accessible catalog page per node, searchable, shareable, and embeddable.

**Subscription infrastructure** — Midtrans payment integration, subscription tiers, feature flags, invoice generation, and voluntary donation flow.

**Infrastructure** — Deployment to a Jakarta-region VPS with automated daily backups, rate limiting on authentication endpoints, and error monitoring.

**End of Phase 1 deliverable:** A TBM operator in Bandung can sign up during a lunch break, catalog their first ten books, and share a working public catalog page with their community before the break ends.

### 10.2 Phase 2 — Community Launch (2026, Q2–Q3)

**Goal: 50+ active nodes, genuine community activity.**

**Onboarding flow** — Post-signup wizard, empty state designs, first-week email sequence. Every new node gets a personal welcome from the founder.

**CSV import** — Migration from spreadsheets with column mapping, import preview, and SLiMS format compatibility.

**Analytics per node** — Usage dashboard and exportable summary reports for accreditation and donor reporting.

**Institusi paid tier** — Launched when 50+ active free nodes demonstrate platform value. Clear feature comparison, upgrade flow, and founder-led onboarding for first commercial subscribers.

**Community content** — Weekly publication on the Curatorian blog, personal outreach to librarian and TBM networks in West Java, engagement in Indonesian librarian Facebook groups and Telegram channels.

### 10.3 Phase 3 — Platform Expansion (2026, Q3–Q4)

**Goal: 100+ active nodes, first SaaS platform features beyond collection management.**

Features in this phase are demand-gated — built when specific user demand is confirmed, in the order that demand arrives.

**Event and webinar platform** — If 3+ users request it by name. Complete event lifecycle management with ticketing, QR check-in, certificate generation and verification, and Zoom integration.

**Job board** — If 3+ users request it by name. GLAM sector job listings with in-platform application, posting fees for commercial institutions, and free posting for non-profits.

**Shared bibliographic network** — When 10+ active nodes and 5+ opted into sharing. Cross-institutional catalog search and one-click copy cataloging.

### 10.4 Phase 4 — Marketplace & Depth (2027)

**Goal: 200+ active nodes, first marketplace revenue, platform self-sustaining.**

**Freelance marketplace** — When 5+ organic freelancer profiles exist and 3+ institutions have posted project requests. Full escrow, matching, completion confirmation, and rating system.

**Digital exhibition builder** — When museum and gallery nodes become active. Thematic exhibition creation and publication.

**Institutional crowdfunding** — When TBM network is active and any institution requests it. Donation campaigns and progress tracking.

**Reading program manager** — When TBM or school nodes request it. Program creation, reading logs, progress visualization, and completion certificates.

**Inter-library loan coordination** — When 50+ institutional nodes are in the same region and express interest.

**API access** — Third-party integration access for commercial subscribers.

**Regional expansion research** — When the platform is stable, profitable, and has demonstrated the Indonesian model. Malaysia and the Philippines are the logical next markets given language proximity and similar GLAM sector characteristics.

---

## 11. Join the Movement

Curatorian is built in public, with public documentation, on open source foundations. The platform is stronger with more perspectives, more contributions, and more people who care about the same problem.

### If You Are a Curator or GLAM Professional

Sign up at `curatorian.id`. Create your node. Catalog your first item. Share your collection. Write something for the community blog. Follow other curators who are doing interesting work. Tell us what you need that the platform does not yet provide — every product decision is shaped by real user input.

### If You Are a Developer

The Voile core library and Curatorian frontend are open source repositories on GitHub. If you work in Elixir, Phoenix, or PostgreSQL and care about Indonesian cultural heritage, we welcome contributions. Start with the issue tracker. Read the technical documentation. Open a PR. The platform is better for every skilled person who engages with it.

### If You Are a Designer

The Curatorian design system — Voile Library (light) and Voile Night (dark) — is documented and uses a CSS custom property system that makes contribution tractable. If you design in Figma or have opinions about accessible, scholarly, warm UI design for the Indonesian market, get in touch.

### If You Are an Educator or Researcher

Library and information science faculty, researchers in digital humanities, and educators working in the GLAM sector are natural partners. Whether through student project contributions, research collaboration, or institutional adoption, there is a path for academic engagement. We are particularly interested in research on the impact of community cataloging platforms on information access in underserved Indonesian communities.

### If You Represent an Institution or Organization

If your institution maintains a collection — regardless of size, type, or budget — Curatorian is built for you. For non-profit and community institutions, the platform is and will remain free. For commercial institutions, the subscription cost is designed to be justifiable on any realistic library operational budget.

If your organization works in the GLAM sector in Indonesia — professional associations (IPI, ATPUSI), government agencies (Perpustakaan Nasional, Dinas Perpustakaan), NGOs working on literacy and cultural heritage, or corporate partners interested in CSR and digital preservation — we welcome conversations about collaboration and partnership.

---

## Contact

**Platform:** curatorian.id
**Email:** hello@curatorian.id
**Voile repository:** github.com/curatorian/voile
**Curatorian repository:** github.com/curatorian/curatorian

---

*This whitepaper is published under Creative Commons CC BY 4.0. You are free to share and adapt it with attribution. Last updated: March 2026.*

*Curatorian is an ongoing project. This document reflects the platform as it exists and as it is planned. Feedback, corrections, and contributions to this document are welcome at hello@curatorian.id.*
