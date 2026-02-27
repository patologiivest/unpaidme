CREATE SCHEMA IF NOT EXISTS master;

-- Accounting Profiles
-- ANCHOR: accounting_profiles
CREATE TABLE IF NOT EXISTS master.accounting_profiles (
        id int4 NOT NULL,
        "name" text NOT NULL,
        "level" int4 NULL,
        amount numeric(100,2) NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        CONSTRAINT accounting_profile_pkey PRIMARY KEY (id),
        CONSTRAINT accounting_profile_uniq UNIQUE ("name", valid_from)
);
-- ANCHOR_END: accounting_profiles

-- actors and roles
-- ANCHOR: actors_roles
CREATE SEQUENCE IF NOT EXISTS master.actors_seq;

CREATE TABLE IF NOT EXISTS master.actors (
        id int4 NOT NULL DEFAULT nextval('master.actors_seq'::regclass),
        "name" text NOT NULL,
        "alias" text NULL,
        CONSTRAINT actors_name_key UNIQUE (name),
        CONSTRAINT actors_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS master.role_assignments (
        actor_id int4 NOT NULL,
        role_id int4 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        CONSTRAINT role_assignments_pkey PRIMARY KEY (actor_id, role_id, valid_from)
);
ALTER TABLE master.role_assignments 
    ADD CONSTRAINT role_assignments_actor_id_fkey 
    FOREIGN KEY (actor_id) REFERENCES master.actors(id);
ALTER TABLE master.role_assignments 
    ADD CONSTRAINT role_assignments_role_id_fkey 
    FOREIGN KEY (role_id) REFERENCES config.actor_roles(id);
CREATE INDEX role_assignment_actor_idx ON master.role_assignments(actor_id);
-- ANCHOR_END: actors_roles


-- Requisitioners and organizations
-- ANCHOR: requisitioners_organizations
CREATE SEQUENCE IF NOT EXISTS master.requisitioners_seq;
CREATE SEQUENCE IF NOT EXISTS master.organizations_seq;

CREATE TABLE IF NOT EXISTS master.organizations(
        id int4 NOT NULL DEFAULT nextval('master.organizations_seq'::regclass),
        "name" text NOT NULL,
        parent_organization int4 NULL,
        CONSTRAINT organization_pkey PRIMARY KEY (id),
        CONSTRAINT organization_name_key UNIQUE ("name")
);
ALTER TABLE master.organizations 
    ADD CONSTRAINT organization_parent_fkey 
    FOREIGN KEY (parent_organization) REFERENCES master.organizations(id);

CREATE TABLE IF NOT EXISTS master.requisitioners (
       id int4 NOT NULL DEFAULT nextval('master.requisitioners_seq'::regclass),
       "name" text NOT NULL,
       "organization" int4 NULL,
       CONSTRAINT requisitioners_name_key UNIQUE ("name"),
       CONSTRAINT requisitioners_pkey PRIMARY KEY (id)
);
ALTER TABLE master.requisitioners 
    ADD CONSTRAINT requisitioner_organization_fkey 
    FOREIGN KEY ("organization") REFERENCES master.organizations(id);
-- ANCHOR_END: requisitioners_organizations


-- Workstations
-- ANCHOR: workstations
CREATE SEQUENCE IF NOT EXISTS master.workstations_seq;

CREATE TABLE IF NOT EXISTS master.workstations (
     id int4 NOT NULL DEFAULT nextval('master.workstations_seq'::regclass),
     "name" text NOT NULL,
     lab_location int4 NULL,
     workstation_type int4 NULL,
     CONSTRAINT workstations_name_key UNIQUE (name),
     CONSTRAINT workstations_pkey PRIMARY KEY (id)
);
ALTER TABLE master.workstations 
    ADD CONSTRAINT workstations_fk_lab_location 
    FOREIGN KEY (lab_location) REFERENCES config.lab_locations(id);
ALTER TABLE master.workstations 
    ADD CONSTRAINT workstations_fk_type 
    FOREIGN KEY (workstation_type) REFERENCES config.workstation_types(id);
-- ANCHOR_END: workstations


--- Codings
-- ANCHOR: coding
CREATE SEQUENCE IF NOT EXISTS master.code_values_seq;
CREATE TABLE IF NOT EXISTS master.code_values (
        id int8 NOT NULL DEFAULT nextval('master.code_values_seq'::regclass),
        code text NOT NULL,
        coding_scheme text NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        code_display_text text NULL,
        parent_code int8 NULL,
        CONSTRAINT code_values_pkey PRIMARY KEY (id),
        CONSTRAINT global_code_scheme UNIQUE (code, coding_scheme, valid_from)
);
CREATE INDEX code_values_names_idx ON master.code_values (code);
CREATE INDEX code_values_schemes_idx ON master.code_values (coding_scheme);

CREATE TABLE IF NOT EXISTS master.code_mapping (
        src_code int8 NOT NULL,
        dst_code int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        mapping_type text NOT NULL,
        CONSTRAINT code_mapping_pkey PRIMARY KEY (src_code, dst_code, valid_from)
);
ALTER TABLE master.code_mapping 
    ADD CONSTRAINT code_mapping_src_fkey 
    FOREIGN KEY (src_code) REFERENCES master.code_values(id);
ALTER TABLE master.code_mapping 
    ADD CONSTRAINT code_mapping_dst_fkey 
    FOREIGN KEY (dst_code) REFERENCES master.code_values(id);
CREATE INDEX code_mapping_src_idx ON master.code_mapping(src_code);
CREATE INDEX code_mapping_dst_idx ON master.code_mapping(dst_code);
-- ANCHOR_END: coding


-- ANCHOR: specimen_types
CREATE SEQUENCE IF NOT EXISTS master.specimen_types_seq;
CREATE TABLE IF NOT EXISTS master.specimen_types (
        id int8 NOT NULL DEFAULT nextval('master.specimen_types_seq'::regclass),
        loc_code int8 NOT NULL,
        proc_code int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        patho_division int4 NULL,
        accounting_profile int4 NULL,
        CONSTRAINT specimen_types_pkey PRIMARY KEY (id),
        CONSTRAINT specimen_types_uniq UNIQUE (loc_code, proc_code)
);
ALTER TABLE master.specimen_types 
    ADD CONSTRAINT specimen_types_loc_code_fkey 
    FOREIGN KEY (loc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_types 
    ADD CONSTRAINT specimen_types_proc_code_fkey 
    FOREIGN KEY (proc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_types 
    ADD CONSTRAINT specimen_types_division_fkey 
    FOREIGN KEY (patho_division) REFERENCES config.patho_divisions(id);
ALTER TABLE master.specimen_types 
    ADD CONSTRAINT specimen_types_accounting_fkey 
    FOREIGN KEY (accounting_profile) REFERENCES master.accounting_profiles(id);
CREATE INDEX specimen_types_loc_code_idx ON master.specimen_types (loc_code);
CREATE INDEX specimen_types_proc_code_idx ON master.specimen_types (proc_code);
-- ANCHOR_END: specimen_types


-- ANCHOR: staining_methods
CREATE SEQUENCE IF NOT EXISTS master.staining_methods_seq;
CREATE TABLE IF NOT EXISTS master.staining_methods (
        id int4 NOT NULL DEFAULT nextval('master.staining_methods_seq'::regclass),
        coding int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        accounting_profile int4 NULL,
        lab_location int4 NULL,
        CONSTRAINT staining_methods_pkey PRIMARY KEY (id)
);
ALTER TABLE master.staining_methods 
    ADD CONSTRAINT staining_methods_coding_fkey 
    FOREIGN KEY (coding) REFERENCES master.code_values(id);
ALTER TABLE master.staining_methods 
    ADD CONSTRAINT staining_methods_accounting_fkey 
    FOREIGN KEY (accounting_profile) REFERENCES master.accounting_profiles(id);
ALTER TABLE master.staining_methods 
    ADD CONSTRAINT staining_methods_location_fkey 
    FOREIGN KEY (lab_location) REFERENCES config.lab_locations(id);
CREATE INDEX staining_method_code_idx ON master.staining_methods(coding);
-- ANCHOR_END: staining_methods

-- ANCHOR: fixation_methods
CREATE SEQUENCE IF NOT EXISTS master.fixation_methods_seq;
CREATE TABLE IF NOT EXISTS master.fixation_methods (
        id int4 NOT NULL DEFAULT nextval('master.fixation_methods_seq'::regclass),
        coding int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        CONSTRAINT fixation_methods_pkey PRIMARY KEY (id)
);
ALTER TABLE master.fixation_methods 
    ADD CONSTRAINT fixation_methods_fkey 
    FOREIGN KEY (coding) REFERENCES master.code_values(id);
CREATE INDEX fixation_method_code_idx ON master.fixation_methods(coding);
-- ANCHOR_END: fixation_methods


-- ANCHOR: analysis_methods
CREATE SEQUENCE IF NOT EXISTS master.analysis_methods_seq;
CREATE TABLE IF NOT EXISTS master.analysis_methods (
        id int4 NOT NULL DEFAULT nextval('master.analysis_methods_seq'::regclass),
        coding int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        accounting_profile int4 NULL,
        lab_location int4 NULL,
        CONSTRAINT analysis_methods_pkey PRIMARY KEY (id)
);
ALTER TABLE master.analysis_methods 
    ADD CONSTRAINT analysis_methods_coding_fkey 
    FOREIGN KEY (coding) REFERENCES master.code_values(id);
ALTER TABLE master.analysis_methods 
    ADD CONSTRAINT analysis_methods_accounting_fkey 
    FOREIGN KEY (accounting_profile) REFERENCES master.accounting_profiles(id);
ALTER TABLE master.analysis_methods 
    ADD CONSTRAINT analysis_methods_lab_locations_fkey 
    FOREIGN KEY (lab_location) REFERENCES config.lab_locations(id);
CREATE INDEX analysis_method_code_idx ON master.analysis_methods(coding);
-- ANCHOR_END: analysis_methods



