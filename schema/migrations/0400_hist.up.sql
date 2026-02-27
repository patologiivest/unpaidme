-- versioned history of the trans tables
CREATE SCHEMA IF NOT EXISTS hist;

CREATE TABLE IF NOT EXISTS hist.cases (
    id int8 NOT NULL,
    requisition_id text NULL,
    lab_id text NULL,
    legacy_id text NULL,
    patho_division int4 NULL,
    priority int4 NULL,
    patient int8 NULL,
    requisitioner int4 NULL,
    requisition_type int4 NULL,
    responsible_actor int4 NULL,
    specimen_type int4 NULL,
    specimen_containers int4 NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT cases_pkey PRIMARY KEY (id, valid_from)
);
CREATE INDEX hist_cases_id_idx ON hist.cases(id);


-- specimen containers 
CREATE TABLE IF NOT EXISTS hist.specimen_containers (
    id int8 NOT NULL,
    case_id int8 NOT NULL,
    legacy_id text NULL,
    container_no int4 NULL,
    specimen_type int4 NULL,
    fixation_method int4 NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT specimen_containers_pkey PRIMARY KEY (id, valid_from)
);
CREATE INDEX hist_specimen_containers_idx ON hist.specimen_containers(id);

-- blocks
CREATE TABLE IF NOT EXISTS hist.blocks (
    id int8 NOT NULL,
    case_id int8 NOT NULL,
    block_no int4 NULL,
    legacy_id text NULL,
    block_type int4 NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT blocks_pkey PRIMARY KEY (id, valid_from)
);
CREATE INDEX hist_blocks_idx ON hist.blocks(id);

-- slides 
CREATE TABLE IF NOT EXISTS hist.slides (
    id int8 NOT NULL,
    block_id int8 NULL,
    case_id int8 NOT NULL,
    legacy_id text NULL,
    slide_no int4 NULL,
    slide_type int4 NULL,
    stain_type int4 NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT slides_pkey PRIMARY KEY (id, valid_from)
);
CREATE INDEX hist_slides_idx ON hist.slides(id);


-- Analyes
CREATE TABLE IF NOT EXISTS hist.analyses (
    id int8 NOT NULL,
    case_id int8 NOT NULL,
    legacy_id text NULL,
    analysis_type int4 NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT analyses_pkey PRIMARY KEY (id, valid_from)
);
CREATE INDEX hist_analyses_idx ON hist.analyses(id);


-- ANCHOR: worklist
CREATE TABLE IF NOT EXISTS hist.worklist_cases (
    case_id int8 NOT NULL,
    actor_ref int4 NOT NULL,
    valid_from timestamp NOT NULL,
    valid_until timestamp NULL,
    in_role int4 NULL,
    CONSTRAINT hist_worklist_cases_pkey PRIMARY KEY (case_id, actor_ref, valid_from)
);
CREATE INDEX hist_worklist_case_id_idx ON hist.worklist_cases(case_id);
-- ANCHOR_END: worklist

CREATE TABLE IF NOT EXISTS hist.case_codings (
    case_id int8 NOT NULL,
    code_id int8 NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT case_codings_pkey PRIMARY KEY (case_id, code_id, valid_from)
);
CREATE INDEX case_codings_case_id_fkey_hist_idx ON hist.case_codings (case_id);


CREATE TABLE IF NOT EXISTS hist.case_profiles (
    case_id int8 NOT NULL,
    case_profile int4 NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_until timestamptz NULL,
    modified_by int4 NULL,
    CONSTRAINT case_profile_pkey PRIMARY KEY (case_id, case_profile, valid_from)
);
CREATE INDEX case_profiles_case_id_fkey_hist_idx ON hist.case_codings (case_id);







