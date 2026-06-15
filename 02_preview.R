# =============================================================================
#  02_preview.R
#  Quick validation / README preview charts (the recruiter-facing interactive
#  dashboard is built in Power BI / Tableau - see DASHBOARD_GUIDE.md).
# =============================================================================

suppressMessages({ library(dplyr); library(tidyr); library(ggplot2); library(readr) })

dir.create("preview", showWarnings = FALSE)

fact <- read_csv("data/fact_health_long.csv", show_col_types = FALSE)
dim_c <- read_csv("data/dim_country.csv",      show_col_types = FALSE)
dim_i <- read_csv("data/dim_indicator.csv",    show_col_types = FALSE)

df <- fact %>%
  left_join(dim_c, by = "iso3") %>%
  left_join(dim_i, by = "indicator_code")

# ---- 1. Ghana's progress across key indicators (the headline story) --------
key <- c("Life expectancy at birth", "Under-5 mortality rate",
         "Maternal mortality ratio", "Malaria incidence",
         "Measles immunization (ages 12-23 months)", "Health expenditure per capita")

p1 <- df %>%
  filter(is_ghana, indicator_name %in% key) %>%
  ggplot(aes(year, value)) +
  geom_line(color = "#1f78b4", linewidth = 1) +
  geom_point(color = "#1f78b4", size = 1) +
  facet_wrap(~ indicator_name, scales = "free_y") +
  labs(title = "Ghana's health indicators, 2000-2022",
       subtitle = "Source: World Bank Open Data",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(strip.text = element_text(face = "bold"))

ggsave("preview/ghana_trends.png", p1, width = 9, height = 5.5, dpi = 130)

# ---- 2. West Africa ranking: under-5 mortality (latest year), Ghana shown --
p2 <- df %>%
  filter(is_west_africa, indicator_name == "Under-5 mortality rate") %>%
  group_by(iso3, country_name) %>%
  filter(year == max(year)) %>%
  ungroup() %>%
  ggplot(aes(reorder(country_name, value), value, fill = is_ghana)) +
  geom_col() +
  geom_text(aes(label = round(value, 0)), hjust = -0.15, size = 3) +
  coord_flip() +
  scale_fill_manual(values = c("FALSE" = "grey70", "TRUE" = "#e31a1c"), guide = "none") +
  labs(title = "Under-5 mortality across West Africa (latest year)",
       subtitle = "Ghana highlighted in red - lower is better",
       x = NULL, y = "Deaths per 1,000 live births") +
  theme_minimal(base_size = 11)

ggsave("preview/westafrica_ranking.png", p2, width = 8, height = 5, dpi = 130)

cat("Preview charts written to ./preview/\n")
