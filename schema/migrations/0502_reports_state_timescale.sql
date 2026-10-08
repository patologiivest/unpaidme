CREATE MATERIALIZED VIEW reports.cases_in_progress 
WITH (timescaledb.continuous) AS
select 
case_id,
time_bucket(interval '7 days', happened_at) as week,
min(
case 
	when event_name = 20 then happened_at
	else null
end) as opened_at,
min(
case 
	when event_name in (98, 99, 102, 103) then happened_at
	else null
end) as closed_at
from trans.events e 
group by case_id, week;

SELECT add_continuous_aggregate_policy('reports.production_view',
  schedule_interval => INTERVAL '1 day'); -- set `start_offset` and `enf_offset` if needed
