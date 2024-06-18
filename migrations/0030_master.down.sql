DROP TABLE IF EXISTS master.specimen_type_workflow_profiles;
DROP TABLE IF EXISTS master.specimen_type_aux_codes;
DROP TABLE IF EXISTS master.code_alias;
DROP TABLE IF EXISTS master.workstations;
DROP TABLE IF EXISTS master.specimen_types;
DROP TABLE IF EXISTS master.requisitioners;
DROP TABLE IF EXISTS master.staining_methods;
DROP TABLE IF EXISTS master.analysis_methods;
DROP TABLE IF EXISTS master.code_values;
DROP TABLE IF EXISTS master.role_assignments;
DROP TABLE IF EXISTS master.actors;


DROP SEQUENCE IF EXISTS master.actors_seq;
DROP SEQUENCE IF EXISTS master.code_values_seq;
DROP SEQUENCE IF EXISTS master.requisitioners_seq;
DROP SEQUENCE IF EXISTS master.workstations_seq;
DROP SEQUENCE IF EXISTS master.specimen_types_seq;

DROP SCHEMA IF EXISTS master;
