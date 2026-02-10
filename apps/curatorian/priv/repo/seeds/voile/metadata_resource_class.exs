alias Voile.Repo
alias Voile.Schema.Metadata
alias Voile.Schema.Metadata.ResourceClass

vocabulary_1 = Repo.get!(Metadata.Vocabulary, 1)
vocabulary_2 = Repo.get!(Metadata.Vocabulary, 2)
vocabulary_3 = Repo.get!(Metadata.Vocabulary, 3)
vocabulary_4 = Repo.get!(Metadata.Vocabulary, 4)

resource_class = [
  %{
    information: "A resource that acts or has the power to act.",
    label: "Agent",
    local_name: "Agent",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "A group of agents.",
    label: "Agent Class",
    local_name: "AgentClass",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "A book, article, or other documentary resource.",
    label: "Bibliographic Resource",
    local_name: "BibliographicResource",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "A digital resource format.",
    label: "File Format",
    local_name: "FileFormat",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A rate at which something recurs.",
    label: "Frequency",
    local_name: "Frequency",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "The extent or range of judicial, law enforcement, or other authority.",
    label: "Jurisdiction",
    local_name: "Jurisdiction",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A legal document giving official permission to do something with a Resource.",
    label: "License Document",
    local_name: "LicenseDocument",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A system of signs, symbols, sounds, gestures, or rules used in communication.",
    label: "Linguistic System",
    local_name: "LinguisticSystem",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "A spatial region or named place.",
    label: "Location",
    local_name: "Location",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A location, period of time, or jurisdiction.",
    label: "Location, Period or Jurisdiction",
    local_name: "LocationPeriodOrJurisdiction",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A file format or physical medium.",
    label: "Media Type",
    local_name: "MediaType",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A media type or extent.",
    label: "Media Type or Extent",
    local_name: "MediaTypeOrExtent",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A process that is used to engender knowledge, attitudes, and skills.",
    label: "Method of Instruction",
    local_name: "MethodOfInstruction",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "A method by which resources are added to a collection.",
    label: "Method of Accrual",
    local_name: "MethodOfAccrual",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "An interval of time that is named or defined by its start and end dates.",
    label: "Period of Time",
    local_name: "PeriodOfTime",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A physical material or carrier.",
    label: "Physical Medium",
    local_name: "PhysicalMedium",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Museum"
  },
  %{
    information: "A material thing.",
    label: "Physical Resource",
    local_name: "PhysicalResource",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Museum"
  },
  %{
    information:
      "A plan or course of action by an authority, intended to influence and determine decisions, actions, and other matters.",
    label: "Policy",
    local_name: "Policy",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information:
      "A statement of any changes in ownership and custody of a resource since its creation that are significant for its authenticity, integrity, and interpretation.",
    label: "Provenance Statement",
    local_name: "ProvenanceStatement",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information:
      "A statement about the intellectual property rights (IPR) held in or over a Resource, a legal document giving official permission to do something with a resource, or a statement about access rights.",
    label: "Rights Statement",
    local_name: "RightsStatement",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Archive"
  },
  %{
    information: "A dimension or extent, or a time taken to play or execute.",
    label: "Size or Duration",
    local_name: "SizeOrDuration",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information:
      "A basis for comparison; a reference point against which other things can be evaluated.",
    label: "Standard",
    local_name: "Standard",
    owner_id: nil,
    vocabulary_id: 1,
    glam_type: "Library"
  },
  %{
    information: "An aggregation of resources.",
    label: "Collection",
    local_name: "Collection",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "Data encoded in a defined structure.",
    label: "Dataset",
    local_name: "Dataset",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "A non-persistent, time-based occurrence.",
    label: "Event",
    local_name: "Event",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "A visual representation other than text.",
    label: "Image",
    local_name: "Image",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Gallery"
  },
  %{
    information:
      "A resource requiring interaction from the user to be understood, executed, or experienced.",
    label: "Interactive Resource",
    local_name: "InteractiveResource",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Museum"
  },
  %{
    information: "A system that provides one or more functions.",
    label: "Service",
    local_name: "Service",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "A computer program in source or compiled form.",
    label: "Software",
    local_name: "Software",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "A resource primarily intended to be heard.",
    label: "Sound",
    local_name: "Sound",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Archive"
  },
  %{
    information: "A resource consisting primarily of words for reading.",
    label: "Text",
    local_name: "Text",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Library"
  },
  %{
    information: "An inanimate, three-dimensional object or substance.",
    label: "Physical Object",
    local_name: "PhysicalObject",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Museum"
  },
  %{
    information: "A static visual representation.",
    label: "Still Image",
    local_name: "StillImage",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Gallery"
  },
  %{
    information:
      "A series of visual representations imparting an impression of motion when shown in succession.",
    label: "Moving Image",
    local_name: "MovingImage",
    owner_id: nil,
    vocabulary_id: 2,
    glam_type: "Gallery"
  },
  %{
    information: "A scholarly academic article, typically published in a journal.",
    label: "Academic Article",
    local_name: "AcademicArticle",
    owner_id: nil,
    vocabulary_id: 3,
    glam_type: "Library"
  },
  %{
    information:
      "A written composition in prose, usually nonfiction, on a specific topic, forming an independent part of a book or other publication, as a newspaper or magazine.",
    label: "Article",
    local_name: "Article",
    owner_id: nil,
    vocabulary_id: 3,
    glam_type: "Library"
  }
]

for resource <- resource_class do
  # Check if resource class already exists by local_name
  case Repo.get_by(ResourceClass, local_name: resource[:local_name]) do
    nil ->
      %ResourceClass{
        label: resource[:label],
        local_name: resource[:local_name],
        information: resource[:information],
        glam_type: resource[:glam_type],
        vocabulary_id:
          case resource[:vocabulary_id] do
            1 -> vocabulary_1.id
            2 -> vocabulary_2.id
            3 -> vocabulary_3.id
            4 -> vocabulary_4.id
            _ -> 1
          end
      }
      |> Repo.insert!()

    _existing ->
      # Resource class already exists, skip
      :ok
  end
end
