-- Foreign keys enable to enforce structural integrity 
-- hoever, they also come with a runtime cost, whenever entries in these tables are mutated.
-- hence, they are split into this separate file, so you may choose to apply them or not
ALTER TABLE trans.cases ADD CONSTRAINT cases_patho_division_fkey FOREIGN KEY (patho_division) REFERENCES config.patho_divisions(id) ON DELETE SET NULL;
ALTER TABLE trans.cases ADD CONSTRAINT cases_patient_fkey FOREIGN KEY (patient) REFERENCES trans.patients(id) ON DELETE SET NULL;
ALTER TABLE trans.cases ADD CONSTRAINT cases_priority_fkey FOREIGN KEY (priority) REFERENCES config.case_priority(id) ON DELETE SET NULL; ALTER TABLE trans.cases ADD CONSTRAINT cases_requisition_type_fkey FOREIGN KEY (requisition_type) REFERENCES config.requisition_types(id) ON DELETE SET NULL;
ALTER TABLE trans.cases ADD CONSTRAINT cases_requisitioner_fkey FOREIGN KEY (requisitioner) REFERENCES master.requisitioners(id) ON DELETE SET NULL;
ALTER TABLE trans.cases ADD CONSTRAINT cases_responsible_actor_fkey FOREIGN KEY (responsible_actor) REFERENCES master.actors(id) ON DELETE SET NULL;
ALTER TABLE trans.cases ADD CONSTRAINT cases_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id) ON DELETE SET NULL;

-- trans.specimen_containers foreign keys
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_specimen_type_fkey FOREIGN KEY (specimen_type) REFERENCES master.specimen_types(id) ON DELETE SET NULL;
ALTER TABLE trans.specimen_containers ADD CONSTRAINT specimen_containers_fixation_method_fkey FOREIGN KEY (fixation_method) REFERENCES master.fixation_methods(id) ON DELETE SET NULL;

-- trans.blocks foreign keys
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_block_type_fkey FOREIGN KEY (block_type) REFERENCES config.block_types(id) ON DELETE SET NULL;
ALTER TABLE trans.blocks ADD CONSTRAINT blocks_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;

-- trans.slides foreign keys
ALTER TABLE trans.slides ADD CONSTRAINT slides_block_id_fkey FOREIGN KEY (block_id) REFERENCES trans.blocks(id) ON DELETE SET NULL;
ALTER TABLE trans.slides ADD CONSTRAINT slides_case_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;
ALTER TABLE trans.slides ADD CONSTRAINT slides_slide_type_fkey FOREIGN KEY (slide_type) REFERENCES config.slide_types(id) ON DELETE SET NULL;
ALTER TABLE trans.slides ADD CONSTRAINT slides_stain_type_fkey FOREIGN KEY (stain_type) REFERENCES master.staining_methods(id) ON DELETE SET NULL;

-- trans.analyses foreign keys
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;
ALTER TABLE trans.analyses ADD CONSTRAINT analyses_coding_fkey FOREIGN KEY (analysis_type) REFERENCES master.analysis_codes(id) ON DELETE SET NULL;

-- trans.case_codings foreign keys
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;
ALTER TABLE trans.case_codings ADD CONSTRAINT case_codings_code_id_fkey FOREIGN KEY (code_id) REFERENCES master.code_values(id) ON DELETE CASCADE;

-- trans.case_profiles foreign keys
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_id_fkey FOREIGN KEY (case_id) REFERENCES trans.cases(id) ON DELETE CASCADE;
ALTER TABLE trans.case_profiles ADD CONSTRAINT case_profile_case_profile_fkey FOREIGN KEY (case_profile) REFERENCES config.workflow_profiles(id) ON DELETE CASCADE;








