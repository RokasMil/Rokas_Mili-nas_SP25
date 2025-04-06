INSERT INTO film (
    title,
    description,
    release_year,
    language_id,
    original_language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    last_update,
    special_features
)
SELECT * FROM (
    SELECT 
        'Inception' AS title,
        'A mind-bending thriller' AS description,
        2010 AS release_year,
        1 AS language_id,
        NULL::smallint AS original_language_id,
        7 AS rental_duration,
        4.99 AS rental_rate,
        148 AS length,
        29.99 AS replacement_cost,
        'PG-13'::mpaa_rating AS rating,
        CURRENT_DATE AS last_update,
        ARRAY['Behind the Scenes', 'Commentaries']::text[] AS special_features
        
    UNION ALL

    SELECT 
        'The Matrix',
        'A hacker discovers reality is a simulation',
        1999,
        1,
        NULL,
        14,
        9.99,
        136,
        24.99,
        'R'::mpaa_rating,
        CURRENT_DATE,
        ARRAY['Deleted Scenes', 'Trailers']

    UNION ALL

    SELECT 
        'Interstellar',
        'Journey through space and time',
        2014,
        1,
        NULL,
        21,
        19.99,
        169,
        39.99,
        'PG-13'::mpaa_rating,
        CURRENT_DATE,
        ARRAY['Behind the Scenes']
) AS new_films
WHERE NOT EXISTS (
    SELECT 1 FROM film f WHERE f.title = new_films.title
)
RETURNING film_id, title;

-- Insert actors if not already in DB
INSERT INTO actor (first_name, last_name, last_update)
SELECT * FROM (
    SELECT 'Leonardo', 'DiCaprio', CURRENT_DATE
    UNION ALL SELECT 'Elliot', 'Page', CURRENT_DATE
    UNION ALL SELECT 'Keanu', 'Reeves', CURRENT_DATE
    UNION ALL SELECT 'Carrie-Anne', 'Moss', CURRENT_DATE
    UNION ALL SELECT 'Matthew', 'McConaughey', CURRENT_DATE
    UNION ALL SELECT 'Anne', 'Hathaway', CURRENT_DATE
) AS new_actors(first_name, last_name, last_update)
WHERE NOT EXISTS (
    SELECT 1 FROM actor a WHERE a.first_name = new_actors.first_name AND a.last_name = new_actors.last_name
)
RETURNING actor_id, first_name, last_name;

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, CURRENT_DATE
FROM actor a
JOIN film f ON (
    (f.title = 'Inception' AND a.first_name = 'Leonardo' AND a.last_name = 'DiCaprio') OR
    (f.title = 'Inception' AND a.first_name = 'Elliot' AND a.last_name = 'Page') OR
    (f.title = 'The Matrix' AND a.first_name = 'Keanu' AND a.last_name = 'Reeves') OR
    (f.title = 'The Matrix' AND a.first_name = 'Carrie-Anne' AND a.last_name = 'Moss') OR
    (f.title = 'Interstellar' AND a.first_name = 'Matthew' AND a.last_name = 'McConaughey') OR
    (f.title = 'Interstellar' AND a.first_name = 'Anne' AND a.last_name = 'Hathaway')
)
WHERE NOT EXISTS (
    SELECT 1 FROM film_actor fa
    WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

-- Add to store_id = 1 for simplicity
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, CURRENT_DATE
FROM film f
WHERE f.title IN ('Inception', 'The Matrix', 'Interstellar')
  AND NOT EXISTS (
    SELECT 1 FROM inventory i WHERE i.film_id = f.film_id AND i.store_id = 1
)
RETURNING inventory_id, film_id;

-- Select an existing customer with 43+ rentals and payments
SELECT c.customer_id, c.first_name, c.last_name, COUNT(DISTINCT r.rental_id) AS rentals, COUNT(DISTINCT p.payment_id) AS payments
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
LIMIT 1;

UPDATE customer
SET 
    store_id = 1,
    first_name = 'Rokas',
    last_name = 'Miliunas',
    email = 'miliunas.rokas@email.com',
    address_id = (
        SELECT address_id FROM address ORDER BY RANDOM() LIMIT 1
    ),
    activebool = TRUE,
    create_date = CURRENT_DATE,
    last_update = CURRENT_DATE,
    active = 1
WHERE customer_id = (SELECT c.customer_id FROM customer c
                        JOIN rental r ON c.customer_id = r.customer_id
                        JOIN payment p ON p.customer_id = c.customer_id
                        GROUP BY c.customer_id, c.first_name, c.last_name
                        HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
                        LIMIT 1);


SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas';
-- Remove payments and rentals made by you
DELETE FROM payment
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas');

DELETE FROM rental
WHERE customer_id =  (SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas');

-- Simulate rentals
-- Insert rental records for favorite movies
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT 
    DATE '2017-04-01', i.inventory_id, 
    (SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas' LIMIT 1), 
    DATE '2017-04-08', 1, CURRENT_DATE
FROM inventory i
JOIN film f ON f.film_id = i.film_id
WHERE f.title IN ('Inception', 'The Matrix', 'Interstellar')
RETURNING rental_id;

-- Pay for those rentals
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    (SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas' LIMIT 1),
    1, r.rental_id,
    CASE 
        WHEN f.title = 'Inception' THEN 4.99
        WHEN f.title = 'The Matrix' THEN 9.99
        WHEN f.title = 'Interstellar' THEN 19.99
    END,
    DATE '2017-04-01'
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Rokas' AND last_name = 'Miliunas' LIMIT 1)
RETURNING payment_id;