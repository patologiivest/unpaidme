CREATE SCHEMA IF NOT EXISTS master;

CREATE SEQUENCE IF NOT EXISTS master.actors_seq;
CREATE SEQUENCE IF NOT EXISTS master.code_values_seq;
CREATE SEQUENCE IF NOT EXISTS master.requisitioners_seq;
CREATE SEQUENCE IF NOT EXISTS master.specimen_types_seq;
CREATE SEQUENCE IF NOT EXISTS master.workstations_seq;

CREATE TABLE IF NOT EXISTS master.actors (
   id int4 NOT NULL DEFAULT nextval('master.actors_seq'::regclass),
   "name" varchar(255) NOT NULL,
   alias varchar(255) NULL,
   CONSTRAINT actors_name_key UNIQUE (name),
   CONSTRAINT actors_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX actors_name_idx ON master.actors USING btree (name);

CREATE TABLE IF NOT EXISTS master.role_assignments (
     actor_id int4 NOT NULL,
     role_id int4 NOT NULL,
     valid_from timestamp NOT NULL,
     valid_until timestamp NULL,
     CONSTRAINT role_assignments_pkey PRIMARY KEY (actor_id, role_id, valid_from)
);

ALTER TABLE master.role_assignments ADD CONSTRAINT role_assignments_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES master.actors(id);
ALTER TABLE master.role_assignments ADD CONSTRAINT role_assignments_role_id_fkey FOREIGN KEY (role_id) REFERENCES config.actor_roles(id);


CREATE TABLE IF NOT EXISTS master.code_values (
    id int8 NOT NULL,
    code varchar(255) NOT NULL,
    coding_scheme varchar(255) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_until timestamp NULL,
    obsoleted_by int8 NULL,
    code_display_text varchar(10000) NULL,
    parent_code int8 NULL,
    CONSTRAINT code_values_pkey PRIMARY KEY (id)
);

CREATE INDEX code_values_code_idx ON master.code_values USING btree (code);
CREATE INDEX code_values_coding_scheme_idx ON master.code_values USING btree (coding_scheme);

ALTER TABLE master.code_values ADD CONSTRAINT master_coded_values_obsoleted_by_fk FOREIGN KEY (obsoleted_by) REFERENCES master.code_values(id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE master.code_values ADD CONSTRAINT master_coded_values_parent_fk FOREIGN KEY (parent_code) REFERENCES master.code_values(id) DEFERRABLE INITIALLY DEFERRED;


CREATE TABLE IF NOT EXISTS master.analysis_methods (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      coding int8 NULL,
      CONSTRAINT analysis_methods_pkey PRIMARY KEY (id)
);

ALTER TABLE master.analysis_methods ADD CONSTRAINT analysis_methods_coding_fkey FOREIGN KEY (coding) REFERENCES master.code_values(id);
-- TODO: alternative analysis codes
--

CREATE TABLE IF NOT EXISTS master.staining_methods (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      coding int8 NULL,
      CONSTRAINT staining_methods_pkey PRIMARY KEY (id)
);
ALTER TABLE master.staining_methods ADD CONSTRAINT enum_staining_methods_coding_fkey FOREIGN KEY (coding) REFERENCES master.code_values(id);
-- TODO: alternative staining codes


CREATE TABLE IF NOT EXISTS master.requisitioners (
       id int4 NOT NULL DEFAULT nextval('master.requisitioners_seq'::regclass),
       "name" varchar(255) NOT NULL,
       organisation varchar(255) NULL,
       default_accounting_profile int4 NULL,
       CONSTRAINT requisitioners_name_key UNIQUE (name),
       CONSTRAINT requisitioners_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX requisitioners_name_idx ON master.requisitioners USING btree (name);
ALTER TABLE master.requisitioners ADD CONSTRAINT requisitioners_default_accounting_profile_fkey FOREIGN KEY (default_accounting_profile) REFERENCES config.accounting_profiles(id);



CREATE TABLE IF NOT EXISTS master.specimen_types (
       id int8 NOT NULL DEFAULT nextval('master.specimen_types_seq'::regclass),
       loc_code int8 NOT NULL,
       proc_code int8 NOT NULL,
       valid_from timestamp NOT NULL,
       valid_until timestamp NULL,
       obsoleted_by int8 NULL,
       secondary_code_pairs int4 NOT NULL DEFAULT 0,
       CONSTRAINT specimen_types_pkey PRIMARY KEY (id)
);
CREATE INDEX specimen_types_loc_code_idx ON master.specimen_types USING btree (loc_code);
CREATE INDEX specimen_types_proc_code_idx ON master.specimen_types USING btree (proc_code);

ALTER TABLE master.specimen_types ADD CONSTRAINT specimen_types_loc_code_fkey FOREIGN KEY (loc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_types ADD CONSTRAINT specimen_types_obsoleted_by_fk FOREIGN KEY (obsoleted_by) REFERENCES master.specimen_types(id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE master.specimen_types ADD CONSTRAINT specimen_types_proc_code_fkey FOREIGN KEY (proc_code) REFERENCES master.code_values(id);


CREATE TABLE IF NOT EXISTS master.workstations (
     id int4 NOT NULL DEFAULT nextval('master.workstations_seq'::regclass),
     "name" varchar(255) NOT NULL,
     workstation_desc varchar(255) NULL,
     lab_location int4 NULL,
     CONSTRAINT workstations_name_key UNIQUE (name),
     CONSTRAINT workstations_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX workstations_name_idx ON master.workstations USING btree (name);
ALTER TABLE master.workstations ADD CONSTRAINT workstations_fk FOREIGN KEY (lab_location) REFERENCES config.lab_locations(id) ON DELETE SET NULL;


CREATE TABLE IF NOT EXISTS master.code_alias (
       code_id int8 NOT NULL,
       alias_code varchar(255) NULL,
       code_display_text varchar(10000) NULL,
       CONSTRAINT code_alias_code_id_fkey FOREIGN KEY (code_id) REFERENCES master.code_values(id)
);

CREATE TABLE IF NOT EXISTS master.specimen_type_aux_codes (
        specimen_type int8 NOT NULL,
        loc_code int8 NOT NULL,
        "comment" varchar(255) NULL,
        proc_code int8 NOT NULL,
        order_indicator int4 NOT NULL,
        CONSTRAINT specimen_type_aux_codes_pk PRIMARY KEY (specimen_type, loc_code, proc_code, order_indicator),
);
ALTER TABLE master.specimen_type_aux_codes CONSTRAINT specimen_type_aux_codes_code_fkey FOREIGN KEY (loc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_type_aux_codes CONSTRAINT specimen_type_aux_codes_fk FOREIGN KEY (proc_code) REFERENCES master.code_values(id);
ALTER TABLE master.specimen_type_aux_codes CONSTRAINT specimen_type_aux_codes_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);

CREATE TABLE IF NOT EXISTS master.specimen_type_workflow_profiles (
        specimen_type int8 NOT NULL,
        workflow_profile int4 NOT NULL,
        CONSTRAINT specimen_type_workflow_profiles_pkey PRIMARY KEY (specimen_type, workflow_profile)
);
ALTER TABLE master.specimen_type_workflow_profiles ADD CONSTRAINT specimen_type_workflow_profiles_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
ALTER TABLE master.specimen_type_workflow_profiles ADD CONSTRAINT specimen_type_workflow_profiles_workflow_profile_fkey FOREIGN KEY (workflow_profile) REFERENCES config.workflow_profile(id);

