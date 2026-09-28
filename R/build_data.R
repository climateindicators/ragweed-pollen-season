# Build tidy long-format data for the Ragweed Pollen Season indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

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

# ---- Figure 1: Change in Ragweed Pollen Season, 1995-2015 ----

f1_path <- file.path(raw_dir, "ragweed_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = character(),
  expected_headers = c("City", "State/Province", "Latitude (decimal degrees)", "Longitude (decimal degrees)", "Change in Length of Ragweed Pollen Season (days)"),
  what             = "ragweed_fig-1.csv"
)

# The Units: line lists two units, but only one of them belongs to a measured
# series: "decimal degrees" describes the latitude/longitude identifier
# columns, and "days" is the only unit a value column here actually carries.
# meta.yml's unit: field below is set to "days" for that reason.
f1 <- f1_raw |>
  dplyr::transmute(
    city           = City,
    state_province = `State/Province`,
    latitude       = `Latitude (decimal degrees)`,
    longitude      = `Longitude (decimal degrees)`,
    value          = `Change in Length of Ragweed Pollen Season (days)`
  )

write_csv_stable(f1, file.path(out_dir, "ragweed_pollen_season_change_by_location.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "ragweed_pollen_season_change_by_location.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "ragweed_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = "days",
      rows            = nrow(f1),
      columns         = list(
        col("city", "character", "City name, as published by EPA (some carry a trailing comma from the source file)."),
        col("state_province", "character", "US state or Canadian province/country."),
        col("latitude", "number", "Station latitude, decimal degrees."),
        col("longitude", "number", "Station longitude, decimal degrees."),
        col("value", "number", "Total change in length of ragweed pollen season from 1995 to 2015, in days.")
      )
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
