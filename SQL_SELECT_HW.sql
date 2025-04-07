-- Explanation:
-- 1. Avoided hardcoding IDs to make the queries reusable.
-- 2. Used explicit JOIN types (INNER/LEFT/RIGHT) for clarity and control over results.
-- 3. Avoided window functions as requested.
-- 4. Followed SQL code formatting standards for readability.
-- 5. Ensured queries can run without errors when executed sequentially.

-- 1. Animation movies (2017-2019) with rating > 1, ordered alphabetically
SELECT f.title
FROM public.film AS f
INNER JOIN public.film_category AS fc ON fc.film_id = f.film_id
INNER JOIN public.category AS c ON fc.category_id = c.category_id
WHERE f.release_year BETWEEN 2017 AND 2019
  AND UPPER(c.name) = 'ANIMATION'
  AND f.rental_rate > 1
ORDER BY f.title;

-- 2. Revenue earned by each rental store after March 2017
SELECT CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS store_address,
       SUM(p.amount) AS total_revenue 
FROM public.inventory i
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id 
INNER JOIN public.payment p ON r.rental_id = p.rental_id 
INNER JOIN public.store s ON s.store_id = i.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date > '2017-03-31' 
GROUP BY a.address, a.address2
ORDER BY total_revenue DESC;


-- 3. Top-5 actors by number of movies (after 2015)
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- 4. Number of Drama, Travel, Documentary movies per year
SELECT f.release_year,
       COUNT(CASE WHEN UPPER(c.name) = 'DRAMA' THEN 1 END) AS number_of_drama_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'TRAVEL' THEN 1 END) AS number_of_travel_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN 1 END) AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- Query 1: Which three employees generated the most revenue in 2017?
WITH employee_revenue AS (
    SELECT
        s.staff_id,
        s.first_name,
        s.last_name,
        st.store_id,
        a.address AS store_address,
        SUM(p.amount) AS total_revenue,
        MAX(DATE(p.payment_date)) AS last_rental_date
    FROM public.staff s
    INNER JOIN public.store st ON s.store_id = st.store_id
    INNER JOIN public.payment p ON s.staff_id = p.staff_id
    INNER JOIN public.address a ON st.address_id = a.address_id
    WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY s.staff_id, s.first_name, s.last_name, st.store_id, a.address
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
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS rental_count
    FROM public.rental r
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN public.film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT
    mr.title,
    mr.rental_count,
    CASE
        WHEN UPPER(mr.rating::text) = 'G' THEN 'All Ages'
        WHEN UPPER(mr.rating::text) = 'PG' THEN 'All Ages, but some material may not be suitable for children'
        WHEN UPPER(mr.rating::text) = 'PG-13' THEN 'Some material may be inappropriate for children under 13'
        WHEN UPPER(mr.rating::text) = 'R' THEN 'Restricted to viewers over 17 or 18'
        WHEN UPPER(mr.rating::text) = 'NC-17' THEN 'No one under 17 admitted'
        ELSE 'Unknown Rating'
    END AS expected_audience_age
FROM movie_rentals mr
ORDER BY mr.rental_count DESC
LIMIT 5;


-- Query to find the gap between the latest release year and current year per each actor
SELECT
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS latest_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS gap_from_current_year
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY gap_from_current_year DESC;

-- Query to find the gaps between sequential films per each actor 
SELECT
    a1.first_name,
    a1.last_name,
    f1.title AS movie_title_1,
    f1.release_year AS release_year_1,
    f2.title AS movie_title_2,
    f2.release_year AS release_year_2,
    (f2.release_year - f1.release_year) AS gap_between_movies
FROM public.actor a1
JOIN public.film_actor fa1 ON a1.actor_id = fa1.actor_id
JOIN public.film f1 ON fa1.film_id = f1.film_id
JOIN public.film_actor fa2 ON a1.actor_id = fa2.actor_id
JOIN public.film f2 ON fa2.film_id = f2.film_id
WHERE f2.release_year = (
    SELECT MIN(f3.release_year)
    FROM public.film_actor fa3
    JOIN public.film f3 ON fa3.film_id = f3.film_id
    WHERE fa3.actor_id = a1.actor_id
      AND f3.release_year > f1.release_year
)
ORDER BY a1.actor_id, f1.release_year;