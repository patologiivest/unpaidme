
ALTER TABLE trans.cases ADD CONSTRAINT cases_patho_division_fkey FOREIGN KEY (patho_division) REFERENCES config.patho_division(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_patient_fkey FOREIGN KEY (patient) REFERENCES trans.patients(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_priority_fkey FOREIGN KEY (priority) REFERENCES config.case_priority(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_requisition_type_fkey FOREIGN KEY (requisition_type) REFERENCES config.requisition_type(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_requisitioner_fkey FOREIGN KEY (requisitioner) REFERENCES master.requisitioners(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_responsible_actor_fkey FOREIGN KEY (responsible_actor) REFERENCES master.actors(id);
ALTER TABLE trans.cases ADD CONSTRAINT cases_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);

-- trans.specimen_containers foreign keys
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id);
ALTER TABLE trans.specimen_containers ADD CONSTRAINT trans_specimen_containers_fixation_method_fk FOREIGN KEY (fixation_method) REFERENCES master.fixation_methods(id);


-- trans.blocks foreign keys
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_block_type_fkey FOREIGN KEY (block_type) REFERENCES config.block_types(id);
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);

-- trans.slides foreign keys
ALTER TABLE trans.slides ADD CONSTRAINT slides_block_id_fkey FOREIGN KEY (block_id) REFERENCES trans.blocks(id) ON DELETE SET NULL;
ALTER TABLE trans.slides ADD CONSTRAINT slides_fk FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.slides ADD CONSTRAINT slides_slide_type_fkey FOREIGN KEY (slide_type) REFERENCES config.slide_types(id);
ALTER TABLE trans.slides ADD CONSTRAINT trans_slides_stain_type_fk FOREIGN KEY (stain_type) REFERENCES master.staining_methods(id);


-- trans.analyses foreign keys
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_coding_fkey FOREIGN KEY (analysis_type) REFERENCES master.analysis_codes(id);

-- trans.case_codings foreign keys
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_code_id_fkey FOREIGN KEY (code_id) REFERENCES master.code_values(id);
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_fk FOREIGN KEY (added_by) REFERENCES master.actors(id);

-- trans.case_profiles foreign keys
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_profile_fkey FOREIGN KEY (case_profile) REFERENCES master.workflow_profiles(id);

-- trans.worklist_cases foreign keys
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_actor_ref_fkey FOREIGN KEY (actor_ref) REFERENCES master.actors(id);
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.worklist_cases ADD CONSTRAINT worklist_role_fkey FOREIGN KEY (in_role) REFERENCES master.actor_roles(id);

-- trans.events (might clash with timescale)
ALTER TABLE trans.events ADD CONSTRAINT events_case_fk FOREIGN KEY (case_id) REFERENCES trans.cases(id);
ALTER TABLE trans.events ADD CONSTRAINT events_token_type_fk FOREIGN KEY (token_type) REFERENCES config.token_types(id);
ALTER TABLE trans.events ADD CONSTRAINT events_event_type_fk FOREIGN KEY (event_type) REFERENCES config.event_types(id);
ALTER TABLE trans.events ADD CONSTRAINT events_event_name_fk FOREIGN KEY (event_name) REFERENCES config.event_names(id);
ALTER TABLE trans.events ADD CONSTRAINT events_actor_fk FOREIGN KEY (actor_ref) REFERENCES master.actors(id);
ALTER TABLE trans.events ADD CONSTRAINT events_location_fk FOREIGN KEY (lab_ref) REFERENCES config.lab_locations(id);
-- TODO: workstation ref missing







