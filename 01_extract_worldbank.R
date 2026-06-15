# =============================================================================
#  01_extract_worldbank.R
#  ETL step 1: pull health indicators from the World Bank API and build a
#  clean star-schema (1 fact table + 3 dimension tables) for the dashboard.
#
#  Source: World Bank Open Data API (no API key required)
#  Output: tidy CSVs in ./data ready to load into Power BI / Tableau.
# =============================================================================

suppressMessages({
  library(jsonlite)   # parse the API's JSON responses
  library(dplyr)      # data wrangling
  library(tidyr)      # reshape (long <-> wide)
  library(readr)      # write_csv
})

out_dir <- "data"
base    <- "https://api.worldbank.org/v2"
years   <- "2000:2022"

# ---- 1. Indicators we want (health surveillance + KPI-friendly) ------------
# higher_is_better drives conditional formatting / arrow direction in the BI tool.
indicators <- tribble(
  ~indicator_code,      ~indicator_name,                              ~unit,                 ~category,        ~higher_is_better,
  "SP.DYN.LE00.IN",     "Life expectancy at birth",                   "years",               "Outcomes",       TRUE,
  "SH.DYN.MORT",        "Under-5 mortality rate",                     "per 1,000 live births","Mortality",      FALSE,
  "SP.DYN.IMRT.IN",     "Infant mortality rate",                      "per 1,000 live births","Mortality",      FALSE,
  "SH.STA.MMRT",        "Maternal mortality ratio",                   "per 100,000 births",  "Mortality",      FALSE,
  "SH.IMM.MEAS",        "Measles immunization (ages 12-23 months)",   "% of children",       "Prevention",     TRUE,
  "SH.IMM.IDPT",        "DPT immunization (ages 12-23 months)",       "% of children",       "Prevention",     TRUE,
  "SH.MLR.INCD.P3",     "Malaria incidence",                          "per 1,000 at risk",   "Disease burden", FALSE,
  "SH.XPD.CHEX.PC.CD",  "Health expenditure per capita",              "current US$",         "Resources",      TRUE
)

# ---- 2. Helper: download one indicator as a tidy data frame ----------------
get_indicator <- function(code) {
  url <- sprintf("%s/country/all/indicator/%s?format=json&date=%s&per_page=20000",
                 base, code, years)
  message("Downloading ", code, " ...")
  raw <- fromJSON(url, flatten = TRUE)   # element [[1]] = metadata, [[2]] = data
  df  <- raw[[2]]
  if (is.null(df) || nrow(df) == 0) return(NULL)
  df %>%
    transmute(
      iso3           = countryiso3code,
      year           = as.integer(date),
      indicator_code = code,
      value          = as.numeric(value)
    ) %>%
    filter(!is.na(value), iso3 != "")
}

# ---- 3. Download all indicators and stack into one long fact table ---------
fact_long <- bind_rows(lapply(indicators$indicator_code, get_indicator))

# ---- 4. Country metadata -> dim_country -----------------------------------
meta_url <- sprintf("%s/country?format=json&per_page=400", base)
meta_raw <- fromJSON(meta_url, flatten = TRUE)[[2]]

dim_country_all <- meta_raw %>%
  transmute(
    iso3         = trimws(id),
    country_name = trimws(name),
    # NOTE: the API pads some text fields with trailing spaces, so we trimws()
    region       = trimws(region.value),
    income_level = trimws(incomeLevel.value),
    latitude     = as.numeric(latitude),
    longitude    = as.numeric(longitude)
  ) %>%
  # Drop aggregate rows (regions/income groups have region = "Aggregates")
  filter(region != "Aggregates")

# Keep African countries only: all of Sub-Saharan Africa + North African states
north_africa <- c("DZA", "EGY", "LBY", "MAR", "TUN", "SDN", "ESH")
west_africa  <- c("GHA", "NGA", "CIV", "SEN", "MLI", "BFA", "NER", "TGO",
                  "BEN", "GIN", "GNB", "LBR", "SLE", "GMB", "MRT", "CPV")

dim_country <- dim_country_all %>%
  filter(region == "Sub-Saharan Africa" | iso3 %in% north_africa) %>%
  mutate(
    is_ghana       = iso3 == "GHA",
    is_west_africa = iso3 %in% west_africa,
    subregion      = if_else(iso3 %in% north_africa, "North Africa", "Sub-Saharan Africa")
  ) %>%
  arrange(country_name)

# ---- 5. Restrict the fact table to African countries ----------------------
fact_long <- fact_long %>%
  semi_join(dim_country, by = "iso3") %>%
  arrange(iso3, indicator_code, year)

# A wide version is handy for quick exploration / Tableau drag-and-drop
fact_wide <- fact_long %>%
  left_join(indicators %>% select(indicator_code, indicator_name), by = "indicator_code") %>%
  select(iso3, year, indicator_name, value) %>%
  pivot_wider(names_from = indicator_name, values_from = value)

# ---- 6. Write the star schema to CSV --------------------------------------
write_csv(fact_long,  file.path(out_dir, "fact_health_long.csv"))
write_csv(fact_wide,  file.path(out_dir, "fact_health_wide.csv"))
write_csv(dim_country, file.path(out_dir, "dim_country.csv"))
write_csv(indicators, file.path(out_dir, "dim_indicator.csv"))

# ---- 7. Console summary ----------------------------------------------------
cat("\n==================== ETL COMPLETE ====================\n")
cat("Countries (African):", nrow(dim_country), "\n")
cat("Indicators:         ", nrow(indicators), "\n")
cat("Fact rows (long):   ", nrow(fact_long), "\n")
cat("Year range:         ", min(fact_long$year), "-", max(fact_long$year), "\n")
cat("Files written to ./", out_dir, ":\n", sep = "")
cat("  fact_health_long.csv, fact_health_wide.csv, dim_country.csv, dim_indicator.csv\n")
