# Regression checks on the generated data files.
#
#   Rscript tests/test-data.R
#
# These are value snapshots, deliberately separate from R/build_data.R. The
# build asserts structural invariants that survive a data update (header
# match, conservation, row count, sign count); this file pins the actual
# numbers, so after an update it tells you exactly what changed instead of
# silently accepting it.
#
# When the data is legitimately updated, expect failures here and update the
# expectations after checking each one against the new source file.

setwd(here::here())
source("R/utils/write_stable.R")

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

val <- function(df, ...) {
  conds <- list(...)
  keep <- rep(TRUE, nrow(df))
  for (nm in names(conds)) keep <- keep & df[[nm]] == conds[[nm]]
  df$value[keep]
}

f1 <- rd("ragweed_pollen_season_change.csv")

cat("\nFigure 1 (ragweed_pollen_season_change.csv)\n")
check("11 rows", nrow(f1) == 11L)
check("columns as documented",
      identical(names(f1), c("city", "state_province", "latitude", "longitude", "value")))

check("Austin/Georgetown row (first)",
      identical(as.list(f1[f1$city == "Austin/Georgetown,", ]),
                list(city = "Austin/Georgetown,", state_province = "TX",
                     latitude = "30.63271111", longitude = "-97.67727778",
                     value = "-1.084754492")))
check("Kansas City row",
      identical(as.list(f1[f1$city == "Kansas City,", ]),
                list(city = "Kansas City,", state_province = "MO",
                     latitude = "39.08316", longitude = "-94.577429",
                     value = "25.22807018")))
check("Winnipeg row (Canadian entry)",
      identical(as.list(f1[f1$city == "Winnipeg,", ]),
                list(city = "Winnipeg,", state_province = "MB, Canada",
                     latitude = "49.89975833", longitude = "-97.13749444",
                     value = "24.56239413")))
check("Saskatoon row (last)",
      identical(as.list(f1[f1$city == "Saskatoon,", ]),
                list(city = "Saskatoon,", state_province = "SK, Canada",
                     latitude = "52.13439167", longitude = "-106.647675",
                     value = "23.71541502")))

check("all 11 city names present, each once",
      identical(sort(f1$city), sort(c(
        "Austin/Georgetown,", "Oklahoma City,", "Rogers,", "Kansas City,",
        "Papillion/Bellevue,", "Madison,", "La Crosse,", "Minneapolis,",
        "Fargo,", "Winnipeg,", "Saskatoon,"
      ))))
check("no duplicate cities", !anyDuplicated(f1$city))

change_numeric <- as.numeric(f1$value)
check("exactly one negative value (change in days)", sum(change_numeric < 0) == 1L)
check("the negative value belongs to Austin/Georgetown",
      f1$city[change_numeric < 0] == "Austin/Georgetown,")
check("exactly 10 of 11 stations show a longer season (positive change)",
      sum(change_numeric > 0) == 10L)
check("max value is Kansas City, 25.22807018",
      f1$city[which.max(change_numeric)] == "Kansas City," &&
        f1$value[which.max(change_numeric)] == "25.22807018")
check("min value is Austin/Georgetown, -1.084754492",
      f1$city[which.min(change_numeric)] == "Austin/Georgetown," &&
        f1$value[which.min(change_numeric)] == "-1.084754492")

check("both Canadian entries carry ', Canada' in state_province",
      all(grepl(", Canada$", f1$state_province[f1$city %in% c("Winnipeg,", "Saskatoon,")])))
check("no other entry carries a comma in state_province",
      !any(grepl(",", f1$state_province[!f1$city %in% c("Winnipeg,", "Saskatoon,")])))

cat("\nFile hygiene\n")
for (f in list.files("data", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE }, error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

meta <- yaml::read_yaml("data/meta.yml")
check("meta.yml documents one dataset", length(meta$datasets) == 1L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))
for (ds in meta$datasets) {
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  actual <- names(rd(ds$file))
  check(sprintf("meta.yml dictionary matches %s columns", ds$file),
        identical(cols, actual))
  check(sprintf("meta.yml row count matches %s", ds$file),
        ds$rows == nrow(rd(ds$file)))
}

cat("\nnarrative.qmd\n")
check("narrative.qmd exists", file.exists("narrative.qmd"))
check("narrative.qmd is UTF-8, LF, no BOM, no mojibake",
      tryCatch({ assert_clean_output("narrative.qmd"); TRUE }, error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
nar <- readLines("narrative.qmd", warn = FALSE, encoding = "UTF-8")
check("narrative.qmd has exactly 7 references",
      sum(grepl('<li id="ref-', nar, fixed = TRUE)) == 7L)
check("narrative.qmd has all six sections",
      all(c("## Key Points", "## Background", "## About the Indicator",
            "## Indicator Notes", "## Data Sources", "## References") %in% nar))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
