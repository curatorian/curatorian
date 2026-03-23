# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Voile.Repo.insert!(%Voile.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Voile.Schema.Metadata

# Populate the Vocabulary
vocab = [
  %{
    namespace_url: "http://purl.org/dc/terms/",
    prefix: "dcterms",
    label: "Dublin Core",
    information: "Basic resource metadata (DCMI Metadata Terms)"
  },
  %{
    namespace_url: "http://purl.org/dc/dcmitype/",
    prefix: "dctype",
    label: "Dublin Core Type",
    information: "Basic resource types (DCMI Type Vocabulary)"
  },
  %{
    namespace_url: "http://purl.org/ontology/bibo/",
    prefix: "bibo",
    label: "Bibliographic Ontology",
    information: "Bibliographic metadata (BIBO)"
  },
  %{
    namespace_url: "http://xmlns.com/foaf/0.1/",
    prefix: "foaf",
    label: "Friend of a Friend",
    information: "Relationships between people and organizations (FOAF)"
  },
  %{
    namespace_url: "https://kandaga.unpad.ac.id/vocab/book/",
    prefix: "slims_book",
    label: "SLiMS Book Vocabulary",
    information: "Vocabulary for Senayan Library Management System book metadata"
  },

  # ── Gallery ─────────────────────────────────────────────────────────────────
  %{
    namespace_url: "http://www.vraweb.org/vracore/vracore4#",
    prefix: "vra",
    label: "VRA Core 4.0",
    information: "Visual Resources Association Core Categories — three-entity model (Work, Image, Collection) for visual art resources. Library of Congress."
  },
  %{
    namespace_url: "http://www.getty.edu/CDWA/CDWALite/",
    prefix: "cdwalite",
    label: "CDWA Lite",
    information: "Categories for the Description of Works of Art (Lite subset) — OAI-PMH XML schema for art objects. Getty Research Institute."
  },
  %{
    namespace_url: "http://www.w3.org/2003/12/exif/ns#",
    prefix: "exif",
    label: "EXIF",
    information: "Exchangeable Image File Format — technical metadata embedded in image files (ISO 12234-2)."
  },
  %{
    namespace_url: "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/",
    prefix: "iptc",
    label: "IPTC Photo Metadata",
    information: "IPTC Core — descriptive and rights metadata for photographic images. International Press Telecommunications Council."
  },
  %{
    namespace_url: "http://ns.adobe.com/xap/1.0/",
    prefix: "xmp",
    label: "XMP",
    information: "Adobe Extensible Metadata Platform — extensible metadata embedded in digital files. Includes xmpRights and xmpMM sub-namespaces."
  },
  %{
    namespace_url: "https://schema.org/",
    prefix: "schema",
    label: "Schema.org",
    information: "Schema.org vocabulary — structured data for web discoverability (JSON-LD / Microdata). Covers CreativeWork, VisualArtwork, Book, ArchiveComponent, Museum, etc."
  },

  # ── Library ─────────────────────────────────────────────────────────────────
  %{
    namespace_url: "http://www.loc.gov/MARC21/slim#",
    prefix: "marc21",
    label: "MARC 21",
    information: "Machine-Readable Cataloging — primary library catalogue interchange format. Library of Congress."
  },
  %{
    namespace_url: "http://www.loc.gov/mods/v3#",
    prefix: "mods",
    label: "MODS 3.x",
    information: "Metadata Object Description Schema — XML-based, MARC-derived library metadata. Widely used in institutional repositories. Library of Congress."
  },
  %{
    namespace_url: "http://id.loc.gov/ontologies/bibframe/",
    prefix: "bf",
    label: "BIBFRAME 2.0",
    information: "Bibliographic Framework — RDF/Linked Data replacement for MARC modelling Work → Instance → Item. Library of Congress."
  },
  %{
    namespace_url: "http://www.loc.gov/METS/",
    prefix: "mets",
    label: "METS",
    information: "Metadata Encoding and Transmission Standard — XML container for packaging digital objects with descriptive, administrative and structural metadata. Library of Congress."
  },
  %{
    namespace_url: "http://ns.editeur.org/onix/3.0/reference#",
    prefix: "onix",
    label: "ONIX 3.0",
    information: "Online Information eXchange — book supply-chain metadata standard. EDItEUR. Useful for acquisition and e-resource workflows."
  },

  # ── Archive ─────────────────────────────────────────────────────────────────
  %{
    namespace_url: "http://www.archiveshub.ac.uk/isadg/",
    prefix: "isadg",
    label: "ISAD(G)",
    information: "General International Standard Archival Description (2nd ed.) — hierarchical description Fonds → Series → File → Item. International Council on Archives."
  },
  %{
    namespace_url: "http://ead3.archivists.org/schema/#",
    prefix: "ead",
    label: "EAD 3",
    information: "Encoded Archival Description — XML finding aid standard implementing ISAD(G). Society of American Archivists / Library of Congress."
  },
  %{
    namespace_url: "http://www.archivists.org/ns/eac-cpf#",
    prefix: "eaccpf",
    label: "EAC-CPF 2.0",
    information: "Encoded Archival Context — Corporate bodies, Persons, Families. Authority records for archival agents. ICA / SAA."
  },
  %{
    namespace_url: "https://www.ica.org/standards/RiC/ontology#",
    prefix: "ric",
    label: "Records in Contexts (RiC)",
    information: "Next-generation archival description standard — OWL Linked Data ontology superseding ISAD(G), ISAAR(CPF), ISDF, ISDIAH. ICA 2023."
  },
  %{
    namespace_url: "http://www.loc.gov/premis/rdf/v3/",
    prefix: "premis",
    label: "PREMIS 3.0",
    information: "PREservation Metadata: Implementation Strategies — standard for digital preservation metadata (objects, events, agents, rights). Library of Congress."
  },
  %{
    namespace_url: "http://www.archiveshub.ac.uk/isaar/",
    prefix: "isaar",
    label: "ISAAR(CPF)",
    information: "International Standard Archival Authority Record for Corporate bodies, Persons, Families (2nd ed.). ICA. Still widely used in AtoM software."
  },

  # ── Museum ──────────────────────────────────────────────────────────────────
  %{
    namespace_url: "http://www.cidoc-crm.org/cidoc-crm/",
    prefix: "crm",
    label: "CIDOC CRM",
    information: "Conceptual Reference Model for Cultural Heritage Documentation (ISO 21127) — semantic backbone for CH Linked Data. ICOM-CIDOC."
  },
  %{
    namespace_url: "http://www.collectionstrust.org.uk/spectrum/",
    prefix: "spectrum",
    label: "SPECTRUM 5.1",
    information: "UK Museum Collections Management Standard — 21 collection management procedures and object information groups. Collections Trust."
  },
  %{
    namespace_url: "http://www.lido-schema.org/schema/v1.0/lido-v1.0#",
    prefix: "lido",
    label: "LIDO 1.1",
    information: "Lightweight Information Describing Objects — XML interchange format for museum objects used by Europeana and national CH aggregators. ICOM-CIDOC."
  },
  %{
    namespace_url: "https://www.object-id.com/vocab/",
    prefix: "objectid",
    label: "ICOM Object ID",
    information: "Standard for documenting cultural objects to prevent theft and aid recovery. 9 minimum categories. ICOM / Interpol."
  },

  # ── Cross-Domain (aggregation / vocabulary / linked data) ───────────────────
  %{
    namespace_url: "http://www.europeana.eu/schemas/edm/",
    prefix: "edm",
    label: "Europeana Data Model (EDM)",
    information: "Europeana Data Model — aggregation model for CH portals, wrapping DC and CIDOC CRM into Linked Data. Europeana Foundation."
  },
  %{
    namespace_url: "http://www.w3.org/2004/02/skos/core#",
    prefix: "skos",
    label: "SKOS",
    information: "Simple Knowledge Organization System — W3C standard for controlled vocabularies, thesauri and classification schemes (AAT, LCSH, TGN)."
  },
  %{
    namespace_url: "http://iiif.io/api/presentation/3#",
    prefix: "iiif",
    label: "IIIF Presentation API 3",
    information: "International Image Interoperability Framework Presentation API — Manifest model for image delivery and viewer interoperability across GLAM."
  }
]

for vocabulary <- vocab do
  Metadata.create_vocabulary(vocabulary)
end

# Populate the Node List
node_list = [
  %{
    name: "Curatorian",
    abbr: "curatorian",
    description: nil,
    image: nil
  }
]

for node <- node_list do
  case Voile.Repo.get_by(Voile.Schema.System.Node, name: node.name) do
    nil -> Voile.Schema.System.create_node(node)
    _existing -> IO.puts("Node #{node.name} already exists, skipping...")
  end
end

## NOTE: The main `mix ecto.setup` alias runs multiple seed scripts in a specific order
## (see `mix.exs` "ecto.setup" alias). Avoid requiring/ executing large seed files
## here so the Mix alias can control ordering. The following seeds are run by the
## alias in the desired order: master.exs, metadata_resource_class.exs,
## metadata_properties.exs, glams.exs.

IO.puts(
  "Seeds: core vocabulary and nodes loaded. Other seed scripts will be run by the `ecto.setup` alias in mix.exs."
)

## Application profile & theme defaults (Patchouli-inspired)
## These defaults will be upserted into the `settings` table so the
## application picks up a sensible identity and runtime theme on first run.

alias Voile.Schema.System

IO.puts("Seeding default application profile and theme...")

# App identity
System.upsert_setting("app_name", "Curatorian")

System.upsert_setting(
  "app_description",
  "A gentle digital sanctuary for libraries, museums, and archives — curated for discovery and wonder."
)

System.upsert_setting("app_contact_email", "chrisnaadhip@gmail.com")
System.upsert_setting("app_website", "https://curatorian.id")
System.upsert_setting("app_address", "Curatorian Network")

# Logo (default to packaged icon)
System.upsert_setting("app_logo_url", "/images/v.png")

# Storage adapter default
System.upsert_setting("storage_adapter", "local")

# Theme colors (Patchouli-inspired)
# Primary: deep violet — good for primary buttons, icons, and strong accents
System.upsert_setting("app_main_color", "#6B21A8")
# Secondary: soft lavender for accents and highlights
System.upsert_setting("app_secondary_color", "#A78BFA")
# Surface: very light violet for surfaces (panels, cards)
System.upsert_setting("app_surface_color", "#F6F3FF")
# Surface variant: slightly darker surface for active tabs/badges
System.upsert_setting("app_surface_variant", "#EFE9FF")
# Surface dark (for dark mode surfaces)
System.upsert_setting("app_surface_dark", "#0F0820")
# Accent / highlight
System.upsert_setting("app_accent_color", "#C4B5FD")

System.upsert_setting("app_email", "curatorian@proton.me")
System.upsert_setting("app_instagram_url", "https://instagram.com/curatorian_id")
System.upsert_setting("app_contact_number", "081573710645")

IO.puts(
  "Seeded: app_name, app_description, contact, website, address, logo, storage_adapter, and theme colors."
)
