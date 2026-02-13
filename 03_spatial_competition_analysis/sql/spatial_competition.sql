/* =========================================================
   03_spatial_competition_analysis
   Spatial supply & competition layer 
   ========================================================= */

/* ---------------------------------------------------------
   (1) Map dataset for Superset (All Cafes — Spatial Distribution)
   Uses mart.map_points as base, exposes lat/lon as columns
---------------------------------------------------------- */

CREATE OR REPLACE VIEW mart.map_points_lat_lon AS
SELECT
    place_id,
    name,
    district,
    rating,
    user_ratings_total,
    price_level,
    business_status,
    website,
    google_maps_url,
    rating_band,
    ST_Y(geom) AS latitude,
    ST_X(geom) AS longitude,
    geom
FROM mart.map_points
WHERE geom IS NOT NULL;




/* ---------------------------------------------------------
   (2) Competition distribution (banded histogram dataset)
   X: competition_band_label
   Y: SUM(cafe_count)
---------------------------------------------------------- */

CREATE OR REPLACE VIEW mart.v_competition_distribution AS
WITH banded AS (
    SELECT
        competitors_within_2km,
        CASE
            WHEN competitors_within_2km < 50  THEN '0-49'
            WHEN competitors_within_2km < 100 THEN '50-99'
            WHEN competitors_within_2km < 150 THEN '100-149'
            WHEN competitors_within_2km < 250 THEN '150-249'
            ELSE '250+'
        END AS competition_band_label,
        CASE
            WHEN competitors_within_2km < 50  THEN 1
            WHEN competitors_within_2km < 100 THEN 2
            WHEN competitors_within_2km < 150 THEN 3
            WHEN competitors_within_2km < 250 THEN 4
            ELSE 5
        END AS competition_band_order
    FROM mart.cafe_competition_2km
    WHERE competitors_within_2km IS NOT NULL
)
SELECT
    competition_band_order,
    competition_band_label,
    COUNT(*) AS cafe_count
FROM banded
GROUP BY competition_band_order, competition_band_label
ORDER BY competition_band_order;


/* ---------------------------------------------------------
   (4) Average 2km competition by district (district pressure)
   X: district
   Metric: AVG(competitors_within_2km)
---------------------------------------------------------- */

CREATE OR REPLACE VIEW mart.v_avg_competition_by_district AS
SELECT
    district,
    AVG(competitors_within_2km) AS avg_competition_2km
FROM mart.cafe_competition_2km
WHERE district IS NOT NULL
GROUP BY district;
