DROP TABLE IF EXISTS table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, (10^7)::int) x;

SELECT *, 
    pg_size_pretty(total_bytes) AS total,
    pg_size_pretty(index_bytes) AS index,
    pg_size_pretty(toast_bytes) AS toast,
    pg_size_pretty(table_bytes) AS table_size
FROM (
    SELECT *, 
        total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
    FROM (
        SELECT 
            c.oid,
            nspname AS table_schema,
            relname AS table_name,
            c.reltuples AS row_estimate,
            pg_total_relation_size(c.oid) AS total_bytes,
            pg_indexes_size(c.oid) AS index_bytes,
            pg_total_relation_size(c.reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

/*oid: 1
table_schema: public
table_name: table_to_delete
row_estimate: -1
total_bytes: 602447872
index_bytes: 0
toast_bytes: 8192
table_bytes: 602439680
total: 575 MB
index: 0 bytes
toast: 8192 bytes
table_size: 575 MB*/

-- DELETE 1/3 rows where the number part is divisible by 3
DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

/*time: 9sec
oid: 1
table_schema: public
table_name: table_to_delete
row_estimate: -1
total_bytes: 602415104
index_bytes: 0
toast_bytes: 8192
table_bytes: 602406912
total: 575 MB
index: 0 bytes
toast: 8192 bytes
table_size: 575 MB*/

VACUUM FULL VERBOSE table_to_delete;

/*time: 6.9sec
oid: 1
table_schema: public
table_name: table_to_delete
row_estimate: 6666667
total_bytes: 401612800
index_bytes: 0
toast_bytes: 8192
table_bytes: 401604608
total: 383 MB
index: 0 bytes
toast: 8192 bytes
table_size: 383 MB*/

TRUNCATE table_to_delete;

/*time: 0.28sec
oid: 1
table_schema: public
table_name: table_to_delete
row_estimate: 0
total_bytes: 8192
index_bytes: 0
toast_bytes: 8192
table_bytes: 0
total: 0 bytes
index: 0 bytes
toast: 8192 bytes
table_size: 0 bytes*/

/*Deleting rows does not reduce the disk space used.
VACUUM FULL It's effective but takes time and locks the table,
 which may affect availability.
TRUNCATE is extremely fast and instantly reclaims all space.

Conclusion:
DELETE followed by VACUUM FULL reclaims space but is slower. 
TRUNCATE is much faster but only useful when all rows are to be removed.*/