alias Voile.Repo
alias Voile.Schema.Metadata
alias Voile.Schema.Metadata.Property

vocabulary_1 = Repo.get!(Metadata.Vocabulary, 1)
vocabulary_2 = Repo.get!(Metadata.Vocabulary, 2)
vocabulary_3 = Repo.get!(Metadata.Vocabulary, 3)
vocabulary_4 = Repo.get!(Metadata.Vocabulary, 4)
vocabulary_5 = Repo.get!(Metadata.Vocabulary, 5)

properties_list = [
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "title",
    label: "Title",
    comment: "A name given to the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "creator",
    label: "Creator",
    comment: "An entity primarily responsible for making the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "subject",
    label: "Subject",
    comment: "The topic of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "description",
    label: "Description",
    comment: "An account of the resource.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "publisher",
    label: "Publisher",
    comment: "An entity responsible for making the resource available.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "contributor",
    label: "Contributor",
    comment: "An entity responsible for making contributions to the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "date",
    label: "Date",
    comment:
      "A point or period of time associated with an event in the lifecycle of the resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "type",
    label: "Type",
    comment: "The nature or genre of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "format",
    label: "Format",
    comment: "The file format, physical medium, or dimensions of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "identifier",
    label: "Identifier",
    comment: "An unambiguous reference to the resource within a given context.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "source",
    label: "Source",
    comment: "A related resource from which the described resource is derived.",
    type_value: "url"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "language",
    label: "Language",
    comment: "A language of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "relation",
    label: "Relation",
    comment: "A related resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "coverage",
    label: "Coverage",
    comment:
      "The spatial or temporal topic of the resource, the spatial applicability of the resource, or the jurisdiction under which the resource is relevant.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "rights",
    label: "Rights",
    comment: "Information about rights held in and over the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "audience",
    label: "Audience",
    comment: "A class of entity for whom the resource is intended or useful.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "alternative",
    label: "Alternative Title",
    comment: "An alternative name for the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "tableOfContents",
    label: "Table Of Contents",
    comment: "A list of subunits of the resource.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "abstract",
    label: "Abstract",
    comment: "A summary of the resource.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "created",
    label: "Date Created",
    comment: "Date of creation of the resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "valid",
    label: "Date Valid",
    comment: "Date (often a range) of validity of a resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "available",
    label: "Date Available",
    comment: "Date (often a range) that the resource became or will become available.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "issued",
    label: "Date Issued",
    comment: "Date of formal issuance (e.g., publication) of the resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "modified",
    label: "Date Modified",
    comment: "Date on which the resource was changed.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "extent",
    label: "Extent",
    comment: "The size or duration of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "medium",
    label: "Medium",
    comment: "The material or physical carrier of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isVersionOf",
    label: "Is Version Of",
    comment:
      "A related resource of which the described resource is a version, edition, or adaptation.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "hasVersion",
    label: "Has Version",
    comment:
      "A related resource that is a version, edition, or adaptation of the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isReplacedBy",
    label: "Is Replaced By",
    comment:
      "A related resource that supplants, displaces, or supersedes the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "replaces",
    label: "Replaces",
    comment:
      "A related resource that is supplanted, displaced, or superseded by the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isRequiredBy",
    label: "Is Required By",
    comment:
      "A related resource that requires the described resource to support its function, delivery, or coherence.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "requires",
    label: "Requires",
    comment:
      "A related resource that is required by the described resource to support its function, delivery, or coherence.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isPartOf",
    label: "Is Part Of",
    comment:
      "A related resource in which the described resource is physically or logically included.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "hasPart",
    label: "Has Part",
    comment:
      "A related resource that is included either physically or logically in the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isReferencedBy",
    label: "Is Referenced By",
    comment:
      "A related resource that references, cites, or otherwise points to the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "references",
    label: "References",
    comment:
      "A related resource that is referenced, cited, or otherwise pointed to by the described resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "isFormatOf",
    label: "Is Format Of",
    comment:
      "A related resource that is substantially the same as the described resource, but in another format.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "hasFormat",
    label: "Has Format",
    comment:
      "A related resource that is substantially the same as the pre-existing described resource, but in another format.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "conformsTo",
    label: "Conforms To",
    comment: "An established standard to which the described resource conforms.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "spatial",
    label: "Spatial Coverage",
    comment: "Spatial characteristics of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "temporal",
    label: "Temporal Coverage",
    comment: "Temporal characteristics of the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "mediator",
    label: "Mediator",
    comment:
      "An entity that mediates access to the resource and for whom the resource is intended or useful.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "dateAccepted",
    label: "Date Accepted",
    comment: "Date of acceptance of the resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "dateCopyrighted",
    label: "Date Copyrighted",
    comment: "Date of copyright.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "dateSubmitted",
    label: "Date Submitted",
    comment: "Date of submission of the resource.",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "educationLevel",
    label: "Audience Education Level",
    comment:
      "A class of entity, defined in terms of progression through an educational or training context, for which the described resource is intended.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "accessRights",
    label: "Access Rights",
    comment:
      "Information about who can access the resource or an indication of its security status.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "bibliographicCitation",
    label: "Bibliographic Citation",
    comment: "A bibliographic reference for the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "license",
    label: "License",
    comment: "A legal document giving official permission to do something with the resource.",
    type_value: "url"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "rightsHolder",
    label: "Rights Holder",
    comment: "A person or organization owning or managing rights over the resource.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "provenance",
    label: "Provenance",
    comment:
      "A statement of any changes in ownership and custody of the resource since its creation that are significant for its authenticity, integrity, and interpretation.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "instructionalMethod",
    label: "Instructional Method",
    comment:
      "A process, used to engender knowledge, attitudes and skills, that the described resource is designed to support.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "accrualMethod",
    label: "Accrual Method",
    comment: "The method by which items are added to a collection.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "accrualPeriodicity",
    label: "Accrual Periodicity",
    comment: "The frequency with which items are added to a collection.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 1,
    local_name: "accrualPolicy",
    label: "Accrual Policy",
    comment: "The policy governing the addition of items to a collection.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "affirmedBy",
    label: "affirmedBy",
    comment: "A legal decision that affirms a ruling.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "annotates",
    label: "annotates",
    comment: "Critical or explanatory note for a Document.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "authorList",
    label: "list of authors",
    comment:
      "An ordered list of authors. Normally, this list is seen as a priority list that order authors by importance.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "citedBy",
    label: "cited by",
    comment: "Relates a document to another document that cites the\nfirst document.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "cites",
    label: "cites",
    comment:
      "Relates a document to another document that is cited\nby the first document as reference, comment, review, quotation or for\nanother purpose.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "contributorList",
    label: "list of contributors",
    comment:
      "An ordered list of contributors. Normally, this list is seen as a priority list that order contributors by importance.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "court",
    label: "court",
    comment:
      "A court associated with a legal document; for example, that which issues a decision.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "degree",
    label: "degree",
    comment: "The thesis degree.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "director",
    label: "director",
    comment: "A Film director.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "distributor",
    label: "distributor",
    comment: "Distributor of a document or a collection of documents.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "editor",
    label: "editor",
    comment:
      "A person having managerial and sometimes policy-making responsibility for the editorial part of a publishing firm or of a newspaper, magazine, or other publication.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "editorList",
    label: "list of editors",
    comment:
      "An ordered list of editors. Normally this list is seen as a priority list that order editors by importance.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "interviewee",
    label: "interviewee",
    comment: "An agent that is interviewed by another agent.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "interviewer",
    label: "interviewer",
    comment: "An agent that interview another agent.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "issuer",
    label: "issuer",
    comment:
      "An entity responsible for issuing often informally published documents such as press releases, reports, etc.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "organizer",
    label: "organizer",
    comment:
      "The organizer of an event; includes conference organizers, but also government agencies or other bodies that are responsible for conducting hearings.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "owner",
    label: "owner",
    comment: "Owner of a document or a collection of documents.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "performer",
    label: "performer",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "presentedAt",
    label: "presented at",
    comment: "Relates a document to an event; for example, a paper to a conference.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "presents",
    label: "presents",
    comment: "Relates an event to associated documents; for example, conference to a paper.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "producer",
    label: "producer",
    comment: "Producer of a document or a collection of documents.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "recipient",
    label: "recipient",
    comment: "An agent that receives a communication document.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "reproducedIn",
    label: "reproducedIn",
    comment: "The resource in which another resource is reproduced.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "reversedBy",
    label: "reversedBy",
    comment: "A legal decision that reverses a ruling.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "reviewOf",
    label: "review of",
    comment: "Relates a review document to a reviewed thing (resource, item, etc.).",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "status",
    label: "status",
    comment: "The publication status of (typically academic) content.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "subsequentLegalDecision",
    label: "subsequentLegalDecision",
    comment:
      "A legal decision on appeal that takes action on a case (affirming it, reversing it, etc.).",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "transcriptOf",
    label: "transcript of",
    comment: "Relates a document to some transcribed original.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "translationOf",
    label: "translation of",
    comment: "Relates a translated document to the original document.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "translator",
    label: "translator",
    comment: "A person who translates written document from one language to another.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "argued",
    label: "date argued",
    comment:
      "The date on which a legal case is argued before a court. Date is of format xsd:date",
    type_value: "date"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "asin",
    label: "asin",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "chapter",
    label: "chapter",
    comment: "An chapter number",
    type_value: "number"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "coden",
    label: "coden",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "content",
    label: "content",
    comment:
      "This property is for a plain-text rendering of the content of a Document. While the plain-text content of an entire document could be described by this property.",
    type_value: "textarea"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "doi",
    label: "doi",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "eanucc13",
    label: "eanucc13",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "edition",
    label: "edition",
    comment:
      "The name defining a special edition of a document. Normally its a literal value composed of a version number and words.",
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "eissn",
    label: "eissn",
    comment: nil,
    type_value: "text"
  },
  %{
    owner_id: nil,
    vocabulary_id: 3,
    local_name: "gtin14",
    label: "gtin14",
    comment: nil,
    type_value: "text"
  }
]

for property <- properties_list do
  # Check if property already exists by local_name and vocabulary_id
  vocabulary_id =
    case property[:vocabulary_id] do
      1 -> vocabulary_1.id
      2 -> vocabulary_2.id
      3 -> vocabulary_3.id
      4 -> vocabulary_4.id
      5 -> vocabulary_5.id
    end

  case Repo.get_by(Property, local_name: property[:local_name], vocabulary_id: vocabulary_id) do
    nil ->
      %Property{
        owner_id: property[:owner_id],
        vocabulary_id: vocabulary_id,
        local_name: property[:local_name],
        label: property[:label],
        information: property[:comment],
        type_value: property[:type_value]
      }
      |> Repo.insert!()

    _existing ->
      # Property already exists, skip
      :ok
  end
end
