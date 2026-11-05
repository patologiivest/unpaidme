-- Plain PostgreSQL or Timescale OSS
CREATE MATERIALIZED VIEW reports.production_view  AS
SELECT 
    event_name,
    event_type,
    lab_ref as lab_location,
    happened_at::date as production_day,
    COUNT(DISTINCT token_id)
FROM trans.events 
GROUP BY event_name, event_type, lab_location, happened_at::date;