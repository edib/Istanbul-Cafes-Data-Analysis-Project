/* =========================================================
   04_demand_and_quality_analysis
   Demand & quality layer (NO competition, NO decision)
   ========================================================= */


/* =========================================================
   1) Pedestrian Activity Proxy (Cafe-Based Heatmap)
   Dataset: viz.v_traffic_heatmap_final
   ========================================================= */

DROP VIEW IF EXISTS viz.v_traffic_heatmap_final;

CREATE VIEW viz.v_traffic_heatmap_final AS
SELECT
    grid_id,

    -- Superset için WGS84
    ST_Y(centroid_4326) AS lat,
    ST_X(centroid_4326) AS lon,

    -- Cafe-based pedestrian activity proxy
    CASE
        WHEN cafe_count = 0 THEN 0
        ELSE
            (10 * cafe_count)
          + (0.1 * COALESCE(total_reviews, 0))
    END AS heat_weight

FROM viz.grid_traffic_500m
WHERE centroid_4326 IS NOT NULL;



/* =========================================================
   2) Relationship Between Cafe Ratings and Review Volume
   Dataset: mart.v_scatter_cafe_rating_reviews
   ========================================================= */

DROP VIEW IF EXISTS mart.v_scatter_cafe_rating_reviews;

CREATE VIEW mart.v_scatter_cafe_rating_reviews AS
SELECT
    place_id,
    name,
    district,

    -- Ana metrikler
    rating,
    user_ratings_total,

    -- Log transform (visibility normalization)
    LOG(1 + user_ratings_total) AS user_ratings_log,

    -- Segmentasyon
    rating_band_fine,

    -- Tooltip / bağlamsal alanlar
    price_level,
    business_status,
    google_maps_url,

    -- Geometri (ileride map için)
    geom

FROM mart.map_points_enriched
WHERE
    rating IS NOT NULL
    AND user_ratings_total IS NOT NULL
    AND user_ratings_total > 0;



/* =========================================================
   3) Price–Quality Value Index by Price Segment
   Dataset: mart.v_price_value_index
   ========================================================= */

DROP VIEW IF EXISTS mart.v_price_value_index;

CREATE VIEW mart.v_price_value_index AS
SELECT
    price_level_bucket,

    COUNT(DISTINCT place_id) AS cafe_count,

    AVG(rating) AS avg_rating,

    AVG(LOG(1 + user_ratings_total)) AS avg_log_reviews,

    -- Analitik fiyat ağırlığı
    CASE price_level_bucket
        WHEN 'Cheap' THEN 1.0
        WHEN 'Mid' THEN 1.2
        WHEN 'Expensive' THEN 1.5
        ELSE NULL
    END AS price_weight,

    -- Price–Quality Value Score
    AVG(
        rating
        * LOG(1 + user_ratings_total)
        / CASE price_level_bucket
            WHEN 'Cheap' THEN 1.0
            WHEN 'Mid' THEN 1.2
            WHEN 'Expensive' THEN 1.5
          END
    ) AS price_value_score

FROM mart.v_price_level_analysis
WHERE
    price_level_bucket IS NOT NULL
    AND price_level_bucket <> 'Unknown'
    AND review_reliability = 'Reliable'
GROUP BY price_level_bucket;
