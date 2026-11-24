# Indonesian sources: live search API vs OAI-PMH — spike report

**Date:** 2026-11-24
**Scope:** Phase C4 evaluation item (spec §14 C4). No production code; this is a
decision document for whether to federate or harvest Indonesian sources.
**Method:** direct HTTP probes from the Curatorian host (raw results quoted
below), plus published documentation. Nothing here is assumed.

---

## 1. Verdict up front

**No Indonesian national portal currently offers a public full-text search API
usable for live federation.** Every candidate is either:

- **OAI-PMH only** (a *harvesting* protocol — it cannot answer a user's query),
- **HTML-only** (server-rendered pages, no documented JSON endpoint), or
- **unreachable** from this network.

Therefore the choice is not "federate vs harvest" for these sources; it is
"harvest into Atrium's index later, or leave them out". This iteration
(Curatorian) does neither — Curatorian has no catalog index of its own (D8), and
harvesting belongs to Atrium.

---

## 2. Probe results

| Source | Probe | Result | Reading |
|---|---|---|---|
| **IndonesiaOneSearch** (Perpusnas aggregator, ~9.8 M entries) | `GET onesearch.id/Search/Results?lookfor=borobudur` | `status=000` (connection failed) | Unreachable from this host; also HTML-only by design |
| | `GET onesearch.id/api/search?q=…` | `status=000` | No API path exists to probe |
| **Perpusnas OPAC** (national catalogue) | `GET opac.perpusnas.go.id/oai/oai2.aspx?verb=Identify` | `200`, OAI-PMH XML (`<OAI-PMH …>`) | **OAI-PMH works** (`marcxml`); no search API |
| **Neliti** (1,554 repositories, Indonesian journals) | `GET neliti.com/oai?verb=Identify` | `200`, OAI-PMH XML | **OAI-PMH works** (`oai_dc` only) |
| | `GET neliti.com/oai?verb=ListRecords&metadataPrefix=oai_dc` | `200`, 532 KB, **200 records/page**, `resumptionToken` present | Harvestable, paginated |
| **GARUDA** (Kemdiktisaintek journal portal) | `GET garuda.kemdiktisaintek.go.id/` | `200 text/html` | HTML only |
| | `GET …/api/v1` | `200 text/plain` → body: **"Not Support"** | No API |
| | `GET …/api` | `404` → "Cannot GET /api" | No API |
| | `GET …/suggest?term=…` | `200 text/html` | Autocomplete page, not JSON |
| **Moraref** (Ministry of Religious Affairs) | published evaluation | landing page only, no parseable result markup | Dead as a source |
| **BASE** (not Indonesian, but indexes Indonesian repos) | documented | OAI-PMH requires **institutional IP registration** | Not viable for a public site |

Independent corroboration: a 2026 peer-reviewed country-level study of
Indonesian journal publishing (Quantitative Science Studies, doi
10.1162/qss.a.515) states plainly that **"GARUDA does not provide an API to
access its metadata"** and that the authors had to web-mine it.

Third-party paid wrappers (Zapi, hoshime) do exist for GARUDA and Perpusnas —
they scrape HTML and resell it behind their own keys. Using them would mean
depending on an unlicensed middleman for data we do not control; **not
recommended**.

---

## 3. Why OAI-PMH cannot substitute for live search

OAI-PMH has `Identify`, `ListRecords`, `ListIdentifiers`, `GetRecord`,
`ListSets` — **no query parameter**. A "search" over OAI-PMH is a full harvest
followed by a local index lookup. Consequences:

- it needs a persistent store and an index (Atrium, not Curatorian — D8),
- it needs scheduled incremental harvests (`from`/`until` datestamps),
- metadata quality is per-repository (many SLiMS/INLIS installations emit
  sparse or inconsistent `oai_dc`),
- **Neliti alone**: 200 records/page with resumption tokens; IOS aggregates
  ~9.8 M unique entries across 9,174 repositories.

That is a multi-week Atrium project with ongoing operational cost, not a
provider module.

---

## 4. Recommendation

1. **Do not add an Indonesian provider to Curatorian in this iteration.**
   There is no live search API to call, and scraping violates the spec's
   "no scraping any source that lacks an official API" rule (§15).
2. **Record the gap honestly in the UI copy.** The external section already
   labels results as third-party; no change needed.
3. **If Indonesian coverage becomes a product goal**, the work is an Atrium
   harvest, in this order of value-per-effort:
   - **Neliti** (`https://www.neliti.com/oai`, `oai_dc`) — 1,554 repositories,
     clean pagination, Indonesian scholarly articles. Best first target.
   - **Perpusnas OPAC** (`opac.perpusnas.go.id/oai/oai2.aspx`, `marcxml`) —
     national catalogue, richer metadata but MARCXML parsing needed.
   - **IOS** — only worth it if IOS exposes its own aggregated index to us
     directly; harvesting 9,174 upstream repositories ourselves duplicates
     what IOS already does.
4. **Do not build** GARUDA or Moraref integrations: no API, and HTML scraping
   is both brittle and outside the project's rules.

### If approved, the Atrium-side shape

- Oban worker: `ListRecords` with `resumptionToken` loop, batched upserts into
  an `atrium.external_records` table (source, external_id, title, creators,
  year, language, url, license, harvested_at).
- Incremental: store the last datestamp per set, use `from=` on subsequent runs.
- Reuse the existing search plumbing: the same `tsvector` + trigram approach
  already used for `voile.collections`, exposed through the **same**
  `/api/v1/search/collections` contract with a `source=external` filter — so
  Curatorian needs no new code beyond a toggle.
- Licensing: `oai_dc` metadata is generally reusable, but **display the
  per-record rights** where supplied, and link back to the source (the
  external-section UI already supports both).

---

## 5. What would change this verdict

- IOS or Perpusnas publishing a documented JSON search endpoint.
- GARUDA shipping an official API (their portal currently answers "Not Support"
  at every plausible API path).
- An Indonesian consortium offering a hosted search endpoint with an SLA.

Until one of those happens, the four international sources already integrated
(Open Library, Internet Archive, OpenAlex, Wikisource) plus the art/photo
sources (Wikimedia Commons, Art Institute of Chicago, Cleveland, Europeana) are
the correct external coverage.
