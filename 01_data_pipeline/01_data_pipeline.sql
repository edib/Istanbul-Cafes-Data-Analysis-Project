/* =========================================================
   01 DATA PIPELINE
   Raw → Clean → Mart (Core Analytical Foundation)
========================================================= */

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS mart;

/* =========================================================
   1. CLEAN LAYER — clean.cafes
   Purpose: Normalize raw cafe data for analytics & spatial use
========================================================= */

DROP TABLE IF EXISTS clean.cafes;
CREATE TABLE clean.cafes AS
SELECT
    NULLIF(BTRIM(place_id), '')::text              AS place_id,
    NULLIF(BTRIM(name), '')::text                  AS name,

    rating::double precision                       AS rating,
    user_ratings_total::integer                    AS user_ratings_total,
    price_level::integer                           AS price_level,

    NULLIF(BTRIM(business_status), '')::text       AS business_status,

    latitude::double precision                     AS latitude,
    longitude::double precision                    AS longitude,

    NULLIF(BTRIM(formatted_address), '')::text     AS formatted_address,
    NULLIF(BTRIM(vicinity), '')::text              AS vicinity,
    NULLIF(BTRIM(district), '')::text              AS district,

    NULLIF(BTRIM(phone), '')::text                 AS phone,
    NULLIF(BTRIM(international_phone), '')::text   AS international_phone,
    NULLIF(BTRIM(website), '')::text               AS website,
    NULLIF(BTRIM(google_maps_url), '')::text       AS google_maps_url,

    NULLIF(BTRIM(types), '')::text                 AS types,

    CASE
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL
        THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
        ELSE NULL
    END AS geom

FROM raw.istanbul_cafes_ultra_kopyasi;


/* =========================================================
   2. INDEXES — Performance & Spatial Queries
========================================================= */

CREATE INDEX IF NOT EXISTS ix_clean_cafes_geom
    ON clean.cafes USING GIST (geom);

CREATE INDEX IF NOT EXISTS ix_clean_cafes_district
    ON clean.cafes (district);

CREATE INDEX IF NOT EXISTS ix_clean_cafes_rating
    ON clean.cafes (rating);

CREATE INDEX IF NOT EXISTS ix_clean_cafes_reviews
    ON clean.cafes (user_ratings_total);

CREATE INDEX IF NOT EXISTS ix_clean_cafes_price
    ON clean.cafes (price_level);


/* =========================================================
   3. NORMALIZATION — clean.cafe_types
   Purpose: 1 cafe → N type structure
========================================================= */

DROP TABLE IF EXISTS clean.cafe_types;
CREATE TABLE clean.cafe_types AS
SELECT
    c.place_id,
    c.district,
    c.name,
    BTRIM(t.type_token) AS type_token
FROM clean.cafes c
CROSS JOIN LATERAL (
    SELECT UNNEST(
        string_to_array(REPLACE(c.types, '"', ''), ',')
    ) AS type_token
) t
WHERE c.place_id IS NOT NULL
  AND c.types IS NOT NULL
  AND BTRIM(t.type_token) <> '';

CREATE INDEX IF NOT EXISTS ix_clean_cafe_types_district
    ON clean.cafe_types (district);

CREATE INDEX IF NOT EXISTS ix_clean_cafe_types_type
    ON clean.cafe_types (type_token);


/* =========================================================
   4. MART LAYER — Core Analytical Tables
   (Downstream analyses depend on these tables)
========================================================= */

/* -------------------------
   4.1 Global KPI Overview
-------------------------- */

DROP TABLE IF EXISTS mart.kpi_overview;
CREATE TABLE mart.kpi_overview AS
SELECT
    COUNT(*)                                           AS total_cafes,
    AVG(rating)                                        AS avg_rating,
    COUNT(*) FILTER (WHERE rating >= 4.5)              AS cafes_rating_ge_4_5,
    AVG(user_ratings_total)                            AS avg_user_ratings_total,
    AVG(price_level)                                   AS avg_price_level,
    COUNT(*) FILTER (WHERE business_status ILIKE '%OPERATIONAL%')
                                                      AS operational_count
FROM clean.cafes;


/* -------------------------
   4.2 District Summary
-------------------------- */

DROP TABLE IF EXISTS mart.district_summary;
CREATE TABLE mart.district_summary AS
SELECT
    district,
    COUNT(*)                                AS cafe_count,
    AVG(rating)                             AS avg_rating,
    COUNT(*) FILTER (WHERE rating >= 4.5)   AS high_quality_count,
    AVG(price_level)                        AS avg_price_level,
    SUM(COALESCE(user_ratings_total, 0))    AS total_reviews,
    AVG(COALESCE(user_ratings_total, 0))    AS avg_reviews
FROM clean.cafes
WHERE district IS NOT NULL
  AND district <> ''
GROUP BY district;

CREATE INDEX IF NOT EXISTS ix_mart_district_summary_district
    ON mart.district_summary (district);


/* -------------------------
   4.3 Cafe Competition (2km)
-------------------------- */

DROP TABLE IF EXISTS mart.cafe_competition_2km;
CREATE TABLE mart.cafe_competition_2km AS
SELECT
    a.place_id,
    a.name,
    a.district,
    a.geom,

    COUNT(b.place_id) - 1 AS competitors_within_2km

FROM clean.cafes a
JOIN clean.cafes b
  ON a.geom IS NOT NULL
 AND b.geom IS NOT NULL
 AND ST_DWithin(
        a.geom::geography,
        b.geom::geography,
        2000
     )
GROUP BY
    a.place_id,
    a.name,
    a.district,
    a.geom;

CREATE INDEX IF NOT EXISTS ix_mart_cafe_competition_geom
    ON mart.cafe_competition_2km USING GIST (geom);


/* =========================================================
   END OF 01 DATA PIPELINE
========================================================= */
