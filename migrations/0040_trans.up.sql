CREATE SCHEMA IF NOT EXISTS trans;

CREATE SEQUENCE IF NOT EXISTS trans.analyses_seq;
CREATE SEQUENCE IF NOT EXISTS trans.blocks_seq;
CREATE SEQUENCE IF NOT EXISTS trans.cases_seq;
CREATE SEQUENCE IF NOT EXISTS trans.patients_seq;
CREATE SEQUENCE IF NOT EXISTS trans.slides_seq;
CREATE SEQUENCE IF NOT EXISTS trans.specimen_containers_seq;


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



CREATE TABLE IF NOT EXISTS trans.patients (
    id int8 NOT NULL DEFAULT nextval('trans.patients_seq'::regclass),
    external_id varchar(255) NOT NULL,
    dob date NULL,
    sex bpchar(1) NULL,
    CONSTRAINT patients_external_id_key UNIQUE (external_id),
    CONSTRAINT patients_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX patients_external_id_idx ON trans.patients (external_id);



CREATE TABLE IF NOT EXISTS trans.analyses (
    id int8 NOT NULL DEFAULT nextval('trans.analyses_seq'::regclass),
    case_id int8 NOT NULL,
    legacy_id varchar(255) NULL,
    coding int8 NOT NULL,
    ordered_by int4 NOT NULL,
    CONSTRAINT analyses_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT analyses_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX analyses_legacy_id_idx ON trans.analyses USING btree (legacy_id);


CREATE TABLE IF NOT EXISTS trans.blocks (
    id int8 NOT NULL DEFAULT nextval('trans.blocks_seq'::regclass),
    case_id int8 NOT NULL,
    block_no int4 NULL,
    legacy_id varchar(255) NULL,
    specimen_container int8 NULL,
    block_type int4 NULL,
    CONSTRAINT blocks_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT blocks_pkey PRIMARY KEY (id)
);
CREATE INDEX blocks_case_id_fkey_idx ON trans.blocks (case_id);
CREATE UNIQUE INDEX blocks_legacy_id_idx ON trans.blocks (legacy_id);



CREATE TABLE IF NOT EXISTS trans.case_codings (
    case_id int8 NOT NULL,
    code_id int8 NOT NULL,
    added_at timestamp NOT NULL,
    added_by int4 NOT NULL,
    CONSTRAINT case_codings_pkey PRIMARY KEY (case_id, code_id)
);
CREATE INDEX case_codings_case_id_fkey_idx ON trans.case_codings (case_id);


CREATE TABLE IF NOT EXISTS trans.case_profiles (
    case_id int8 NOT NULL,
    case_profile int4 NOT NULL,
    CONSTRAINT case_profile_pkey PRIMARY KEY (case_id, case_profile)
);
CREATE INDEX case_profile_case_id_fkey_idx ON trans.case_profiles (case_id);


CREATE TABLE IF NOT EXISTS trans.cases (
    id int8 NOT NULL DEFAULT nextval('trans.cases_seq'::regclass),
    requisition_id varchar(50) NULL,
    lab_id varchar(50) NULL,
    legacy_id varchar(50) NULL,
    patho_division int4 NOT NULL,
    priority int4 NULL,
    patient int8 NULL,
    requisitioner int4 NULL,
    requisition_type int4 NULL,
    accounting_profile int4 NULL,
    responsible_actor int4 NULL,
    specimen_type int8 NULL,
    specimen_containers int4 NULL,
    CONSTRAINT cases_lab_id_key UNIQUE (lab_id),
    CONSTRAINT cases_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT cases_pkey PRIMARY KEY (id),
    CONSTRAINT cases_requisition_id_key UNIQUE (requisition_id)
);
CREATE UNIQUE INDEX cases_lab_id_idx ON trans.cases (lab_id);
CREATE UNIQUE INDEX cases_legacy_id_idx ON trans.cases (legacy_id);
CREATE UNIQUE INDEX cases_requisition_id_idx ON trans.cases (requisition_id);


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


CREATE TABLE IF NOT EXISTS trans.specimen_containers (
    id int8 NOT NULL,
    case_id int8 NOT NULL,
    legacy_id varchar(255) NULL,
    container_no int4 NOT NULL,
    specimen_type int8 NOT NULL,
    fixation_method int4 NULL,
    CONSTRAINT specimen_containers_case_id_container_no_key UNIQUE (case_id, container_no),
    CONSTRAINT specimen_containers_legacy_id_key UNIQUE (legacy_id),
    CONSTRAINT specimen_containers_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX specimen_containers_legacy_id_idx ON trans.specimen_containers USING btree (legacy_id);


CREATE TABLE IF NOT EXISTS trans.worklist_cases (
    case_id int8 NOT NULL,
    actor_ref int4 NOT NULL,
    valid_from timestamp NOT NULL,
    valid_until timestamp NULL,
    in_role int4 NULL
);
CREATE INDEX worklist_case_id_fke_idx ON trans.worklist_cases USING btree (case_id);

-- trans.analyses foreign keys
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_coding_fkey FOREIGN KEY (coding) REFERENCES config.analysis_methods(id);
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_ordered_by_fkey FOREIGN KEY (ordered_by) REFERENCES master.actors(id);
-- trans.blocks foreign keys
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_block_type_fkey FOREIGN KEY (block_type) REFERENCES config.block_types(id);
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_specimen_container_fkey FOREIGN KEY (specimen_container) REFERENCES trans.specimen_containers(id);
-- trans.case_codings foreign keys
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_code_id_fkey FOREIGN KEY (code_id) REFERENCES master.code_values(id);
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_fk FOREIGN KEY (added_by) REFERENCES master.actors(id);
-- trans.case_profiles foreign keys
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_profile_fkey FOREIGN KEY (case_profile) REFERENCES config.workflow_profiles(id);
-- trans.cases foreign keys
ALTER TABLE trans.cases ADD CONSTRAINT cases_accounting_profile_fkey FOREIGN KEY (accounting_profile) REFERENCES master.enum_accounting_profile(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_patho_division_fkey FOREIGN KEY (patho_division) REFERENCES config.patho_division(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_patient_fkey FOREIGN KEY (patient) REFERENCES trans.patients(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_priority_fkey FOREIGN KEY (priority) REFERENCES config.case_priority(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_requisition_type_fkey FOREIGN KEY (requisition_type) REFERENCES config.requisition_type(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_requisitioner_fkey FOREIGN KEY (requisitioner) REFERENCES master.requisitioners(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_responsible_actor_fkey FOREIGN KEY (responsible_actor) REFERENCES master.actors(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
-- trans.slides foreign keys
ALTER TABLE trans.slides ADD CONSTRAINT slides_block_id_fkey FOREIGN KEY (block_id) REFERENCES trans.blocks(id) ON DELETE SET NULL;
ALTER TABLE trans.slides ADD CONSTRAINT slides_fk FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.slides ADD CONSTRAINT slides_slide_type_fkey FOREIGN KEY (slide_type) REFERENCES config.slide_types(id);
ALTER TABLE trans.slides ADD CONSTRAINT trans_slides_stain_type_fk FOREIGN KEY (stain_type) REFERENCES master.enum_staining_methods(id);
-- trans.specimen_containers foreign keys
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
ALTER TABLE trans.specimen_containers ADD CONSTRAINT trans_specimen_containers_fixation_method_fk FOREIGN KEY (fixation_method) REFERENCES config.fixation_methods(id);
-- trans.worklist_cases foreign keys
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_actor_ref_fkey FOREIGN KEY (actor_ref) REFERENCES master.actors(id);
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_role_fkey FOREIGN KEY (in_role) REFERENCES master.actor_roles(id);



