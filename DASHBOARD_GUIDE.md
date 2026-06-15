# Dashboard Build Guide (Power BI & Tableau)

This guide turns the `data/` star schema into an interactive, recruiter-ready
dashboard. Follow the **Power BI** path or the **Tableau** path — both end with a
free, shareable **live link** you can pin on LinkedIn.

---

## 0. Load the data

**Power BI Desktop** → *Home ▸ Get Data ▸ Text/CSV* → import all four files in
`data/`. **Tableau Public** → *Connect ▸ Text File* → add the same four.

## 1. Build the model (relationships)

Create these relationships (one-to-many, single direction):

```
dim_country[iso3]        1 ──► *  fact_health_long[iso3]
dim_indicator[indicator_code] 1 ──► * fact_health_long[indicator_code]
```

In Power BI: *Model view* → drag the keys together. In Tableau: relate them on
the data-source canvas. This is a classic **star schema** — say so in your README;
recruiters notice modelling.

---

## 2. Core measures

### Power BI (DAX)
```DAX
Selected Value      = SUM ( fact_health_long[value] )

Latest Year         = MAX ( fact_health_long[year] )

Value (Latest Year) =
    CALCULATE ( [Selected Value], fact_health_long[year] = [Latest Year] )

Value (Year 2000)   =
    CALCULATE ( [Selected Value], fact_health_long[year] = 2000 )

% Change since 2000 =
    DIVIDE ( [Value (Latest Year)] - [Value (Year 2000)], [Value (Year 2000)] )

Ghana vs WA Avg =   -- Ghana minus West-Africa average for the selected indicator
VAR WAAvg =
    CALCULATE ( AVERAGE ( fact_health_long[value] ),
                FILTER ( ALL ( dim_country ), dim_country[is_west_africa] = TRUE ) )
VAR GhanaVal =
    CALCULATE ( [Selected Value], dim_country[is_ghana] = TRUE )
RETURN GhanaVal - WAAvg
```

### Tableau (calculated fields)
```
Latest Year:        { FIXED : MAX([Year]) }
Value Latest:       SUM(IF [Year] = [Latest Year] THEN [Value] END)
Value 2000:         SUM(IF [Year] = 2000 THEN [Value] END)
% Change since 2000: ([Value Latest] - [Value 2000]) / [Value 2000]
```

---

## 3. Page / sheet layout

Design **three pages**. Keep one consistent colour theme (Ghana = a single
accent colour, e.g. red `#E31A1C`; everything else neutral grey).

### Page 1 — Executive Overview (for *any* recruiter)
- **5 KPI cards** (top row): Life expectancy, Under-5 mortality, Maternal
  mortality, Malaria incidence, Health spend per capita — each showing the
  latest value + `% Change since 2000` with an up/down arrow coloured by
  `higher_is_better`.
- **Choropleth map** (see §4) of the selected indicator across Africa.
- **Slicers:** Indicator (single-select), Year.
- One sentence of insight as a text box (the "so what").

### Page 2 — Ghana Spotlight (your domain edge)
- **Line chart**: selected indicator over time, Ghana vs West-Africa average
  (two lines) — uses `is_west_africa`.
- **Small multiples**: all indicators for Ghana over time (like
  `preview/ghana_trends.png`).
- KPI cards specific to Ghana.

### Page 3 — Country Benchmark
- **Bar chart** ranking all countries on the selected indicator (latest year),
  Ghana bar highlighted (like `preview/westafrica_ranking.png`).
- **Scatter**: Health expenditure per capita (x) vs Life expectancy (y), one
  dot per country, sized by nothing/coloured by subregion — shows the
  spend↔outcome relationship.
- **Matrix/heatmap**: country (rows) × indicator (cols), colour = value.

---

## 4. The map (choropleth)

- **Power BI:** use the *Filled map* visual → Location = `dim_country[country_name]`
  (set its Data category to *Country*), or use `iso3` for reliable matching →
  Colour saturation = `[Value (Latest Year)]`.
- **Tableau:** drag `Country Name` to the view (Tableau auto-geocodes) → colour by
  `Value Latest`. Use `latitude`/`longitude` if you prefer symbol maps.
- Use a **diverging or sequential** palette and **reverse it** for
  "lower-is-better" indicators so red always = worse.

---

## 5. Polish (the difference between OK and hire-worthy)

- Title every page; add a footer: *"Source: World Bank Open Data · built by [name]"*.
- Format numbers (no 6-decimal noise): mortality 0 dp, % 1 dp, US$ with `$`.
- Add a **tooltip** on the map/bars showing country + value + rank.
- Make the **Indicator slicer sync** across all pages.
- Sentence of insight per page — recruiters skim; tell them what to conclude.

## 6. Publish a LIVE link (do this!)

- **Tableau Public** (easiest free public link): *File ▸ Save to Tableau Public*.
  You get a URL like `public.tableau.com/app/profile/.../viz/...`.
- **Power BI:** *Publish to web* (Free) → embeds a public link, **or** export a
  short screen-recording GIF if your org disables public publish.
- Put the live link in your repo README **and** your LinkedIn Featured section.

---

## Suggested build order (≈ half a day)
1. Load data + relationships (§1) — 15 min
2. Measures (§2) — 20 min
3. Page 1 overview + map (§3, §4) — 90 min
4. Pages 2 & 3 — 90 min
5. Polish + publish (§5, §6) — 45 min
