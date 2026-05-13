-- Populate the customers table with ~1,000,000 rows whose distribution
-- is engineered to reproduce the numbers shown on the slides:
--
--   * 50 distinct states (n_distinct=50 for state)
--   * CA ~18%, TX ~12%, NY ~9%, FL ~7%, IL ~5% (top MCVs)
--   * WY very rare (~0.45%)
--   * Cheyenne dominates WY (~89% of WY rows) -> demonstrates the
--     independence-assumption blow-up for (city, state) together
--   * signup_date inserted monotonically -> high correlation (~1.0)
--   * city ~20,000 distinct values across the table
--
-- The data is intentionally inserted *grouped by state* so that the
-- physical order shows the correlation effect for the `state` column.

\echo '>>> generating ~1,000,000 rows (this takes ~10-20 seconds)'

SET seed = 0.42;

-- Weight column controls the relative frequency of each state.
-- primary_city is the dominant city inside that state.
-- primary_share is the fraction of that state's rows assigned to its
-- primary city; the remainder is spread across ~400 generated cities.
WITH state_weights(state, w, primary_city, primary_share) AS (VALUES
    -- top-5 (these produce the MCV percentages on the slides)
    ('CA', 180.0, 'Los Angeles',  0.30),
    ('TX', 120.0, 'Houston',      0.25),
    ('NY',  90.0, 'New York',     0.40),
    ('FL',  70.0, 'Miami',        0.25),
    ('IL',  50.0, 'Chicago',      0.45),
    -- mid-tier states
    ('PA',  40.0, 'Philadelphia', 0.30),
    ('OH',  35.0, 'Columbus',     0.25),
    ('GA',  32.0, 'Atlanta',      0.30),
    ('NC',  30.0, 'Charlotte',    0.25),
    ('MI',  28.0, 'Detroit',      0.25),
    ('NJ',  25.0, 'Newark',       0.20),
    ('VA',  22.0, 'Richmond',     0.20),
    ('WA',  21.0, 'Seattle',      0.40),
    ('AZ',  20.0, 'Phoenix',      0.45),
    ('MA',  19.0, 'Boston',       0.40),
    ('TN',  18.0, 'Nashville',    0.30),
    ('IN',  17.0, 'Indianapolis', 0.35),
    ('MO',  16.0, 'Kansas City',  0.25),
    ('MD',  15.0, 'Baltimore',    0.35),
    ('WI',  14.0, 'Milwaukee',    0.30),
    ('CO',  13.0, 'Denver',       0.40),
    ('MN',  12.0, 'Minneapolis',  0.35),
    ('SC',  11.0, 'Columbia',     0.25),
    ('AL',  10.0, 'Birmingham',   0.30),
    ('LA',   9.5, 'New Orleans',  0.35),
    ('KY',   9.0, 'Louisville',   0.40),
    ('OR',   8.5, 'Portland',     0.50),
    ('OK',   8.0, 'Oklahoma City',0.40),
    ('CT',   7.5, 'Hartford',     0.30),
    ('UT',   7.0, 'Salt Lake City',0.50),
    ('IA',   6.5, 'Des Moines',   0.35),
    ('NV',   6.0, 'Las Vegas',    0.65),
    ('AR',   5.5, 'Little Rock',  0.35),
    ('MS',   5.0, 'Jackson',      0.30),
    ('KS',   4.8, 'Wichita',      0.35),
    ('NM',   4.7, 'Albuquerque',  0.55),
    ('NE',   4.6, 'Omaha',        0.45),
    ('ID',   4.5, 'Boise',        0.55),
    ('HI',   4.4, 'Honolulu',     0.70),
    ('NH',   4.3, 'Manchester',   0.30),
    ('ME',   4.2, 'Portland',     0.30),
    ('MT',   4.1, 'Billings',     0.30),
    ('RI',   4.0, 'Providence',   0.40),
    ('DE',   3.9, 'Wilmington',   0.45),
    ('SD',   3.8, 'Sioux Falls',  0.40),
    ('ND',   3.7, 'Fargo',        0.40),
    ('AK',   3.6, 'Anchorage',    0.50),
    ('VT',   3.5, 'Burlington',   0.30),
    ('WV',   3.4, 'Charleston',   0.30),
    -- the star of the show: Cheyenne dominates Wyoming
    ('WY',   4.5, 'Cheyenne',     0.89)
),
sw AS (
    -- normalize the weights to integer row counts that sum to ~1M
    SELECT state, primary_city, primary_share,
           floor(w / (SELECT sum(w) FROM state_weights) * 1000000)::int AS n
    FROM state_weights
),
expanded AS (
    -- Globally shuffle states across the table (so the physical
    -- correlation for `state` is ~0 and the planner has to choose
    -- between Seq Scan and Index Scan honestly), but assign
    -- signup_date from a monotonic row_number so dates stay
    -- highly correlated with physical position.
    SELECT
        state,
        primary_city,
        primary_share,
        row_number() OVER (ORDER BY random()) AS rn
    FROM sw, LATERAL generate_series(1, sw.n) AS g
)
INSERT INTO customers (city, state, signup_date)
SELECT
    CASE
        WHEN random() < primary_share
            THEN primary_city
        ELSE state || '-City-' || ((random() * 400)::int + 1)::text
    END,
    state,
    DATE '2020-01-01' + (rn / 549)::int  -- ~1,825 distinct dates
FROM expanded
ORDER BY rn;

\echo '>>> creating indexes'

CREATE INDEX customers_state_idx       ON customers (state);
CREATE INDEX customers_city_idx        ON customers (city);
CREATE INDEX customers_signup_date_idx ON customers (signup_date);
CREATE INDEX customers_city_state_idx  ON customers (city, state);

\echo '>>> ANALYZE'

ANALYZE customers;

\echo '>>> row count by state (top 8):'
SELECT state, count(*)
FROM customers
GROUP BY state
ORDER BY count(*) DESC
LIMIT 8;

\echo '>>> Cheyenne / WY sanity check:'
SELECT
    (SELECT count(*) FROM customers WHERE state = 'WY')                        AS wy_rows,
    (SELECT count(*) FROM customers WHERE city  = 'Cheyenne')                  AS cheyenne_rows,
    (SELECT count(*) FROM customers WHERE city  = 'Cheyenne' AND state = 'WY') AS cheyenne_wy_rows;

\echo '>>> done.'
