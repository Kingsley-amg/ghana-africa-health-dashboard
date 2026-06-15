# =============================================================================
#  04_make_video.R
#  Renders animation frames (one PNG per step) of under-5 mortality across
#  West Africa, 2000-2022, with Ghana highlighted. ffmpeg then stitches them
#  into an MP4 (see the shell command run after this script).
# =============================================================================

suppressMessages({ library(dplyr); library(ggplot2); library(readr) })

frame_dir <- "frames"
unlink(frame_dir, recursive = TRUE); dir.create(frame_dir)

fact <- read_csv("data/fact_health_long.csv", show_col_types = FALSE)
dimc <- read_csv("data/dim_country.csv",       show_col_types = FALSE)

wa <- fact %>%
  filter(indicator_code == "SH.DYN.MORT") %>%
  inner_join(dimc %>% filter(is_west_africa), by = "iso3") %>%
  select(country_name, iso3, year, value, is_ghana)

years   <- sort(unique(wa$year))
xmax    <- max(wa$value) * 1.08
# Fix bar order by the year-2000 value (worst at the bottom) so bars don't jump
order_lv <- wa %>% filter(year == 2000) %>% arrange(value) %>% pull(country_name)

# Smooth interpolation: create extra steps between each pair of years
steps   <- 5
frame_i <- 0

render_frame <- function(df, yr_label) {
  frame_i <<- frame_i + 1
  df$country_name <- factor(df$country_name, levels = order_lv)
  p <- ggplot(df, aes(value, country_name, fill = is_ghana)) +
    geom_col(width = 0.72) +
    geom_text(aes(label = round(value)), hjust = -0.25, size = 5, color = "#2a2f37") +
    annotate("text", x = xmax * 0.96, y = 1.4, label = yr_label,
             size = 22, color = "#d8dde3", fontface = "bold", hjust = 1) +
    scale_fill_manual(values = c("FALSE" = "#c3ccd6", "TRUE" = "#e31a1c"), guide = "none") +
    scale_x_continuous(limits = c(0, xmax), expand = c(0, 0)) +
    labs(title = "Under-5 mortality across West Africa",
         subtitle = "Deaths per 1,000 live births  ·  Ghana in red  ·  lower is better",
         x = NULL, y = NULL,
         caption = "Source: World Bank Open Data  |  built by Kingsley Amegah") +
    theme_minimal(base_size = 16) +
    theme(plot.title = element_text(face = "bold", size = 22),
          plot.subtitle = element_text(color = "#6b7785", size = 13),
          plot.caption = element_text(color = "#9aa6b2", size = 10),
          panel.grid.major.y = element_blank(),
          panel.grid.minor = element_blank(),
          plot.margin = margin(18, 26, 12, 12))
  ggsave(sprintf("%s/frame_%04d.png", frame_dir, frame_i), p,
         width = 7.2, height = 7.2, dpi = 150)
}

# Build interpolated frames
for (i in seq_len(length(years) - 1)) {
  y0 <- years[i]; y1 <- years[i + 1]
  d0 <- wa %>% filter(year == y0); d1 <- wa %>% filter(year == y1)
  for (s in 0:(steps - 1)) {
    f <- s / steps
    df <- d0 %>%
      rename(v0 = value) %>%
      inner_join(d1 %>% select(iso3, v1 = value), by = "iso3") %>%
      mutate(value = v0 + (v1 - v0) * f)
    render_frame(df, as.character(y0))
  }
}
# Hold on the final year for ~1.5s
final <- wa %>% filter(year == max(years))
for (k in 1:18) render_frame(final, as.character(max(years)))

cat("Rendered", frame_i, "frames to ./", frame_dir, "\n", sep = "")
