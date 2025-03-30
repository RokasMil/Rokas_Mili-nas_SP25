-- Explanation:
-- 1. Avoided hardcoding IDs to make the queries reusable.
-- 2. Used explicit JOIN types (INNER/LEFT/RIGHT) for clarity and control over results.
-- 3. Avoided window functions as requested.
-- 4. Followed SQL code formatting standards for readability.
-- 5. Ensured queries can run without errors when executed sequentially.

-- 1. Animation movies (2017-2019) with rating > 1, ordered alphabetically
SELECT m.title
FROM movies m
INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
INNER JOIN genres g ON mg.genre_id = g.genre_id
WHERE m.release_year BETWEEN 2017 AND 2019
  AND m.rating > 1
  AND g.genre = 'Animation'
ORDER BY m.title;

-- 2. Revenue earned by each rental store after March 2017
SELECT CONCAT(s.address, ' ', COALESCE(s.address2, '')) AS full_address, SUM(r.revenue) AS total_revenue
FROM rentals r
INNER JOIN stores s ON r.store_id = s.store_id
WHERE r.rental_date > '2017-03-31'
GROUP BY s.address, s.address2
ORDER BY total_revenue DESC;

-- 3. Top-5 actors by number of movies (after 2015)
SELECT a.first_name, a.last_name, COUNT(m.movie_id) AS number_of_movies
FROM actors a
INNER JOIN movie_actor ma ON a.actor_id = ma.actor_id
INNER JOIN movies m ON ma.movie_id = m.movie_id
WHERE m.release_year > 2015
GROUP BY a.first_name, a.last_name
ORDER BY COUNT(m.movie_id) DESC
LIMIT 5;

-- 4. Number of Drama, Travel, Documentary movies per year
SELECT m.release_year,
       COUNT(CASE WHEN g.genre = 'Drama' THEN 1 END) AS number_of_drama_movies,
       COUNT(CASE WHEN g.genre = 'Travel' THEN 1 END) AS number_of_travel_movies,
       COUNT(CASE WHEN g.genre = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM movies m
INNER JOIN movie_genre mg ON m.movie_id = mg.movie_id
INNER JOIN genres g ON mg.genre_id = g.genre_id
WHERE g.genre IN ('Drama', 'Travel', 'Documentary')
GROUP BY m.release_year
ORDER BY m.release_year DESC;

-----------------------------------------------------------------------

-- Query 1: Which three employees generated the most revenue in 2017?
WITH employee_revenue AS (
    SELECT
        e.employee_id,
        e.first_name,
        e.last_name,
        st.store_id,
        st.address AS store_address,
        SUM(r.revenue) AS total_revenue,
        MAX(r.rental_date) AS last_rental_date -- To pick the last store worked by the employee
    FROM rentals r
    INNER JOIN stores st ON r.store_id = st.store_id
    INNER JOIN employees e ON r.employee_id = e.employee_id
    WHERE r.rental_date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY e.employee_id, e.first_name, e.last_name, st.store_id, st.address
)
SELECT
    er.first_name,
    er.last_name,
    er.store_address,
    er.total_revenue
FROM employee_revenue er
ORDER BY er.total_revenue DESC
LIMIT 3;

-- Query 2: Which 5 movies were rented the most, and what's the expected age of the audience for these movies?
WITH movie_rentals AS (
    SELECT
        m.movie_id,
        m.title,
        m.rating,
        COUNT(r.rental_id) AS rental_count
    FROM rentals r
    INNER JOIN movies m ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title, m.rating
)
SELECT
    mr.title,
    mr.rental_count,
    CASE
        WHEN mr.rating = 'G' THEN 'All Ages'
        WHEN mr.rating = 'PG' THEN 'All Ages, but some material may not be suitable for children'
        WHEN mr.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13'
        WHEN mr.rating = 'R' THEN 'Restricted to viewers over 17 or 18'
        WHEN mr.rating = 'NC-17' THEN 'No one under 17 admitted'
        ELSE 'Unknown Rating'
    END AS expected_audience_age
FROM movie_rentals mr
ORDER BY mr.rental_count DESC
LIMIT 5;

-------------------------------------------------------------------------------
-- Query to find the gap between the latest release year and current year per each actor
SELECT
    a.first_name,
    a.last_name,
    MAX(m.release_year) AS latest_release_year,  -- The latest movie release year
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(m.release_year) AS gap_from_current_year
FROM actors a
INNER JOIN movie_cast mc ON a.actor_id = mc.actor_id
INNER JOIN movies m ON mc.movie_id = m.movie_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY gap_from_current_year DESC;

-- Query to find the gaps between sequential films per each actor 
SELECT
    a.first_name,
    a.last_name,
    m1.title AS movie_title_1,
    m1.release_year AS release_year_1,
    m2.title AS movie_title_2,
    m2.release_year AS release_year_2,
    (m2.release_year - m1.release_year) AS gap_between_movies
FROM actors a
INNER JOIN movie_cast mc1 ON a.actor_id = mc1.actor_id
INNER JOIN movies m1 ON mc1.movie_id = m1.movie_id
INNER JOIN movie_cast mc2 ON a.actor_id = mc2.actor_id
INNER JOIN movies m2 ON mc2.movie_id = m2.movie_id
WHERE m1.release_year < m2.release_year  -- To ensure we are looking at subsequent films
ORDER BY a.actor_id, m1.release_year;
