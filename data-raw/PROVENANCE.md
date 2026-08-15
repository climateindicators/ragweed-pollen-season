# Provenance of raw inputs

Everything in this folder is a work of the U.S. Government prepared by EPA staff
as part of their official duties, and is therefore not subject to domestic
copyright (17 U.S.C. 105). It is reproduced here unmodified.

Indicator page (the canonical source, January 19 2025 snapshot):
<https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ragweed-pollen-season/index.html>

Technical documentation (PDF, not vendored here):
<https://19january2025snapshot.epa.gov/system/files/documents/2024-06/ragweed_documentation.pdf>

## Files

Every vendored file is identified by its sha256 and by its own URL in this
repository. **Never record a path on someone's local machine.** The vendored
copy is the citable artifact: it is public, permanent, and fetchable by anyone,
which a local archive folder is not.

| File | sha256 | Raw URL |
|---|---|---|
| `ragweed_fig-1.csv` | `3941da5fe6c1b6207d7979a055496050c2bdbc2a2ccf68a713b82ba03f3b4e8e` | <https://raw.githubusercontent.com/climateindicators/ragweed-pollen-season/main/data-raw/ragweed_fig-1.csv> |

`ragweed_fig-1.csv` is EPA's own public per-figure CSV download for Figure 1,
not an internal ERG workbook. It was checked byte-for-byte against EPA's live
snapshot copy at
<https://19january2025snapshot.epa.gov/sites/default/files/2016-08/ragweed_fig-1.csv>
(HTTP 200, sha256 identical to the vendored copy above) on 2026-08-15. Because
it is the published CSV, `R/build_data.R` reads it with `R/utils/epa_csv.R`:
every column stays character end to end and nothing calls `as.numeric()`, so
the file's own text precision (up to 9 significant digits in the change-in-days
column) survives into `data/` unchanged.

`R/build_data.R` reads all five columns: `City`, `State/Province`,
`Latitude (decimal degrees)`, `Longitude (decimal degrees)`, and
`Change in Length of Ragweed Pollen Season (days)`. Nothing in the file goes
unread.

Figure 1 is the only figure this indicator publishes, and it is EPA's own
figure from its published indicator page. No figure built in this repository
departs from EPA's published presentation.

## Source documents for the prose

The indicator prose is extracted from these Word files, reproduced here
unmodified:

| File | sha256 | Raw URL |
|---|---|---|
| `ragweed_2024 update file.docx` | `049aab7679ea54af9435a00704dd4dfec20dca4e2ec0472f907c302469e7206c` | <https://raw.githubusercontent.com/climateindicators/ragweed-pollen-season/main/data-raw/ragweed_2024%20update%20file.docx> |
| `ragweed_TD_2024 update file CLEAN.docx` | `ec488fc426035f9ad6f14790187044064a3255b81f220a19408d4a4b3ca6bcd2` | <https://raw.githubusercontent.com/climateindicators/ragweed-pollen-season/main/data-raw/ragweed_TD_2024%20update%20file%20CLEAN.docx> |

EPA does not publish a raw `.docx` download for either the indicator narrative
or the technical documentation, only the rendered HTML page and the technical
documentation PDF (linked above) are public, so these two files could not be
checked against a live EPA URL the way the CSV was. They are vendored so the
extraction is reproducible from this repository alone: `R/gen_narrative.R`
reads them out of `data-raw/` and writes `narrative.qmd`, which is a generated
artifact, not a hand-edited one. The generator resolves its inputs relative to
the repository root and never takes a path outside it.

Note that Word documents of this kind routinely carry tracked-change and
reviewer metadata that is not part of the published page.
`R/utils/read_docx.R` reproduces the accept-all-tracked-changes rendering and
never opens `comments.xml`.

`ragweed_2024 update file.docx` contributes the indicator page text (Key
Points, Background, About the Indicator, Indicator Notes, Data Sources,
References). Its citations are Zotero-generated **real Word endnotes**:
`w:endnoteReference` marks in the body plus `word/endnotes.xml`, with 9 real
notes (ids 1-9) rendered as superscript reference marks. `R/gen_narrative.R`
must read `word/endnotes.xml` and remap by the order references first appear
in the body, the same approach used in `cold-related-deaths`.

`ragweed_TD_2024 update file CLEAN.docx` contributes the technical
documentation text used to fill in build/methodology detail. Its citations are
also Zotero fields, but the field results render as plain inline
author-year text (e.g. `(Ziska et al., 2011)`), not superscript numbers or
endnote marks: it has zero `w:endnoteReference` elements. A simple paragraph
text read already captures these citations correctly with no remapping
required. This document also contains "Table TD-1. Stations Reporting Ragweed
Data for this Indicator" (a station-by-station roster of start/end years and
notes) that is not part of EPA's published indicator page. It is not currently
built into `data/` as a dataset; it is documented here so it isn't mistaken for
unused filler if someone reads the source file later.

The checksums above identify the exact revisions used.

## Precision

Values are preserved as source text byte for byte. `R/utils/epa_csv.R` reads
every column as character and nothing in the build calls `as.numeric()`, so
the source file's own precision survives into `data/` unchanged.

## Updating the data

Replace the source file in this folder and rerun `R/build_data.R`. The build
reads its inputs by header cell, not by column position, so a renamed or
reordered column stops the build with a clear error instead of silently
mismatching a series. Update the table above with the new sha256.
