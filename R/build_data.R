# Build tidy data for the Ragweed Pollen Season indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's single published figure CSV in data-raw/ and writes data/*.csv
# plus data/meta.yml. Rerunning with unchanged inputs produces byte-identical
# output. Nothing here touches the network.
#
# TO UPDATE THE DATA: drop a replacement CSV into data-raw/ and rerun. Columns
# are matched by header string, so this stops with a clear error if EPA
# renames or reorders a column rather than silently mismatching one.
#
# TO ADAPT THIS FOR ANOTHER INDICATOR: the indicator constants and the
# expected-header list immediately below are the only indicator-specific
# content. Everything else is mechanical.
#
# Input shape: EPA's published per-figure CSV (see data-raw/PROVENANCE.md).
# Unlike a typical year-series indicator, Figure 1 here is not a time series:
# each row is one of 11 long-term monitoring stations, already reporting a
# single 1995-to-2015 change value. There is no wide-to-year pivot to do; the
# source is already one row per observation.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Ragweed Pollen Season",
  slug                    = "ragweed-pollen-season",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ragweed-pollen-season/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/ragweed_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# The leading identifier columns in the source file, i.e. everything that is
# not the single measured value. Matched by header string so a reordered
# column stops the build rather than silently swapping a value.
FIG1_ID_COLS <- c(
  "City", "State/Province",
  "Latitude (decimal degrees)", "Longitude (decimal degrees)"
)
FIG1_VALUE_COL <- "Change in Length of Ragweed Pollen Season (days)"

# ---- Figure 1: change in ragweed pollen season length, 1995-2015 -------------

f1_path <- file.path(raw_dir, "ragweed_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)
assert_headers(f1_raw, FIG1_ID_COLS, FIG1_VALUE_COL, "ragweed_fig-1.csv")

# Values stay character end to end: nothing here calls as.numeric() to
# overwrite a stored column. suppressWarnings(as.numeric(...)) below is used
# only transiently, for validation, never to replace what gets written.
f1 <- f1_raw |>
  dplyr::transmute(
    # City is reproduced verbatim, including a source formatting artifact:
    # several entries carry a trailing comma or extra space baked into the
    # name itself (e.g. "Austin/Georgetown,", "Kansas City, "). This is EPA's
    # own published text, not a parsing bug here, and it is kept unmodified
    # rather than corrected, per the rule that a source column is reproduced
    # verbatim, never re-derived.
    city           = City,
    # The two Canadian stations additionally carry ", Canada" inside this
    # same field (e.g. "MB, Canada"), rather than a separate country column.
    state_province = `State/Province`,
    latitude       = `Latitude (decimal degrees)`,
    longitude      = `Longitude (decimal degrees)`,
    # Named `value`, not `change_days`: the site's read_indicator() (in
    # climateindicators.us/R/common.R) unconditionally coerces a column
    # literally named `value` to numeric and errors if it is absent. Every
    # indicator repository's primary measured column is named `value` for
    # this reason.
    value          = .data[[FIG1_VALUE_COL]]
  )

assert_conservation(f1_raw, FIG1_VALUE_COL, nrow(f1), "figure 1")

# ---- Assertions that survive a data update ------------------------------------

change_numeric <- suppressWarnings(as.numeric(f1$value))
stopifnot(
  "figure 1: value must parse as a number for every station" =
    !anyNA(change_numeric),
  "figure 1: should have exactly 11 station rows, per EPA's own indicator text ('11 locations')" =
    nrow(f1) == 11L,
  "figure 1: exactly 10 of 11 stations should show a longer season (positive change), per EPA's own Key Points text ('10 of the 11 locations')" =
    sum(change_numeric > 0) == 10L
)

# ---- Write ------------------------------------------------------------------

write_csv_stable(f1, file.path(out_dir, "ragweed_pollen_season_change.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "ragweed_pollen_season_change.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "ragweed_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "windows-1252",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns = list(
        col("city", "string", paste(
          "Monitoring station city, verbatim from the source file. Several",
          "source entries carry a trailing comma or extra space baked into",
          "the city name (e.g. \"Austin/Georgetown,\"); this is preserved",
          "unmodified rather than corrected."
        )),
        col("state_province", "string", paste(
          "US state or Canadian province, verbatim from the source file.",
          "The two Canadian entries additionally carry \", Canada\" inside",
          "this field (e.g. \"MB, Canada\")."
        )),
        col("latitude", "number", "Station latitude, decimal degrees, verbatim from the source file."),
        col("longitude", "number", "Station longitude, decimal degrees, verbatim from the source file."),
        col("value", "number", paste(
          "Change in the length of ragweed pollen season from 1995 to 2015,",
          "in days, verbatim from the source file. Positive means the season",
          "grew longer; the single negative value (Austin/Georgetown) means",
          "it grew shorter."
        ))
      ),
      note = paste(
        "Every row is one of the 11 long-term pollen monitoring stations",
        "EPA's analysis covers. There is no year dimension: this figure",
        "reports one already-computed 1995-to-2015 change per station, not",
        "a time series."
      )
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- file.path(out_dir, c("ragweed_pollen_season_change.csv", "meta.yml"))
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %6d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
cat(sprintf("\nRows: figure 1 = %d\n", nrow(f1)))
