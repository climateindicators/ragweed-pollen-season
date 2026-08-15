# Rights and attribution

## EPA content

The indicator text, figure captions, and underlying data reproduced in this
repository are works of the U.S. Environmental Protection Agency, prepared by
officers or employees of the U.S. Government as part of their official duties.
Under 17 U.S.C. 105 such works are not subject to copyright protection in the
United States.

Source: *Climate Change Indicators in the United States: Ragweed Pollen Season*,
U.S. EPA, as preserved in the January 19, 2025 snapshot of epa.gov.

<https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ragweed-pollen-season/index.html>

The underlying data are from National Allergy Bureau (AAAAI Aeroallergen Network). See the indicator's technical
documentation for details:

<https://19january2025snapshot.epa.gov/system/files/documents/2024-06/ragweed_documentation.pdf>

Files in `data-raw/` are reproduced unmodified. Files in `data/` are
reformatted, not altered. <!-- TODO: state the precision rule that applies here,
either "values are preserved as source text byte for byte" for a published CSV,
or "rates are rounded to N decimal places, beyond the source's own meaningful
precision" for a workbook read as doubles. See data-raw/PROVENANCE.md. -->
Every transformation is in `R/build_data.R` and is checked by
`tests/test-data.R`. `narrative.qmd` is EPA's published wording, extracted from
the Word documents in `data-raw/` by `R/gen_narrative.R`.

## This rebuild

Code and the derived data schema are licensed CC-BY-SA.

This is an independent project. It is **not** affiliated with, endorsed by, or
approved by the U.S. Environmental Protection Agency or National Allergy Bureau (AAAAI Aeroallergen Network) (the
underlying data source agency). <!-- TODO: if this rebuild departs from EPA's
published presentation in any way, name the departure here and document it in
data-raw/PROVENANCE.md. -->
