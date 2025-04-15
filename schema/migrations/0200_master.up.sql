CREATE SCHEMA IF NOT EXISTS master;

-- actors and roles
CREATE SEQUENCE IF NOT EXISTS master.actors_seq;
CREATE TABLE IF NOT EXISTS master.actors (
        id int4 NOT NULL DEFAULT nextval('master.actors_seq'::regclass),
        "name" text NOT NULL,
        alias text NULL,
        CONSTRAINT actors_name_key UNIQUE (name),
        CONSTRAINT actors_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX actors_name_idx ON master.actors USING btree (name);

CREATE TABLE IF NOT EXISTS master.role_assignments (
        actor_id int4 NOT NULL,
        role_id int4 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        CONSTRAINT role_assignments_pkey PRIMARY KEY (actor_id, role_id, valid_from)
);

ALTER TABLE master.role_assignments ADD CONSTRAINT role_assignments_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES master.actors(id);
ALTER TABLE master.role_assignments ADD CONSTRAINT role_assignments_role_id_fkey FOREIGN KEY (role_id) REFERENCES config.actor_roles(id);

-- Requisitioners and organizations
CREATE SEQUENCE IF NOT EXISTS master.requisitioners_seq;
CREATE SEQUENCE IF NOT EXISTS master.organizations_seq;

CREATE TABLE IF NOT EXISTS master.organizations(
        id int4 NOT NULL DEFAULT nextval('master.organizations_seq'::regclass),
        "name" text NOT NULL,
        parent_organization int4 NULL,
        CONSTRAINT organization_pkey PRIMARY KEY (id),
        CONSTRAINT organizartion_uniq UNIQUE ("name")
);
ALTER TABLE master.organizations ADD CONSTRAINT organization_parent_fkey FOREIGN KEY (parent_organization) REFERENCES master.organizations(id);

CREATE TABLE IF NOT EXISTS master.requisitioners (
       id int4 NOT NULL DEFAULT nextval('master.requisitioners_seq'::regclass),
       "name" text NOT NULL,
       organization int4 NULL,
       CONSTRAINT requisitioners_name_key UNIQUE ("name"),
       CONSTRAINT requisitioners_pkey PRIMARY KEY (id)
);
ALTER TABLE master.requisitioners ADD CONSTRAINT requisitioner_organization_fkey FOREIGN KEY (organization) REFERENCES master.organizations(id);


--- Codings
CREATE SEQUENCE IF NOT EXISTS master.code_values_seq;
CREATE TABLE IF NOT EXISTS master.code_values (
        id int8 NOT NULL DEFAULT nextval('master.code_values_seq'::regclass),
        code text NOT NULL,
        coding_scheme text NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        code_display_text text NULL,
        parent_code int8 NULL,
        CONSTRAINT code_values_pkey PRIMARY KEY (id)
);
CREATE INDEX code_values_names_idx ON master.code_values (code);
CREATE INDEX code_values_schemes_idx ON master.code_values (coding_scheme);

CREATE TABLE IF NOT EXISTS master.code_mapping (
        src_code int8 NOT NULL,
        dst_code int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        mapping_type text NULL,
        CONSTRAINT code_mapping_pkey PRIMARY KEY (src_code, dst_code, valid_from)
);
ALTER TABLE master.code_mapping ADD CONSTRAINT code_mapping_src_fkey FOREIGN KEY (src_code) REFERENCES master.code_values(id);
ALTER TABLE master.code_mapping ADD CONSTRAINT code_mapping_dst_fkey FOREIGN KEY (dst_code) REFERENCES master.code_values(id);
CREATE INDEX code_mapping_src_idx ON master.code_mapping(src_code);
CREATE INDEX code_mapping_dst_idx ON master.code_mapping(dst_code);


CREATE SEQUENCE IF NOT EXISTS master.specimen_types_seq;
CREATE TABLE IF NOT EXISTS master.specimen_types (
        id int8 NOT NULL DEFAULT nextval('master.specimen_types_seq'::regclass),
        loc_code int8 NOT NULL,
        proc_code int8 NOT NULL,
        valid_from timestamptz NOT NULL,
        valid_until timestamptz NULL,
        CONSTRAINT specimen_types_pkey PRIMARY KEY (id)
);
ALTER TABLE master.specimen_types ADD CONSTRAINT specimen_types_loc_code_fkey FOREIGN KEY (loc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_types ADD CONSTRAINT specimen_types_proc_code_fkey FOREIGN KEY (proc_code) REFERENCES master.code_values(id);
CREATE INDEX specimen_types_loc_code_idx ON master.specimen_types (loc_code);
CREATE INDEX specimen_types_proc_code_idx ON master.specimen_types (proc_code);


CREATE SEQUENCE IF NOT EXISTS master.staining_methods_seq;
CREATE TABLE IF NOT EXISTS master.staining_methods (
        id int4 NOT NULL DEFAULT nextval('master.staining_methods_seq'::regclass),
        description text NOT NULL,
        coding int8 NULL,
        CONSTRAINT staining_methods_pkey PRIMARY KEY (id),
        CONSTRAINT staining_methods_uniq UNIQUE (description)
);
ALTER TABLE master.staining_methods ADD CONSTRAINT staining_methods_coding_fkey FOREIGN KEY (coding) REFERENCES master.code_values(id);

CREATE TABLE IF NOT EXISTS master.fixation_methods (
        id int4 NOT NULL,
        description text NOT NULL,
        coding int8 NULL,
        CONSTRAINT fixation_methods_pkey PRIMARY KEY (id),
        CONSTRAINT fixation_methods_uniq UNIQUE (description)
);
ALTER TABLE master.fixation_methods ADD CONSTRAINT fixation_methods_fkey FOREIGN KEY (coding) REFERENCES master.code_values(id);


CREATE SEQUENCE IF NOT EXISTS master.analysis_codes_seq;
CREATE TABLE IF NOT EXISTS master.analysis_codes (
        id int4 NOT NULL DEFAULT nextval('master.analysis_codes_seq'::regclass),
        description text NOT NULL,
        coding int8 NULL,
        CONSTRAINT analysis_codes_pkey PRIMARY KEY (id),
        CONSTRAINT analysis_codes_uniq UNIQUE (description)
);
ALTER TABLE master.analysis_codes ADD CONSTRAINT staining_methods_coding_fkey FOREIGN KEY (coding) REFERENCES master.code_values(id);




-- Workstations

CREATE SEQUENCE IF NOT EXISTS master.workstations_seq;


CREATE TABLE IF NOT EXISTS master.workstations (
     id int4 NOT NULL DEFAULT nextval('master.workstations_seq'::regclass),
     "name" varchar(255) NOT NULL,
     workstation_desc varchar(255) NULL,
     lab_location int4 NULL,
     CONSTRAINT workstations_name_key UNIQUE (name),
     CONSTRAINT workstations_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX workstations_name_idx ON master.workstations USING btree (name);
ALTER TABLE master.workstations ADD CONSTRAINT workstations_fk_lab_location FOREIGN KEY (lab_location) REFERENCES config.lab_locations(id) ON DELETE SET NULL;



-- Profiles



CREATE TABLE IF NOT EXISTS master.workflow_profiles (
        id int4 NOT NULL,
        "name" text NOT NULL,
        CONSTRAINT case_profile_pkey PRIMARY KEY (id),
        CONSTRAINT case_profile_uniq UNIQUE ("name")
        CREATE TABLE IF NOT EXISTS master.analysis_methods (
        id int4 NOT NULL,
        "name" varchar(255) NOT NULL,
        coding int8 NULL,
        CONSTRAINT analysis_methods_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS master.accounting_profiles (
        id int4 NOT NULL,
        "name" text NOT NULL,
        "level" int4 NULL,
        CONSTRAINT accounting_profile_pkey PRIMARY KEY (id),
        CONSTRAINT accounting_profile_uniq UNIQUE ("name")
);
ALTER TABLE master.specimen_types_accounting_profiles ADD CONSTRAINT specimen_types_account_types_fk_specimen FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
ALTER TABLE master.specimen_types_accounting_profiles ADD CONSTRAINT specimen_types_accounting_types_fk_acc FOREIGN KEY (accounting_profile) REFERENCES config.accounting_profiles(id);

CREATE TABLE IF NOT EXISTS master.specimen_type_workflow_profiles (
        specimen_type int8 NOT NULL,
        workflow_profile int4 NOT NULL,
        CONSTRAINT specimen_type_workflow_profiles_pkey PRIMARY KEY (specimen_type, workflow_profile)
);
ALTER TABLE master.specimen_type_workflow_profiles ADD CONSTRAINT specimen_type_workflow_profiles_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
ALTER TABLE master.specimen_type_workflow_profiles ADD CONSTRAINT specimen_type_workflow_profiles_workflow_profile_fkey FOREIGN KEY (workflow_profile) REFERENCES config.workflow_profile(id);


CREATE TABLE IF NOT EXISTS master.specimen_types_accounting_profiles (
	specspecimen_type int8 NOT NULL,
	accoaccounting_profile int4 NOT NULL,
	CONSCONSTRAINT specimen_type_accounting_profiles_pk PRIMARY KEY (specimen_type, accounting_profile)
);
