CREATE TABLE IF NOT EXISTS table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x;
 --took 24 secs 10 million rows inserted
 
 SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
 
 
    DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all ROWS
               
--took 14 secs, still 456 mb because disk space hasnt been reclaimed yet

               
VACUUM FULL VERBOSE table_to_delete; 
--took 24 secs to vacuum
--used to be 456 mb after deleting third of the rows, after vacuuming it is 383mb, 
--row estimate matchs the original count, vacuuming reclaimed the disk space that delete didn't free up

DROP TABLE IF EXISTS table_to_delete;

CREATE TABLE table_to_delete AS 
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x

TRUNCATE table_to_delete;
--took 1 sec and space is nearly 0mb(8192 bytes),
--i can say that truncate is a fast operation because unlike delete and vacuum it doesn't unwind
--and just wipes every row
--in terms of speed from slowest to fastest vacuum full > delete > truncate 
