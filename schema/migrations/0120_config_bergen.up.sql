-- PATHO_BERGEN: Actor Role config data
TRUNCATE TABLE config.actor_roles;
INSERT INTO config.actor_roles (id, "name") VALUES(0, 'Lege');
INSERT INTO config.actor_roles (id, "name") VALUES(1, 'LIS');
INSERT INTO config.actor_roles (id, "name") VALUES(2, 'BioIng');
INSERT INTO config.actor_roles (id, "name") VALUES(3, 'Sekretær');

-- PATHO_BERGEN: Block Types
TRUNCATE TABLE config.block_types;
INSERT INTO config.block_types (id, "name") VALUES(0, 'Rosa');
INSERT INTO config.block_types (id, "name") VALUES(1, 'Hvit');
INSERT INTO config.block_types (id, "name") VALUES(2, 'Oransje');
INSERT INTO config.block_types (id, "name") VALUES(3, 'Gul');
INSERT INTO config.block_types (id, "name") VALUES(4, 'Rød');
INSERT INTO config.block_types (id, "name") VALUES(5, 'Grønn');
INSERT INTO config.block_types (id, "name") VALUES(6, 'Grå');
INSERT INTO config.block_types (id, "name") VALUES(7, 'Blå');
INSERT INTO config.block_types (id, "name") VALUES(10, 'Stor Blokk');
INSERT INTO config.block_types (id, "name") VALUES(11, 'EPON Blokk');
INSERT INTO config.block_types (id, "name") VALUES(12, 'Innsend Blokk');
INSERT INTO config.block_types (id, "name") VALUES(13, 'Historisk Blokk');
INSERT INTO config.block_types (id, "name") VALUES(14, 'Celleblokk');

-- TODO: move to master
-- PATHO_BERGEN: Accounting Profile config data
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(0, 'Innlagt', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(1, 'Poliklinikk', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(2, 'Ekstern Rekvirent', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(3, 'HELFO', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(4, 'Forskning', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(5, 'Ufakturert', NULL);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(11, 'PATP1', 1);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(12, 'PATP2', 2);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(13, 'PATP3', 3);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(14, 'PATP4', 4);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(15, 'PATP5', 5);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(16, 'PATP6', 6);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(17, 'PATP7', 7);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(18, 'PATP8', 8);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(19, 'PATP9', 9);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(20, 'PATP10', 10);
INSERT INTO config.accounting_profiles (id, "name", "level") VALUES(21, 'PATP11', 11);


-- PATHO_BERGEN: Lab locations 
INSERT INTO config.lab_locations (id, "name") VALUES(0, 'Histologilabb');
INSERT INTO config.lab_locations (id, "name") VALUES(1, 'Cytologilabb');
INSERT INTO config.lab_locations (id, "name") VALUES(2, 'Immunlabb');
INSERT INTO config.lab_locations (id, "name") VALUES(3, 'Nyrelabb');
INSERT INTO config.lab_locations (id, "name") VALUES(4, 'Nevrolabb');
INSERT INTO config.lab_locations (id, "name") VALUES(5, 'Molekulærlabb');
INSERT INTO config.lab_locations (id, "name") VALUES(6, 'Autopsilabb');


-- PATHO_BERGEN: Case Priorities
TRUNCATE TABLE config.case_priority;
INSERT INTO config.case_priority (id, "name") VALUES(0, 'Regulær');
INSERT INTO config.case_priority (id, "name") VALUES(1, 'Pakkeforløp');
INSERT INTO config.case_priority (id, "name") VALUES(2, 'CITO');
INSERT INTO config.case_priority (id, "name") VALUES(3, 'Frysesnitt');

-- Requistion Types
TRUNCATE TABLE config.requisition_type;
INSERT INTO config.requisition_type (id, "name") VALUES(0, 'Internt Papir');
INSERT INTO config.requisition_type (id, "name") VALUES(1, 'Internt Elektronisk');
INSERT INTO config.requisition_type (id, "name") VALUES(2, 'Eksternt');


-- Slide Types 
INSERT INTO config.slide_types (id, "name") VALUES(2, 'EXTERNAL');


-- TODO: move to master
-- Workflow Profiles 
INSERT INTO config.workflow_profile (id, "name") VALUES(0, 'Små Prøve');
INSERT INTO config.workflow_profile (id, "name") VALUES(1, 'Utvided Prøve');
INSERT INTO config.workflow_profile (id, "name") VALUES(2, 'Stor Prøve');
INSERT INTO config.workflow_profile (id, "name") VALUES(10, 'GYN');
INSERT INTO config.workflow_profile (id, "name") VALUES(11, 'HUD');
INSERT INTO config.workflow_profile (id, "name") VALUES(12, 'GI');
INSERT INTO config.workflow_profile (id, "name") VALUES(13, 'H');
INSERT INTO config.workflow_profile (id, "name") VALUES(14, 'SAR');
INSERT INTO config.workflow_profile (id, "name") VALUES(15, 'MAM');
INSERT INTO config.workflow_profile (id, "name") VALUES(16, 'NEV');
INSERT INTO config.workflow_profile (id, "name") VALUES(17, 'LYM');
INSERT INTO config.workflow_profile (id, "name") VALUES(18, 'ORA');
INSERT INTO config.workflow_profile (id, "name") VALUES(19, 'URO');
INSERT INTO config.workflow_profile (id, "name") VALUES(20, 'ØNH');
INSERT INTO config.workflow_profile (id, "name") VALUES(21, 'LUN');
INSERT INTO config.workflow_profile (id, "name") VALUES(22, 'ØYE');
INSERT INTO config.workflow_profile (id, "name") VALUES(23, 'HJE');
INSERT INTO config.workflow_profile (id, "name") VALUES(24, 'PLA');
INSERT INTO config.workflow_profile (id, "name") VALUES(25, 'ANN');
INSERT INTO config.workflow_profile (id, "name") VALUES(26, 'XXX');
INSERT INTO config.workflow_profile (id, "name") VALUES(27, 'NYR');
INSERT INTO config.workflow_profile (id, "name") VALUES(3, 'Frysesnitt');
INSERT INTO config.workflow_profile (id, "name") VALUES(5, 'Tilsendt');




