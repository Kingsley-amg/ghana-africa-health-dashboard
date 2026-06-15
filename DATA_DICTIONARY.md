# Data Dictionary

All tables are in `data/`. Source: World Bank Open Data API (2000–2022).

## `fact_health_long.csv` — fact table (grain: country × year × indicator)
| Column | Type | Description |
|---|---|---|
| `iso3` | text | ISO-3166 alpha-3 country code (e.g. `GHA`). Foreign key → `dim_country`. |
| `year` | integer | Calendar year (2000–2022). |
| `indicator_code` | text | World Bank indicator code. Foreign key → `dim_indicator`. |
| `value` | numeric | Observed value for that country, year, indicator. Missing values are dropped. |

## `fact_health_wide.csv` — same data pivoted wide
One row per `iso3` × `year`; one column per indicator (readable names). Convenient for quick Tableau drag-and-drop; the long table is preferred for the modelled dashboard.

## `dim_country.csv` — country dimension
| Column | Type | Description |
|---|---|---|
| `iso3` | text | Primary key. |
| `country_name` | text | Country name. |
| `region` | text | World Bank region (all are African here). |
| `income_level` | text | World Bank income group (e.g. *Lower middle income*). |
| `latitude` / `longitude` | numeric | Country centroid (for map plotting). |
| `is_ghana` | boolean | TRUE for Ghana (drives highlight colour). |
| `is_west_africa` | boolean | TRUE for the 16 West-African states (peer group). |
| `subregion` | text | `North Africa` or `Sub-Saharan Africa`. |

## `dim_indicator.csv` — indicator dimension
| Column | Type | Description |
|---|---|---|
| `indicator_code` | text | Primary key (World Bank code). |
| `indicator_name` | text | Human-readable name. |
| `unit` | text | Unit of measure. |
| `category` | text | Grouping: Outcomes, Mortality, Prevention, Disease burden, Resources. |
| `higher_is_better` | boolean | Direction of "good". Use for conditional formatting / KPI arrows. |
