CREATE SCHEMA IF NOT EXISTS trans;


-- ANCHOR: patients
CREATE SEQUENCE IF NOT EXISTS trans.patients_seq;
CREATE TABLE IF NOT EXISTS trans.patients (
    id int8 NOT NULL DEFAULT nextval('trans.patients_seq'::regclass),
    external_id text NOT NULL,
    is_test bool NOT NULL DEFAULT false,
    CONSTRAINT patients_external_id_key UNIQUE (external_id),
    CONSTRAINT patients_pkey PRIMARY KEY (id)
);
-- ANCHOR_END: patients

-- ANCHOR: cases
CREATE SEQUENCE IF NOT EXISTS trans.cases_seq;
CREATE TABLE IF NOT EXISTS trans.cases (
    id int8 NOT NULL DEFAULT nextval('trans.cases_seq'::regclass),
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
    CONSTRAINT cases_lab_id_key UNIQUE (lab_id),
    CONSTRAINT cases_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT cases_requisition_id_key UNIQUE (requisition_id),
    CONSTRAINT cases_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS trans.case_codings (
    case_id int8 NOT NULL,
    code_id int8 NOT NULL,
    CONSTRAINT case_codings_pkey PRIMARY KEY (case_id, code_id)
);
CREATE INDEX case_codings_case_id_fkey_idx ON trans.case_codings (case_id);

CREATE TABLE IF NOT EXISTS trans.case_profiles (
    case_id int8 NOT NULL,
    case_profile int4 NOT NULL,
    CONSTRAINT case_profile_pkey PRIMARY KEY (case_id, case_profile)
);
-- ANCHOR_END:  cases

-- ANCHOR: specimen_containers 
CREATE SEQUENCE IF NOT EXISTS trans.specimen_containers_seq;
CREATE TABLE IF NOT EXISTS trans.specimen_containers (
    id int8 NOT NULL DEFAULT nextval('trans.specimen_containers_seq'::regclass),
    case_id int8 NOT NULL,
    legacy_id text NULL,
    container_no int4 NULL,
    specimen_type int4 NULL,
    fixation_method int4 NULL,
    CONSTRAINT specimen_containers_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT specimen_containers_pkey PRIMARY KEY (id)
);
-- ANCHOR_END: specimen_containers

-- ANCHOR: blocks
CREATE SEQUENCE IF NOT EXISTS trans.blocks_seq;
CREATE TABLE IF NOT EXISTS trans.blocks (
    id int8 NOT NULL DEFAULT nextval('trans.blocks_seq'::regclass),
    case_id int8 NOT NULL,
    block_no int4 NULL,
    legacy_id text NULL,
    block_type int4 NULL,
    CONSTRAINT blocks_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT blocks_pkey PRIMARY KEY (id)
);
-- ANCHOR_END: blocks

-- ANCHOR: slides 
CREATE SEQUENCE IF NOT EXISTS trans.slides_seq;
CREATE TABLE IF NOT EXISTS trans.slides (
    id int8 NOT NULL DEFAULT nextval('trans.slides_seq'::regclass),
    block_id int8 NULL,
    case_id int8 NOT NULL,
    legacy_id text NULL,
    slide_no int4 NULL,
    slide_type int4 NULL,
    stain_type int4 NULL,
    CONSTRAINT slides_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT slides_pkey PRIMARY KEY (id)
);
-- ANCHOR_END: slides


-- ANCHOR: analyses
CREATE SEQUENCE IF NOT EXISTS trans.analyses_seq;
CREATE TABLE IF NOT EXISTS trans.analyses (
    id int8 NOT NULL DEFAULT nextval('trans.analyses_seq'::regclass),
    case_id int8 NOT NULL,
    legacy_id text NULL,
    analysis_type int4 NOT NULL,
    CONSTRAINT analyses_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT analyses_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX analyses_legacy_id_idx ON trans.analyses(legacy_id);
-- ANCHOR_END: analyses






-- ANCHOR: events
-- do not have an id (-> value objects)
CREATE TABLE IF NOT EXISTS trans.events (
    event_name int4 NOT NULL,
    event_type int4 NOT NULL,
    happened_at timestamptz NOT NULL,
    case_id int8 NOT NULL,
    token_id int8 NOT NULL,
    token_type int4 NOT NULL,
    revision int4 NOT NULL DEFAULT 1,
    actor_ref int4 NULL,
    workstation_ref int4 NULL,
    lab_ref int4 NULL
);
CREATE INDEX events_case_idx ON trans.events (case_id);
CREATE INDEX events_happened_at_idx ON trans.events (happened_at DESC);
CREATE INDEX events_token_idx ON trans.events (token_id);
-- ANCHOR_END: events




