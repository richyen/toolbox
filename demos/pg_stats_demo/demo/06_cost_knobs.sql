-- ============================================================
-- Demo 6: How planner cost knobs flip index vs. seq scan
-- ============================================================
-- Goal: even with PERFECT stats, the planner's choice between
-- Index Scan and Seq Scan depends on the *cost model*. Three
-- knobs do most of the work:
--
--   random_page_cost   (default 4.0)  -- cost of a random page fetch
--                                        (dominates Index Scan cost)
--   seq_page_cost      (default 1.0)  -- cost of a sequential page fetch
--                                        (dominates Seq Scan cost)
--   cpu_tuple_cost     (default 0.01) -- per-tuple CPU cost
--                                        (hurts whichever plan touches
--                                         more rows -- usually Seq Scan)
--
-- We'll use state='WY' (rare, ~0.4% of the table) so the index
-- is genuinely useful, and show how each knob flips the plan.
-- ------------------------------------------------------------

-- Keep the contrast crisp: pure Seq Scan vs. pure Index Scan,
-- no bitmap plans. (Same trick as demo 02.)
SET enable_bitmapscan = off;

\echo
\echo '--- Current cost settings (defaults) ---'
SELECT name, setting, unit
FROM   pg_settings
WHERE  name IN ('random_page_cost', 'seq_page_cost',
                'cpu_tuple_cost',  'cpu_index_tuple_cost',
                'cpu_operator_cost', 'effective_cache_size')
ORDER  BY name;

\echo
\echo '============================================================'
\echo '  Baseline: state = ''WY'' (rare value, ~4,000 rows)'
\echo '============================================================'
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'WY';

\echo
\echo '------------------------------------------------------------'
\echo '  Knob 1: random_page_cost'
\echo '------------------------------------------------------------'
\echo
\echo '  Raise random_page_cost from 4.0 -> 40.0'
\echo '  (i.e., "random I/O is *very* expensive" -- old spinning rust)'
\echo '  Expect: planner abandons the index and Seq Scans the table.'
SET random_page_cost = 40.0;
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'WY';

\echo
\echo '  Drop random_page_cost from 4.0 -> 1.1'
\echo '  (i.e., "I am on an SSD, random ~= sequential")'
\echo '  Expect: planner happily Index Scans even less-rare values.'
SET random_page_cost = 1.1;
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'WY';

-- Try a more common state where the default plan was Seq Scan,
-- and see if SSD-style costs flip it to Index Scan.
\echo
\echo '  Same SSD-style costs, but for a COMMON state (NY, ~9%)'
\echo '  Default plan would be Seq Scan; with random_page_cost=1.1'
\echo '  the index may start to look attractive.'
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'NY';

RESET random_page_cost;

\echo
\echo '------------------------------------------------------------'
\echo '  Knob 2: seq_page_cost'
\echo '------------------------------------------------------------'
\echo
\echo '  Raise seq_page_cost from 1.0 -> 10.0 (state = ''WY'')'
\echo '  (i.e., "sequential reads are expensive too" -- not realistic,'
\echo '   but a clean way to show the *ratio* random/seq is what matters)'
\echo '  Expect: index looks relatively cheaper -- still Index Scan.'
SET seq_page_cost = 10.0;
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'WY';

RESET seq_page_cost;

\echo
\echo '------------------------------------------------------------'
\echo '  Knob 3: cpu_tuple_cost'
\echo '------------------------------------------------------------'
\echo
\echo '  Pick a mid-frequency state where the default plan is Seq Scan,'
\echo '  then raise cpu_tuple_cost. Seq Scan pays this cost on EVERY'
\echo '  row in the table; Index Scan only pays it on the matching rows.'
\echo '  Expect: high cpu_tuple_cost pushes the planner toward the index.'
\echo
\echo '  Default cpu_tuple_cost = 0.01, state = ''NY'''
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'NY';

\echo
\echo '  cpu_tuple_cost = 1.0  (100x the default)'
SET cpu_tuple_cost = 1.0;
EXPLAIN (COSTS)
SELECT * FROM customers WHERE state = 'NY';

RESET cpu_tuple_cost;

\echo
\echo '------------------------------------------------------------'
\echo '  Mental model'
\echo '------------------------------------------------------------'
\echo '  Index Scan cost  ~  (random_page_cost * matched_pages)'
\echo '                     + (cpu_tuple_cost  * matched_rows)'
\echo '                     + (cpu_index_tuple_cost * matched_index_entries)'
\echo
\echo '  Seq Scan cost    ~  (seq_page_cost    * table_pages)'
\echo '                     + (cpu_tuple_cost  * all_rows)'
\echo
\echo '  -> Lowering random_page_cost or raising cpu_tuple_cost'
\echo '     favors the index.'
\echo '  -> Raising random_page_cost or lowering cpu_tuple_cost'
\echo '     favors the seq scan.'
\echo '  -> What really matters is the *ratio* random_page_cost'
\echo '     /  seq_page_cost: 4.0 (spinning disks) vs ~1.1 (SSDs).'

RESET enable_bitmapscan;
