-- Prepared table content for the tables in the config schema
-- If you want to customize, you may either directly overwrite the content here
-- or you create a follow-up migration, e.g. `120_config_local.up.sql`
-- where you first `TRUNCATE` this data and then insert your own

-- # Likely to be adjusted:

-- case priority
INSERT INTO config.case_priority (id, "name") VALUES(0, 'REGULAR');
INSERT INTO config.case_priority (id, "name") VALUES(1, 'PRIORITIZED');

-- lab locations 
-- ... depends on your lab

-- Requisition Types
INSERT INTO config.requisition_types (id, "name") VALUES(0, 'INTERNAL');
INSERT INTO config.requisition_types (id, "name") VALUES(1, 'EXTERNAL');


-- # Possibly, need to be adjusted:

-- Actor Roles
INSERT INTO config.actor_roles (id, "name") VALUES(0, 'PATHOLOGIST');
INSERT INTO config.actor_roles (id, "name") VALUES(1, 'RESIDENT');
INSERT INTO config.actor_roles (id, "name") VALUES(2, 'LAB_TECHNICIAN');
INSERT INTO config.actor_roles (id, "name") VALUES(3, 'SECRETARIAN');

-- Block Types
INSERT INTO config.block_types (id, "name") VALUES(0, 'NORMAL');
INSERT INTO config.block_types (id, "name") VALUES(1, 'LARGE');
INSERT INTO config.block_types (id, "name") VALUES(2, 'EPON');
INSERT INTO config.block_types (id, "name") VALUES(3, 'EXTERNAL');
INSERT INTO config.block_types (id, "name") VALUES(4, 'CELL');

-- Slide Types 
INSERT INTO config.slide_types (id, "name") VALUES(0, 'NORMAL');
INSERT INTO config.slide_types (id, "name") VALUES(1, 'BIG');

-- workflow profiles
-- Example content: adjust to your needs
-- different grossing workflows, as an example ...
INSERT INTO config.workflow_profiles (id, "name") VALUES (0, 'REGULAR'); 
INSERT INTO config.workflow_profiles (id, "name") VALUES (1, 'FRONZEN_SECTION'); 
INSERT INTO config.workflow_profiles (id, "name") VALUES (2, 'CONSULTATION');
-- different subspecialities, just as an example...
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (3, 'DERM'); 
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (4, 'BONE');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (5, 'BREAST');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (6, 'CARDIO');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (7, 'DERMA');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (8, 'GASTRO');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (9, 'URO');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (10, 'HEMATO');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (11, 'NEURO');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (12, 'PULMONARY');
-- INSERT INTO config.workflow_profiles (id, "name") VALUES (13, 'RENAL');


-- workstation_types 
-- adjust when needed
INSERT INTO config.workstation_types(id, "name") VALUES (0, 'DESKTOP_COMPUTER');
INSERT INTO config.workstation_types(id, "name") VALUES (1, 'REGISTRATION_DESK');
INSERT INTO config.workstation_types(id, "name") VALUES (2, 'GROSSING_STATION');
INSERT INTO config.workstation_types(id, "name") VALUES (3, 'PROCESSING_MACHINE');
INSERT INTO config.workstation_types(id, "name") VALUES (4, 'CYTOLOGY_PROCESSOR');
INSERT INTO config.workstation_types(id, "name") VALUES (5, 'EMBEDDING_STATION');
INSERT INTO config.workstation_types(id, "name") VALUES (6, 'MICROTOME');
INSERT INTO config.workstation_types(id, "name") VALUES (7, 'STAINING_MACHINE');
INSERT INTO config.workstation_types(id, "name") VALUES (8, 'IHC_STAINING_MACHINE');
INSERT INTO config.workstation_types(id, "name") VALUES (9, 'SCANNER');
INSERT INTO config.workstation_types(id, "name") VALUES (10, 'CRYOTOME');
INSERT INTO config.workstation_types(id, "name") VALUES (11, 'PCR_MACHINE');
INSERT INTO config.workstation_types(id, "name") VALUES (12, 'AUTOMATIC_EMBEDDING_MACHINE');
INSERT INTO config.workstation_types(id, "name") VALUES (13, 'SECTIONING_ROBOT');

-- # BUILTIN
-- The following you will most certainly not touch!

INSERT INTO config.event_types (id, "name") VALUES(0, 'EVENT');
INSERT INTO config.event_types (id, "name") VALUES(1, 'ACTIVITY_START');
INSERT INTO config.event_types (id, "name") VALUES(2, 'ACTIVITY_FINISH');
INSERT INTO config.event_types (id, "name") VALUES(3, 'ACTIVITY_PAUSE');
INSERT INTO config.event_types (id, "name") VALUES(4, 'ACTIVITY_RESUME');
INSERT INTO config.event_types (id, "name") VALUES(5, 'ERROR');
INSERT INTO config.event_types (id, "name") VALUES(6, 'UNKNOWN');

INSERT INTO config.token_types (id, "name") VALUES(0, 'CASE');
INSERT INTO config.token_types (id, "name") VALUES(1, 'CONTAINER');
INSERT INTO config.token_types (id, "name") VALUES(2, 'BLOCK');
INSERT INTO config.token_types (id, "name") VALUES(3, 'SLIDE');
INSERT INTO config.token_types (id, "name") VALUES(4, 'ANALYSIS');
INSERT INTO config.token_types (id, "name") VALUES(5, 'REPORT');
INSERT INTO config.token_types (id, "name") VALUES(6, 'OTHER');


INSERT INTO config.patho_divisions (id, "name") VALUES(0, 'AUTOPSY');
INSERT INTO config.patho_divisions (id, "name") VALUES(1, 'HISTOLOGY');
INSERT INTO config.patho_divisions (id, "name") VALUES(2, 'CYTOLOGY');
INSERT INTO config.patho_divisions (id, "name") VALUES(3, 'MOLECULAR');
INSERT INTO config.patho_divisions (id, "name") VALUES(4, 'FORENSIC');
