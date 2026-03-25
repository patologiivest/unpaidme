-- Artifact lifecycle materialized views
-- These provide a pivoted, one-row-per-artifact overview of when major
-- workflow milestones were reached, derived from trans.events.
--
-- Refresh strategy:
--   REFRESH MATERIALIZED VIEW CONCURRENTLY reports.case_lifecycle;
--   REFRESH MATERIALIZED VIEW CONCURRENTLY reports.block_lifecycle;
--   REFRESH MATERIALIZED VIEW CONCURRENTLY reports.slide_lifecycle;
--
-- The refresh could be scheduled via pg_cron (e.g. every 5 minutes) or an application-level cron.
-- CONCURRENTLY requires the unique indexes created below and does NOT lock readers during refresh.


-- ANCHOR: cases
CREATE MATERIALIZED VIEW reports.case_lifecycle AS
SELECT
    case_id,
    MIN(happened_at) FILTER (
        WHERE event_name = 0  AND event_type = 0
    ) AS sampled_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 10 AND event_type = 0
    ) AS notified_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 20 AND event_type = 2
    ) AS accessioned_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 30 AND event_type = 2
    ) AS grossed_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 80 AND event_type = 0
    ) AS assigned_at,
    MIN(happened_at) FILTER (
        WHERE event_name in (98, 99) AND event_type = 0
    ) AS first_report_at,
    MAX(happened_at) FILTER (
        WHERE event_name in (99, 102, 103)  AND event_type = 0
    ) AS last_report_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 100 AND event_type = 0
    ) AS archived_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 101 AND event_type = 0
    ) AS reopened_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 110 AND event_type = 0
    ) AS answered_at,
    CASE
        WHEN MIN(happened_at) FILTER (WHERE event_name = 110  AND event_type = 0) IS NOT NULL THEN 'ANSWERED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 103 AND event_type = 0) IS NOT NULL THEN 'CORRECTED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 102 AND event_type = 0) IS NOT NULL THEN 'AUGMENTED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 101 AND event_type = 0) IS NOT NULL THEN 'REOPENED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 100 AND event_type = 0) IS NOT NULL THEN 'ARCHIVED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 99  AND event_type = 0) IS NOT NULL THEN 'CONCLUDED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 98  AND event_type = 0) IS NOT NULL THEN 'PRELIMINARY'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 80  AND event_type = 0) IS NOT NULL THEN 'ASSIGNED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 30  AND event_type = 2) IS NOT NULL THEN 'GROSSED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 20  AND event_type = 2) IS NOT NULL THEN 'ACCESSIONED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 10  AND event_type = 0) IS NOT NULL THEN 'NOTIFIED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 0   AND event_type = 0) IS NOT NULL THEN 'SAMPLED'
        ELSE 'UNKNOWN'
    END AS current_phase
FROM trans.events
WHERE token_type = 0
GROUP BY case_id;

CREATE UNIQUE INDEX case_lifecycle_case_id_idx ON reports.case_lifecycle (case_id);
-- ANCHOR_END: cases


-- ANCHOR: block
CREATE MATERIALIZED VIEW reports.block_lifecycle AS
SELECT
    case_id,
    token_id AS block_id,
    MIN(happened_at) FILTER (
        WHERE event_name = 35 AND event_type = 0
    ) AS printed_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 40 AND event_type = 2
    ) AS processed_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 42 AND event_type = 2
    ) AS decalcinated_at,
    MIN(happened_at) FILTER (
        WHERE event_name IN (50, 51) AND event_type = 2
    ) AS embedded_at,
    MIN(happened_at) FILTER (
        WHERE event_name IN (60, 61) AND event_type = 2
    ) AS sectioned_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 67 AND event_type = 0
    ) AS archived_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 68 AND event_type = 0
    ) AS retrieved_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 69 AND event_type = 0
    ) AS destroyed_at,
    CASE
        WHEN MIN(happened_at) FILTER (WHERE event_name = 69 AND event_type = 0) IS NOT NULL THEN 'DESTROYED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 68 AND event_type = 0) IS NOT NULL THEN 'RETRIEVED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 67 AND event_type = 0) IS NOT NULL THEN 'ARCHIVED'
        WHEN MIN(happened_at) FILTER (WHERE event_name IN (60, 61) AND event_type = 2) IS NOT NULL THEN 'SECTIONED'
        WHEN MIN(happened_at) FILTER (WHERE event_name IN (50, 51) AND event_type = 2) IS NOT NULL THEN 'EMBEDDED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 41 AND event_type = 2) IS NOT NULL THEN 'DECALCINATED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 40 AND event_type = 2) IS NOT NULL THEN 'PROCESSED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 35 AND event_type = 0) IS NOT NULL THEN 'PRINTED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 30 AND event_type = 2) IS NOT NULL THEN 'GROSSED'
        ELSE 'UNKNOWN'
    END AS current_phase
FROM trans.events
WHERE token_type = 2
GROUP BY token_id, case_id;

CREATE UNIQUE INDEX block_lifecycle_block_id_idx
    ON reports.block_lifecycle (block_id);
CREATE INDEX block_lifecycle_block_caseid_idx
    ON reports.block_lifecycle (case_id);
-- ANCHOR_END: block


-- ANCHOR: slide
CREATE MATERIALIZED VIEW reports.slide_lifecycle AS
SELECT
    case_id,
    token_id  AS slide_id,
    MIN(happened_at) FILTER (
        WHERE event_name = 66 AND event_type = 0
    ) AS printed_at,
    MIN(happened_at) FILTER (
        WHERE event_name IN (70, 71, 72) AND event_type = 2
    ) AS stained_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 85 AND event_type = 2
    ) AS scanned_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 87 AND event_type = 2
    ) AS archived_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 88 AND event_type = 2
    ) AS retrieved_at,
    MIN(happened_at) FILTER (
        WHERE event_name = 89 AND event_type = 2
    ) AS destroyed_at,
    CASE
        WHEN MIN(happened_at) FILTER (WHERE event_name = 89 AND event_type = 2) IS NOT NULL THEN 'DESTROYED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 88 AND event_type = 2) IS NOT NULL THEN 'RETRIEVED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 87 AND event_type = 2) IS NOT NULL THEN 'ARCHIVED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 85 AND event_type = 2) IS NOT NULL THEN 'SCANNED'
        WHEN MIN(happened_at) FILTER (WHERE event_name IN (70, 71, 72) AND event_type = 2) IS NOT NULL THEN 'STAINED'
        WHEN MIN(happened_at) FILTER (WHERE event_name = 66 AND event_type = 0) IS NOT NULL THEN 'PRINTED'
        ELSE 'UNKNOWN'
    END AS current_phase
FROM trans.events
WHERE token_type = 3
GROUP BY token_id, case_id;

CREATE UNIQUE INDEX slide_lifecycle_slide_id_idx
    ON reports.slide_lifecycle (slide_id);
CREATE INDEX slide_lifecycle_slide_caseid_idx
    ON reports.slide_lifecycle (case_id);
-- ANCHOR_END: slide


-- TODO: 
CREATE VIEW reports.case_arrears AS 
SELECT 
    case_id, 
    patho_division,
    priority
FROM reports.case_lifecycle r 
WHERE 
    (r.accessioned_at IS NOT NULL AND r.accessioned_at < now())
    AND (r.first_report_at IS NULL OR r.first_report_at > now());
