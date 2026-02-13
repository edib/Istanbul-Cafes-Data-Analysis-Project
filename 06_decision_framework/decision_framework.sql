/* =========================================================
   06_decision_framework
   FINAL KARAR KATMANI (Prescriptive Analytics)
   ========================================================= */

/* =========================================================
   1) İlçe Bazlı Opportunity vs Competition
   (Scatter plot veri kaynağı)
   ========================================================= */

CREATE OR REPLACE VIEW mart.v_district_opportunity_vs_competition AS
SELECT
    d.district,
    d.opportunity_score,
    d.cafe_count,

    /* 2km yarıçapta ortalama rekabet seviyesi */
    AVG(c.competitors_within_2km)
        FILTER (WHERE c.competitors_within_2km IS NOT NULL)
        AS avg_competition_2km

FROM mart.district_summary d
LEFT JOIN mart.cafe_competition_2km c
    ON d.district = c.district

GROUP BY
    d.district,
    d.opportunity_score,
    d.cafe_count;


/* =========================================================
   2) Karar Öncesi Feature Tablosu
   ========================================================= */

CREATE OR REPLACE VIEW mart.v_final_opening_decision AS
WITH
/* İlçe bazında aktif trafik grid sayısı (ayağı var mı?) */
traffic_by_district AS (
    SELECT
        d.name_1 AS district,
        COUNT(DISTINCT g.grid_id)
            FILTER (WHERE h.heat_weight > 0) AS active_traffic_grids
    FROM public.istanbul_districts d
    LEFT JOIN mart.grid_heatmap_500m g
        ON ST_Contains(d.geom, g.cell_centroid_4326)
    LEFT JOIN viz.v_traffic_heatmap_final h
        ON g.grid_id = h.grid_id
    GROUP BY d.name_1
),

/* İlçe bazında ortalama rekabet (2km) */
competition_by_district AS (
    SELECT
        district,
        AVG(competitors_within_2km) AS avg_competition_2km
    FROM mart.cafe_competition_2km
    GROUP BY district
)

SELECT
    d.district,
    d.opportunity_score,
    d.cafe_count,
    d.avg_rating,
    c.avg_competition_2km,
    t.active_traffic_grids

FROM mart.district_summary d
LEFT JOIN competition_by_district c
    ON d.district = c.district
LEFT JOIN traffic_by_district t
    ON d.district = t.district;


/* =========================================================
   3) FINAL Karar Skoru (Normalize + Ağırlıklı)
   ========================================================= */

CREATE OR REPLACE VIEW mart.v_final_opening_decision_scored AS
WITH base AS (
    SELECT
        district,
        opportunity_score,
        cafe_count,
        avg_competition_2km,
        avg_rating
    FROM mart.v_final_opening_decision
),
stats AS (
    SELECT
        MIN(opportunity_score) AS min_op,
        MAX(opportunity_score) AS max_op,
        MIN(avg_competition_2km) AS min_comp,
        MAX(avg_competition_2km) AS max_comp,
        MIN(cafe_count) AS min_cafe,
        MAX(cafe_count) AS max_cafe,
        MIN(avg_rating) AS min_rating,
        MAX(avg_rating) AS max_rating
    FROM base
)

SELECT
    b.district,

    (
        /* Fırsat */
        0.40 * CASE
            WHEN s.max_op = s.min_op THEN 0.5
            ELSE (b.opportunity_score - s.min_op)
                 / NULLIF(s.max_op - s.min_op, 0)
        END

        /* Rekabet (ters) */
        + 0.30 * CASE
            WHEN b.avg_competition_2km IS NULL THEN 0.5
            WHEN s.max_comp = s.min_comp THEN 0.5
            ELSE 1 - (b.avg_competition_2km - s.min_comp)
                     / NULLIF(s.max_comp - s.min_comp, 0)
        END

        /* Pazar doygunluğu (ters) */
        + 0.20 * CASE
            WHEN s.max_cafe = s.min_cafe THEN 0.5
            ELSE 1 - (b.cafe_count - s.min_cafe)
                     / NULLIF(s.max_cafe - s.min_cafe, 0)
        END

        /* Mevcut kalite */
        + 0.10 * CASE
            WHEN s.max_rating = s.min_rating THEN 0.5
            ELSE (b.avg_rating - s.min_rating)
                 / NULLIF(s.max_rating - s.min_rating, 0)
        END
    ) AS decision_score

FROM base b
CROSS JOIN stats s;


/* =========================================================
   4) İş Dili Etiketleme Katmanı
   ========================================================= */

CREATE OR REPLACE VIEW mart.v_final_opening_decision_labeled AS
SELECT
    district,
    decision_score,
    CASE
        WHEN decision_score >= 0.70 THEN 'STRONG OPENING CANDIDATE'
        WHEN decision_score >= 0.60 THEN 'MEDIUM POTENTIAL'
        ELSE 'LOW PRIORITY'
    END AS decision_label
FROM mart.v_final_opening_decision_scored;
