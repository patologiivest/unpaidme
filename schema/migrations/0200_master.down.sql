DROP TABLE IF EXISTS master.accounting_profiles CASCADE;
DROP TABLE IF EXISTS master.role_assignments CASCADE;
DROP TABLE IF EXISTS master.actors CASCADE;
DROP TABLE IF EXISTS master.organizations CASCADE;
DROP TABLE IF EXISTS master.requisitioners CASCADE;
DROP TABLE IF EXISTS master.workstations CASCADE;
DROP TABLE IF EXISTS master.code_mapping cascade;
DROP TABLE IF EXISTS master.specimen_types CASCADE;
DROP TABLE IF EXISTS master.staining_methods CASCADE;
DROP TABLE IF EXISTS master.analysis_methods CASCADE;
DROP TABLE IF EXISTS master.fixation_methods CASCADE;
DROP TABLE IF EXISTS master.code_values CASCADE;


DROP SEQUENCE IF EXISTS master.actors_seq;
DROP SEQUENCE IF EXISTS master.code_values_seq;
DROP SEQUENCE IF EXISTS master.workstations_seq;
DROP SEQUENCE IF EXISTS master.organizations_seq;
DROP SEQUENCE IF EXISTS master.requisitioners_seq;
DROP SEQUENCE IF EXISTS master.specimen_types_seq;
DROP SEQUENCE IF EXISTS master.staining_methods_seq;
DROP SEQUENCE IF EXISTS master.analysis_methods_seq;
DROP SEQUENCE IF EXISTS master.fixation_methods_seq;

DROP SCHEMA IF EXISTS master;
