


--Task 1.
DO
$$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'sales_revenue_by_category_qtr') THEN
        DROP VIEW sales_revenue_by_category_qtr;
    END IF;

    -- Create the view
    CREATE VIEW sales_revenue_by_category_qtr AS
    WITH current_period AS (
        SELECT
            EXTRACT(YEAR FROM CURRENT_DATE) AS current_year,
            EXTRACT(QUARTER FROM CURRENT_DATE) AS current_quarter
    ),
    sales_data AS (
        SELECT
            c.name AS category_name,
            SUM(p.amount) AS total_revenue
        FROM
            public.payment p
            INNER JOIN public.rental r ON p.rental_id = r.rental_id
            INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
            INNER JOIN public.film f ON i.film_id = f.film_id
            INNER JOIN public.film_category fc ON f.film_id = fc.film_id
            INNER JOIN public.category c ON fc.category_id = c.category_id
        WHERE
            EXTRACT(YEAR FROM p.payment_date) = (SELECT current_year FROM current_period)
            AND EXTRACT(QUARTER FROM p.payment_date) = (SELECT current_quarter FROM current_period)
        GROUP BY
            c.name
        HAVING
            SUM(p.amount) > 0 -- Ensure at least one sale
    )
    SELECT
        category_name,
        total_revenue
    FROM
        sales_data;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating view sales_revenue_by_category_qtr: %', SQLERRM;
END
$$;


--Task 2. 
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(p_qtr_year TEXT)
RETURNS TABLE (
    category_name TEXT,
    quarter TEXT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        category_name,
        quarter,
        total_revenue
    FROM 
        sales_revenue_by_category_qtr
    WHERE 
        quarter = p_qtr_year;
END;
$$ LANGUAGE plpgsql;


--Task 3.
CREATE OR REPLACE FUNCTION get_most_popular_film_by_country(p_countries TEXT[])
RETURNS TABLE (
    country_name TEXT,
    film_title TEXT,
    rental_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH film_rentals AS (
        SELECT
            co.country AS country_name,
            f.title AS film_title,
            COUNT(r.rental_id) AS rental_count,
            ROW_NUMBER() OVER (PARTITION BY co.country ORDER BY COUNT(r.rental_id) DESC) AS rn
        FROM 
            rental r
        JOIN 
            inventory i ON r.inventory_id = i.inventory_id
        JOIN 
            film f ON i.film_id = f.film_id
        JOIN 
            customer c ON r.customer_id = c.customer_id
        JOIN 
            address a ON c.address_id = a.address_id
        JOIN 
            city ci ON a.city_id = ci.city_id
        JOIN 
            country co ON ci.country_id = co.country_id
        WHERE
            co.country = ANY(p_countries)
        GROUP BY 
            co.country, f.title
    )
    SELECT 
        film_rentals.country_name,
        film_rentals.film_title,
        film_rentals.rental_count
    FROM 
        film_rentals
    WHERE 
        film_rentals.rn = 1;
END;
$$ LANGUAGE plpgsql;


--Task 4.
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(p_partial_title TEXT)
RETURNS TABLE (
    row_num INT,
    film_title TEXT,
    available_inventory INT
) AS $$
DECLARE
    film_count INT;
BEGIN
    SELECT COUNT(*) INTO film_count
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
    WHERE f.title ILIKE p_partial_title
      AND r.rental_id IS NULL;  

    IF film_count = 0 THEN
        RAISE EXCEPTION 'No films found matching %', p_partial_title;
    END IF;

    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY f.title) AS row_num,
        f.title AS film_title,
        COUNT(i.inventory_id) AS available_inventory
    FROM 
        public.film f
    JOIN 
        public.inventory i ON f.film_id = i.film_id
    LEFT JOIN 
       public.rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
    WHERE 
        f.title ILIKE p_partial_title
        AND r.rental_id IS NULL
    GROUP BY 
        f.title;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM public.films_in_stock_by_title('%love%');


--Task 5.
DROP FUNCTION IF EXISTS new_movie(VARCHAR);

CREATE OR REPLACE FUNCTION new_movie(movie_title VARCHAR)
RETURNS VOID AS $$
DECLARE
    current_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
    movie_language VARCHAR := 'Klingon';
    language_exists INT;
    language_id INT;
BEGIN
    SELECT COUNT(*) INTO language_exists
    FROM language
    WHERE language.name = movie_language;

    IF language_exists = 0 THEN
        INSERT INTO language(name) 
        VALUES (movie_language)
        RETURNING language.language_id INTO language_id;
    ELSE
        SELECT language.language_id INTO language_id
        FROM language
        WHERE language.name = movie_language
        LIMIT 1;
    END IF;

    INSERT INTO film (
        title,
        rental_rate,
        rental_duration,
        replacement_cost,
        release_year,
        language_id
    )
    VALUES (
        movie_title,
        4.99,  
        3,   
        19.99, 
        current_year, 
        language_id  

END;
$$ LANGUAGE plpgsql;



