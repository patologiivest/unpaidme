-- requires timescaledb 2.7 or higher
CREATE MATERIALIZED VIEW reports.production_view 
WITH (timescaledb.continuous) AS
SELECT 
    event_name,
    event_type,
    lab_ref as lab_location,
    time_bucket(interval '1 day', happened_at) as production_day,
    COUNT(DISTINCT token_id)
FROM trans.events 
GROUP BY event_name, event_type, lab_location, production_day;

SELECT add_continuous_aggregate_policy('reports.production_view',
  schedule_interval => INTERVAL '1 day'); -- set `start_offset` and `enf_offset` if needed
