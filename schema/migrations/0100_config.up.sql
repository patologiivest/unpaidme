CREATE SCHEMA IF NOT EXISTS config;


CREATE TABLE IF NOT EXISTS config.actor_roles (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT actor_roles_pkey PRIMARY KEY (id),
    CONSTRAINT actor_roles_uniq UNIQUE ("name")
);


CREATE TABLE IF NOT EXISTS config.block_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT block_types_pkey PRIMARY KEY (id),
    CONSTRAINT block_types_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.case_priority (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT case_priority_pkey PRIMARY KEY (id),
    CONSTRAINT case_priority_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.event_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT event_types_pkey PRIMARY KEY (id)
    CONSTRAINT event_types_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.event_names (
    id int4 NOT NULL,
    "name" text NOT NULL,
    default_event_type int4 NULL,
    CONSTRAINT event_names_name_key UNIQUE (name),
    CONSTRAINT event_names_pkey PRIMARY KEY (id)
);
ALTER TABLE config.event_names ADD CONSTRAINT event_names_default_event_type_fkey FOREIGN KEY (default_event_type) REFERENCES config.event_types(id);
CREATE UNIQUE INDEX net_event_names_name_idx ON config.net_event_names USING btree (name);

CREATE TABLE IF NOT EXISTS config.lab_locations (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT lab_locations_pkey PRIMARY KEY (id),
    CONSTRAINT lab_locations_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.patho_division (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT patho_division_pkey PRIMARY KEY (id),
    CONSTRAINT patho_division_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.requisition_type (
      id int4 NOT NULL,
      "name" text NOT NULL,
      CONSTRAINT requisition_type_pkey PRIMARY KEY (id),
      CONSTRAINT requisition_type_uniq UNIQUE ("name")
);

CREATE TABLE IF NOT EXISTS config.slide_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT slide_types_pkey PRIMARY KEY (id),
    CONSTRAINT slide_types_uniq UNIQUE ("name")
);


CREATE TABLE IF NOT EXISTS config.token_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT token_types_pkey PRIMARY KEY (id),
    CONSTRAINT token_types_uniq UNIQUE ("name")
);







