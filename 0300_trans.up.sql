CREATE SCHEMA IF NOT EXISTS trans;

CREATE SEQUENCE IF NOT EXISTS trans.analyses_seq;
CREATE SEQUENCE IF NOT EXISTS trans.blocks_seq;
CREATE SEQUENCE IF NOT EXISTS trans.cases_seq;
CREATE SEQUENCE IF NOT EXISTS trans.patients_seq;
CREATE SEQUENCE IF NOT EXISTS trans.slides_seq;
CREATE SEQUENCE IF NOT EXISTS trans.specimen_containers_seq;

-- Patients
CREATE TABLE IF NOT EXISTS trans.patients (
    id int8 NOT NULL DEFAULT nextval('trans.patients_seq'::regclass),
    external_id text NOT NULL,
    dob date NULL,
    sex bpchar(1) NULL,
    CONSTRAINT patients_external_id_key UNIQUE (external_id),
    CONSTRAINT patients_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX patients_external_id_idx ON trans.patients (external_id);

-- Cases
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
    specimen_type int8 NULL,
    specimen_containers int4 NULL,
    CONSTRAINT cases_lab_id_key UNIQUE (lab_id),
    CONSTRAINT cases_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT cases_requisition_id_key UNIQUE (requisition_id),
    CONSTRAINT cases_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX cases_lab_id_idx ON trans.cases (lab_id);
CREATE UNIQUE INDEX cases_legacy_id_idx ON trans.cases (legacy_id);
CREATE UNIQUE INDEX cases_requisition_id_idx ON trans.cases (requisition_id);


-- specimen_conatiners
CREATE TABLE IF NOT EXISTS trans.specimen_containers (
    id int8 NOT NULL DEFAULT nextval('trans.specimen_containers_seq'::regclass),
    case_id int8 NOT NULL,
    legacy_id text NULL,
    container_no int4 NULL,
    specimen_type int8 NULL,
    fixation_method int4 NULL,
    CONSTRAINT specimen_containers_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT specimen_containers_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX specimen_containers_legacy_id_idx ON trans.specimen_containers USING btree (legacy_id);

-- blocks
CREATE TABLE IF NOT EXISTS trans.blocks (
    id int8 NOT NULL DEFAULT nextval('trans.blocks_seq'::regclass),
    case_id int8 NOT NULL,
    block_no int4 NULL,
    legacy_id text NULL,
    block_type int4 NULL,
    CONSTRAINT blocks_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT blocks_pkey PRIMARY KEY (id)
);
CREATE INDEX blocks_case_id_fkey_idx ON trans.blocks (case_id);
CREATE UNIQUE INDEX blocks_legacy_id_idx ON trans.blocks (legacy_id);

-- slides 
CREATE TABLE IF NOT EXISTS trans.slides (
    id int8 NOT NULL DEFAULT nextval('trans.slides_seq'::regclass),
    block_id int8 NULL,
    legacy_id varchar(255) NULL,
    slide_no int4 NULL,
    slide_type int4 NULL,
    stain_type int4 NULL,
    case_id int8 NOT NULL,
    CONSTRAINT slides_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT slides_pkey PRIMARY KEY (id)
);
CREATE INDEX slides_block_id_fk_idx ON trans.slides (block_id);
CREATE INDEX slides_case_id_fkey_idx ON trans.slides (case_id);
CREATE UNIQUE INDEX slides_legacy_id_idx ON trans.slides (legacy_id);


-- Analyes
CREATE TABLE IF NOT EXISTS trans.analyses (
    id int8 NOT NULL DEFAULT nextval('trans.analyses_seq'::regclass),
    case_id int8 NOT NULL,
    legacy_id varchar(255) NULL,
    analysis_type int4 NOT NULL,
    CONSTRAINT analyses_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT analyses_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX analyses_legacy_id_idx ON trans.analyses USING btree (legacy_id);

-- Codings
CREATE TABLE IF NOT EXISTS trans.case_codings (
    case_id int8 NOT NULL,
    code_id int8 NOT NULL,
    added_at timestamptz NOT NULL,
    added_by int4 NOT NULL,
    CONSTRAINT case_codings_pkey PRIMARY KEY (case_id, code_id)
);
CREATE INDEX case_codings_case_id_fkey_idx ON trans.case_codings (case_id);


-- Profiles
CREATE TABLE IF NOT EXISTS trans.case_profiles (
    case_id int8 NOT NULL,
    case_profile int4 NOT NULL,
    added_at timestamptz NULL,
    added_by int4 NULL,
    CONSTRAINT case_profile_pkey PRIMARY KEY (case_id, case_profile)
);
CREATE INDEX case_profile_case_id_fkey_idx ON trans.case_profiles (case_id);

-- worklist
CREATE TABLE IF NOT EXISTS trans.worklist_cases (
    case_id int8 NOT NULL,
    actor_ref int4 NOT NULL,
    valid_from timestamp NOT NULL,
    valid_until timestamp NULL,
    in_role int4 NULL
);
CREATE INDEX worklist_case_id_fke_idx ON trans.worklist_cases USING btree (case_id);

-- case accounting
CREATE TABLE trans.case_accounting (
	case_id int8 NOT NULL,
	accounting_profile int4 NOT NULL,
	CONSTRAINT case_accounting_pk PRIMARY KEY (case_id, accounting_profile)
);

-- Events
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
CREATE INDEX case_event_ts_idx ON trans.events (case_id, event_name, happened_at);
CREATE INDEX events_happened_at_idx ON trans.events (happened_at DESC);




