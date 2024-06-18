CREATE SCHEMA IF NOT EXISTS config;


CREATE TABLE IF NOT EXISTS config.actor_roles (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT user_roles_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.accounting_profiles (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT accounting_profile_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.analysis_state (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT analysis_state_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.block_state (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT block_state_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.block_types (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT block_types_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.builtin_event_types (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT builtin_event_types_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.builtin_token_types (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT builtin_token_types_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.case_priority (
   id int4 NOT NULL,
   "name" varchar(255) NOT NULL,
   CONSTRAINT case_priority_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.case_state (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT case_state_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.fixation_methods (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      CONSTRAINT fixation_methods_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.patho_division (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT patho_division_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.requisition_type (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      CONSTRAINT requisition_type_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.slide_state (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT slide_state_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.slide_types (
     id int4 NOT NULL,
     "name" varchar(255) NOT NULL,
     CONSTRAINT slide_types_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.specimen_state (
    id int4 NOT NULL,
    "name" varchar(255) NOT NULL,
    CONSTRAINT specimen_state_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.workflow_profile (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      CONSTRAINT case_profile_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS config.lab_locations (
      id int4 NOT NULL,
      "name" varchar(255) NOT NULL,
      CONSTRAINT lab_locations_name_key UNIQUE (name),
      CONSTRAINT lab_locations_pkey PRIMARY KEY (id)
);


CREATE TABLE IF NOT EXISTS config.net_event_names (
        id int4 NOT NULL,
        "name" varchar(50) NOT NULL,
        default_event_type int4 NULL,
        CONSTRAINT net_event_names_name_key UNIQUE (name),
        CONSTRAINT net_event_names_pkey PRIMARY KEY (id)
        );
ALTER TABLE config.net_event_names ADD CONSTRAINT net_event_names_default_event_type_fkey FOREIGN KEY (default_event_type) REFERENCES config.builtin_event_types(id);
CREATE UNIQUE INDEX net_event_names_name_idx ON config.net_event_names USING btree (name);


CREATE TABLE IF NOT EXISTS config.net_structure_mutex (
        left_id int4 NOT NULL,
        right_id int4 NOT NULL,
        CONSTRAINT net_structure_mutex_pkey PRIMARY KEY (left_id, right_id)
);
ALTER TABLE config.net_structure_mutex ADD CONSTRAINT net_structure_mutex_left_id_fkey FOREIGN KEY (left_id) REFERENCES config.net_event_names(id);
ALTER TABLE config.net_structure_mutex ADD CONSTRAINT net_structure_mutex_right_id_fkey FOREIGN KEY (right_id) REFERENCES config.net_event_names(id);

CREATE TABLE IF NOT EXISTS config.net_structure_sequence (
       src_id int4 NOT NULL,
       dst_id int4 NOT NULL,
       CONSTRAINT net_structure_sequence_pkey PRIMARY KEY (src_id, dst_id)
);
ALTER TABLE config.net_structure_mutex ADD CONSTRAINT net_structure_sequence_dst_id_fkey FOREIGN KEY (dst_id) REFERENCES config.net_event_names(id);
ALTER TABLE config.net_structure_mutex ADD CONSTRAINT net_structure_sequence_src_id_fkey FOREIGN KEY (src_id) REFERENCES config.net_event_names(id);

