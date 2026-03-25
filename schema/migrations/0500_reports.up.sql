CREATE SCHEMA IF NOT EXISTS reports;

-- ANCHOR: specimen_types
create or replace view reports.specimen_types as 
select st.id, 
cv1.code as location_code, 
cv2.code as procedure_code, 
cv1.code_display_text as location_desc,
cv2.code_display_text as procedure_desc,
pd.name as patho_division
from master.specimen_types st
inner join master.code_values cv1 on cv1.id = st.loc_code
inner join master.code_values cv2 on cv2.id = st.proc_code
inner join config.patho_divisions pd on pd.id = st.patho_division 
where now() >= st.valid_from 
and (st.valid_until  is null or now() < st.valid_until)
order by id;
-- ANCHOR_END: specimen_types

-- ANCHOR: live_view
CREATE OR REPLACE VIEW reports.live_view AS 
SELECT 
    event_name,
    event_type,
    lab_ref as lab_location,
    COUNT(DISTINCT token_id)
FROM trans.events 
WHERE happened_at > (now()::DATE || ' 00:00:00 +00:00')::timestamptz -- adjust to your time-zone
AND happened_at <= now()
GROUP BY event_name, event_type, lab_location;


CREATE TABLE IF NOT EXISTS reports.live_view_config (
    event_name int4 not null,
    event_type int4 not null,
    lab_location int4 not null,
    station_name text not null,
    station_goal int4 null,
    station_workers float8 null,
    CONSTRAINT live_view_config_pkey PRIMARY KEY (event_name, event_type, lab_location)
);
-- ANCHOR_END: live_view

-- CREATE MATERIALIZED VIEW reports.regular_histology_cases_reg AS 
-- SELECT c.id,
--     MIN(
--         CASE
--             WHEN e.event_name = 0 THEN e.happened_at
--         ELSE 
--             NULL
--     ) AS sample_ts,
--     MIN(
--         CASE
--             WHEN e.event_name = 10 AND e.event_type = 2 THEN e.happened_at
--         ELSE 
--             NULL
--     ) AS notification_ts,
--     MIN(
--         CASE
--             WHEN e.event_name = 20 AND e.event_type = 2 THEN e.happened_at
--         ELSE 
--             NULL
--     ) AS registration_ts
--     FROM trans.cases c 
--         INNER JOIN trans.case_profiles p ON p.case_id = c.id
--         INNER JOIN trans.events e ON e.case_id = c.id
--     WHERE 
--         c.patho_division = 1 -- only histology
--         AND p.workflow_profile = 2 -- only normal cases (no frozen sections, no consultations)
--         AND e.event_anem IN (0, 10, 20)
--         AND e.happened_at <= now();

-- regular histology cases state 
-- regular histology blocks state 
-- regular histology slides state 

-- TODO: production view
