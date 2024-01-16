# Refreshing the views is required in Postgres, otherwise they
# will be empty as they were created before any data was loaded
# in the base tables.

REFRESH MATERIALIZED VIEW customer_pk;
REFRESH MATERIALIZED VIEW orders_pk;
