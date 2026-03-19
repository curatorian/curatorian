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

IO.puts(
  "Seeded: app_name, app_description, contact, website, address, logo, storage_adapter, and theme colors."
)
