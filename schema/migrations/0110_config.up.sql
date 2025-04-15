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
INSERT INTO config.requisition_type (id, "name") VALUES(0, 'INTERNAL');
INSERT INTO config.requisition_type (id, "name") VALUES(1, 'EXTERNAL');


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

-- Event Names
-- Maybe this already fits your use case?
-- Note: You may not use all the entries in this tables (e.g. if you are not using electron-microscopy)
-- If you thing somthing is missing: please create a pull request and share your ideas with us!
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(0, 'specimenTaken', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(10, 'requisitionReceived', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(11, 'consultationReceived', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(19, 'requisitionRetracted', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(20, 'accessioning', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(26, 'consultationBlockRegistered', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(27, 'consultationSlideRegistered', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(30, 'grossing', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(31, 'specimenContainerArchived', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(32, 'specimenContainerRetrieved', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(33, 'grossingKidney', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(34, 'grossingIHC', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(35, 'blockPrinted', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(39, 'dictationTranscription', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(40, 'processing', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(41, 'decalcination', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(42, 'processingPCR', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(43, 'flowCytometry', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(50, 'manualEmbedding', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(51, 'automaticEmbedding', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(59, 'Koordinering', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(60, 'manualSectioning', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(61, 'automaticSectioning', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(62, 'sectioningIHC', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(63, 'sectioningMolecular', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(64, 'sectioningKidney', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(65, 'sectioningNeurology', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(66, 'slidePrinted', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(67, 'blockArchived', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(68, 'blockRetrieved', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(69, 'blockDestroyed', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(70, 'automaticStaining', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(71, 'manualStaining', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(72, 'stainingIHC', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(73, 'molecularAnalysis', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(74, 'stainingKidney', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(75, 'stainingNeurology', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(80, 'caseAssigned', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(81, 'caseReassgined', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(82, 'caseCoResponsibleAssigned', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(85, 'scanning', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(87, 'slideArchived', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(88, 'slideRetrieved', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(89, 'slideDestroyed', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(90, 'microscopicAnalysis', 1);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(91, 'ihcRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(92, 'specialStainRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(93, 'additionalGrossingRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(94, 'molpatRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(95, 'electronMicroscopyRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(96, 'sendInForExternalConsultation', 3);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(97, 'reportSubmittedForReview', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(98, 'preliminaryReportFinished', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(99, 'finalReportFinished', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(100, 'caseArchived', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(101, 'caseReopened', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(102, 'reportAugmented', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(103, 'reportCorrected', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(107, 'archivedSlideRetrievalRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(108, 'archivedBlockRetrievalRequested', 0);
INSERT INTO config.event_names (id, "name", default_event_type) VALUES(110, 'requisitionAnswered', 0);


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

INSERT INTO config.patho_division (id, "name") VALUES(0, 'AUTOPSY');
INSERT INTO config.patho_division (id, "name") VALUES(1, 'HISTOLOGY');
INSERT INTO config.patho_division (id, "name") VALUES(2, 'CYTOLOGY');
INSERT INTO config.patho_division (id, "name") VALUES(3, 'MOLECULAR');
INSERT INTO config.patho_division (id, "name") VALUES(4, 'FORENSIC');

