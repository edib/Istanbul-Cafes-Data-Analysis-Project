

--  KPI Overview (Dashboard Big Numbers)
SELECT
    COUNT(*) AS total_cafes,
    AVG(rating) AS avg_rating,
    COUNT(*) FILTER (WHERE rating >= 4.5) AS high_rating_cafes,
    AVG(user_ratings_total) AS avg_reviews,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE business_status ILIKE '%OPERATIONAL%')
        / NULLIF(COUNT(*), 0),
        2
    ) AS operational_pct
FROM clean.cafes;


--  Cafe Count by District
SELECT
    district,
    COUNT(*) AS cafe_count
FROM clean.cafes
WHERE district IS NOT NULL
GROUP BY district
ORDER BY cafe_count DESC;


--  Rating Distribution (Fine-Grain)
SELECT
    rating,
    COUNT(*) AS cafe_count
FROM clean.cafes
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY rating;


-- Review Count Distribution
SELECT
    user_ratings_total
FROM clean.cafes
WHERE user_ratings_total IS NOT NULL;


-- 2km Competition Distribution
SELECT
    competitors_within_2km
FROM mart.cafe_competition_2km
WHERE competitors_within_2km IS NOT NULL;
