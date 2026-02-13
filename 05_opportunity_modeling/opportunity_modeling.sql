/* =========================================================
   05_opportunity_modeling
   District-level opportunity & category gap modeling
   ========================================================= */


/* ---------------------------------------------------------
   (1) Base district aggregation from clean.cafes
   District-level analytical summary (no normalization yet)
---------------------------------------------------------- */

DROP TABLE IF EXISTS mart.district_summary;

CREATE TABLE mart.district_summary AS
WITH base AS (
    SELECT
        district,
        COUNT(*) AS cafe_count,
        AVG(rating) AS avg_rating,
        COUNT(*) FILTER (WHERE rating >= 4.5) AS high_quality_count,
        AVG(price_level) AS avg_price_level,
        SUM(user_ratings_total) AS total_reviews,
        AVG(user_ratings_total) AS avg_reviews
    FROM clean.cafes
    WHERE district IS NOT NULL
    GROUP BY district
),

/* ---------------------------------------------------------
   (2) Min–max normalization of key metrics
   All metrics scaled to [0,1]
---------------------------------------------------------- */
normalized AS (
    SELECT
        district,
        cafe_count,
        avg_rating,
        high_quality_count,
        avg_price_level,
        total_reviews,
        avg_reviews,

        (avg_rating - MIN(avg_rating) OVER ())
        / NULLIF(MAX(avg_rating) OVER () - MIN(avg_rating) OVER (), 0)
            AS avg_rating_norm,

        (total_reviews - MIN(total_reviews) OVER ())
        / NULLIF(MAX(total_reviews) OVER () - MIN(total_reviews) OVER (), 0)
            AS total_reviews_norm,

        (cafe_count - MIN(cafe_count) OVER ())
        / NULLIF(MAX(cafe_count) OVER () - MIN(cafe_count) OVER (), 0)
            AS cafe_count_norm
    FROM base
)

/* ---------------------------------------------------------
   (3) Final opportunity score calculation
   Demand + Quality − Supply (inverse)
---------------------------------------------------------- */
SELECT
    district,
    cafe_count,
    avg_rating,
    high_quality_count,
    avg_price_level,
    total_reviews,
    avg_reviews,

    avg_rating_norm,
    total_reviews_norm,
    cafe_count_norm,

    (
        0.45 * total_reviews_norm +
        0.45 * avg_rating_norm +
        0.35 * (1 - cafe_count_norm)
    ) AS opportunity_score
FROM normalized;



/* =========================================================
   (4) District × category gap analysis
   Identifies underrepresented cafe-related concepts
   ========================================================= */

DROP TABLE IF EXISTS mart.opportunity_gaps;

CREATE TABLE mart.opportunity_gaps AS
WITH district_type_counts AS (
    SELECT
        district,
        type_token,
        COUNT(*) AS cafe_count
    FROM clean.cafes
    WHERE district IS NOT NULL
      AND type_token IN ('cafe', 'restaurant', 'bakery', 'meal_takeaway')
    GROUP BY district, type_token
),

district_totals AS (
    SELECT
        district,
        SUM(cafe_count) AS district_total
    FROM district_type_counts
    GROUP BY district
),

district_shares AS (
    SELECT
        d.district,
        d.type_token,
        d.cafe_count,
        t.district_total,
        d.cafe_count::double precision / t.district_total
            AS district_type_share
    FROM district_type_counts d
    JOIN district_totals t
      ON d.district = t.district
),

global_shares AS (
    SELECT
        type_token,
        SUM(cafe_count)::double precision
        / SUM(SUM(cafe_count)) OVER ()
            AS global_type_share
    FROM district_type_counts
    GROUP BY type_token
)

/* ---------------------------------------------------------
   (5) Gap score calculation
   Positive gap = underrepresentation
---------------------------------------------------------- */
SELECT
    ds.district,
    ds.type_token,
    ds.cafe_count,
    ds.district_total,
    ds.district_type_share,
    gs.global_type_share,
    (gs.global_type_share - ds.district_type_share) AS gap_score
FROM district_shares ds
JOIN global_shares gs
  ON ds.type_token = gs.type_token;
