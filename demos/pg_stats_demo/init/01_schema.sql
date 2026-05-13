-- Schema for the pg_stats demo
-- A simple customers table with three columns of deliberately
-- different "shapes": skewed categorical (state), high-cardinality
-- (city) and time-correlated (signup_date).

\echo '>>> creating schema'

CREATE TABLE customers (
    id          bigserial PRIMARY KEY,
    city        text NOT NULL,
    state       text NOT NULL,
    signup_date date NOT NULL
);
