-- ========================================================================
-- Healthcare Demo - Step 3: Semantic Views Setup
-- Creates semantic views for Cortex Analyst natural language queries
-- Prerequisites: Run 01_healthcare_data_setup.sql first
-- ========================================================================

-- Switch to the healthcare demo role and database
USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;
USE SCHEMA CLINICAL_SCHEMA;
USE WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH;

-- ========================================================================
-- SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================

-- Clinical Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.CLINICAL_ANALYTICS_VIEW
    tables (
        ENCOUNTERS AS PATIENT_ENCOUNTER_FACT primary key (ENCOUNTER_KEY),
        PATIENTS AS PATIENT_DIM primary key (PATIENT_KEY),
        PROVIDERS AS PROVIDER_DIM primary key (PROVIDER_KEY),
        DEPARTMENTS AS DEPARTMENT_DIM primary key (DEPARTMENT_KEY),
        DIAGNOSES AS DIAGNOSIS_DIM primary key (DIAGNOSIS_KEY),
        CLINICAL_MEASURES AS CLINICAL_MEASURES_FACT primary key (MEASURE_KEY),
        MEDICATIONS AS MEDICATION_FACT primary key (MEDICATION_FACT_KEY)
    )
    relationships (
        ENCOUNTERSTOPATIENTS as ENCOUNTERS(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        ENCOUNTERSTOPROVIDERS as ENCOUNTERS(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY),
        ENCOUNTERSTODEPARTMENTS as ENCOUNTERS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        ENCOUNTERSTODIAGNOSES as ENCOUNTERS(PRIMARY_DIAGNOSIS_KEY) references DIAGNOSES(DIAGNOSIS_KEY),
        CLINICALMEASURESTOPATIENTS as CLINICAL_MEASURES(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        CLINICALMEASURESTOENCOUNTERS as CLINICAL_MEASURES(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY),
        MEDICATIONSTOPATIENTS as MEDICATIONS(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        MEDICATIONSTOENCOUNTERS as MEDICATIONS(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY)
    )
    facts (
        ENCOUNTERS.ENCOUNTER_KEY as encounter_key comment='Encounter identifier',
        ENCOUNTERS.LENGTH_OF_STAY as length_of_stay comment='Length of stay in days',
        ENCOUNTERS.TOTAL_CHARGES as total_charges comment='Total charges for encounter in dollars',
        CLINICAL_MEASURES.MEASURE_VALUE as measure_value comment='Clinical measurement value',
        MEDICATIONS.DOSAGE as dosage comment='Medication dosage amount'
    )
    dimensions (
        PATIENTS.PATIENT_KEY as PATIENT_KEY,
        PATIENTS.GENDER as gender with synonyms=('sex','gender') comment='Patient gender',
        PATIENTS.RACE_ETHNICITY as race_ethnicity with synonyms=('race','ethnicity') comment='Patient race and ethnicity',
        PATIENTS.INSURANCE_TYPE as insurance_type with synonyms=('insurance','payer','coverage') comment='Insurance coverage type',
        PATIENTS.PRIMARY_LANGUAGE as primary_language with synonyms=('language') comment='Patient primary language',
        ENCOUNTERS.ENCOUNTER_DATE as encounter_date with synonyms=('date','visit date') comment='Date of encounter',
        ENCOUNTERS.ENCOUNTER_TYPE as encounter_type with synonyms=('visit type','encounter type') comment='Type of encounter (Inpatient, Outpatient, Emergency)',
        ENCOUNTERS.READMISSION_FLAG as readmission_flag with synonyms=('readmission','return visit') comment='Whether this is a readmission',
        PROVIDERS.PROVIDER_NAME as provider_name with synonyms=('doctor','physician','provider') comment='Healthcare provider name',
        PROVIDERS.PROVIDER_TYPE as provider_type with synonyms=('role','provider type') comment='Type of healthcare provider',
        PROVIDERS.SPECIALTY as specialty comment='Provider medical specialty',
        DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','unit','service') comment='Hospital department name',
        DEPARTMENTS.DEPARTMENT_TYPE as department_type comment='Type of department (Clinical, Administrative, Support)',
        DIAGNOSES.ICD10_CODE as icd10_code with synonyms=('diagnosis code','ICD code') comment='ICD-10 diagnosis code',
        DIAGNOSES.DIAGNOSIS_DESCRIPTION as diagnosis_description with synonyms=('diagnosis','condition','disease') comment='Description of diagnosis',
        DIAGNOSES.DIAGNOSIS_CATEGORY as diagnosis_category comment='Category of diagnosis',
        DIAGNOSES.SEVERITY_LEVEL as severity_level comment='Severity level of diagnosis',
        CLINICAL_MEASURES.MEASURE_TYPE as measure_type comment='Type of clinical measurement',
        CLINICAL_MEASURES.MEASURE_NAME as measure_name comment='Name of clinical measurement',
        CLINICAL_MEASURES.IS_ABNORMAL as is_abnormal comment='Whether measurement is abnormal'
    )
    metrics (
        ENCOUNTERS.TOTAL_ENCOUNTERS as COUNT(encounters.encounter_key) comment='Total number of encounters',
        ENCOUNTERS.AVERAGE_LENGTH_OF_STAY as AVG(encounters.length_of_stay) comment='Average length of stay',
        ENCOUNTERS.SUM_TOTAL_CHARGES as SUM(encounters.total_charges) comment='Total charges across encounters',
        ENCOUNTERS.READMISSION_RATE as AVG(CASE WHEN encounters.readmission_flag THEN 1.0 ELSE 0.0 END) comment='Readmission rate percentage',
        CLINICAL_MEASURES.ABNORMAL_RESULT_RATE as AVG(CASE WHEN clinical_measures.is_abnormal THEN 1.0 ELSE 0.0 END) comment='Rate of abnormal clinical results'
    )
    comment='Semantic view for clinical analytics including patient encounters, diagnoses, and treatments';

-- Operational Analytics Semantic View  
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.OPERATIONAL_ANALYTICS_VIEW
    tables (
        OPERATIONS AS OPERATIONAL_FACT primary key (OPERATIONAL_KEY),
        DEPARTMENTS AS DEPARTMENT_DIM primary key (DEPARTMENT_KEY),
        QUALITY_METRICS AS QUALITY_METRICS_FACT primary key (QUALITY_KEY)
    )
    relationships (
        OPERATIONSTODEPARTMENTS as OPERATIONS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        QUALITYMETRICSTODEPARTMENTS as QUALITY_METRICS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY)
    )
    facts (
        OPERATIONS.METRIC_VALUE as metric_value comment='Operational metric value',
        OPERATIONS.TARGET_VALUE as target_value comment='Target value for operational metric',
        OPERATIONS.VARIANCE_PERCENTAGE as variance_percentage comment='Variance from target as percentage',
        QUALITY_METRICS.NUMERATOR as numerator comment='Quality metric numerator',
        QUALITY_METRICS.DENOMINATOR as denominator comment='Quality metric denominator',
        QUALITY_METRICS.RATE_PERCENTAGE as rate_percentage comment='Quality metric rate percentage'
    )
    dimensions (
        DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','unit','service') comment='Hospital department name',
        DEPARTMENTS.DEPARTMENT_TYPE as department_type comment='Type of department',
        DEPARTMENTS.BED_CAPACITY as bed_capacity comment='Department bed capacity',
        OPERATIONS.MEASURE_DATE as measure_date with synonyms=('date') comment='Date of operational measurement',
        OPERATIONS.METRIC_TYPE as metric_type comment='Type of operational metric',
        OPERATIONS.METRIC_NAME as metric_name comment='Name of operational metric',
        QUALITY_METRICS.MEASURE_DATE as measure_date comment='Date of quality measurement',
        QUALITY_METRICS.QUALITY_MEASURE as quality_measure comment='Quality measure name',
        QUALITY_METRICS.BENCHMARK_RATE as benchmark_rate comment='Quality benchmark rate',
        QUALITY_METRICS.MEETS_BENCHMARK as meets_benchmark comment='Whether quality metric meets benchmark'
    )
    metrics (
        OPERATIONS.AVG_METRIC_VALUE as AVG(operations.metric_value) comment='Average operational metric value',
        OPERATIONS.TARGET_ACHIEVEMENT_RATE as AVG(CASE WHEN operations.metric_value >= operations.target_value THEN 1.0 ELSE 0.0 END) comment='Rate of achieving operational targets',
        QUALITY_METRICS.OVERALL_QUALITY_RATE as AVG(quality_metrics.rate_percentage) comment='Overall quality rate across metrics',
        QUALITY_METRICS.BENCHMARK_ACHIEVEMENT_RATE as AVG(CASE WHEN quality_metrics.meets_benchmark THEN 1.0 ELSE 0.0 END) comment='Rate of meeting quality benchmarks'
    )
    comment='Semantic view for operational analytics including departmental metrics and quality measures';

-- Research Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.RESEARCH_ANALYTICS_VIEW
    tables (
        RESEARCH_OUTCOMES AS RESEARCH_OUTCOMES_FACT primary key (OUTCOME_KEY),
        STUDIES AS RESEARCH_STUDY_DIM primary key (STUDY_KEY),
        PATIENTS AS PATIENT_DIM primary key (PATIENT_KEY),
        PROVIDERS AS PROVIDER_DIM primary key (PROVIDER_KEY)
    )
    relationships (
        OUTCOMESTOSTUDIES as RESEARCH_OUTCOMES(STUDY_KEY) references STUDIES(STUDY_KEY),
        OUTCOMESTOPATIENTS as RESEARCH_OUTCOMES(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        OUTCOMESTOPROVIDERS as RESEARCH_OUTCOMES(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY)
    )
    facts (
        RESEARCH_OUTCOMES.OUTCOME_VALUE as outcome_value comment='Research outcome measurement value',
        RESEARCH_OUTCOMES.BASELINE_VALUE as baseline_value comment='Baseline measurement before intervention',
        RESEARCH_OUTCOMES.IMPROVEMENT_FLAG as improvement_flag comment='Whether outcome showed improvement'
    )
    dimensions (
        STUDIES.STUDY_ID as study_id comment='Research study identifier',
        STUDIES.STUDY_TITLE as study_title with synonyms=('study','research title') comment='Title of research study',
        STUDIES.PRINCIPAL_INVESTIGATOR as principal_investigator with synonyms=('PI','researcher','investigator') comment='Principal investigator name',
        STUDIES.STUDY_PHASE as study_phase comment='Phase of research study',
        STUDIES.STUDY_STATUS as study_status comment='Current status of study',
        STUDIES.START_DATE as start_date comment='Study start date',
        STUDIES.END_DATE as end_date comment='Study end date',
        RESEARCH_OUTCOMES.OUTCOME_DATE as outcome_date with synonyms=('date') comment='Date of outcome measurement',
        RESEARCH_OUTCOMES.OUTCOME_TYPE as outcome_type comment='Type of research outcome',
        RESEARCH_OUTCOMES.OUTCOME_MEASURE as outcome_measure comment='Specific outcome measure',
        PATIENTS.GENDER as gender comment='Patient gender',
        PATIENTS.RACE_ETHNICITY as race_ethnicity comment='Patient race and ethnicity',
        PROVIDERS.PROVIDER_NAME as provider_name comment='Healthcare provider name',
        PROVIDERS.SPECIALTY as specialty comment='Provider medical specialty'
    )
    metrics (
        RESEARCH_OUTCOMES.TOTAL_PARTICIPANTS as COUNT(DISTINCT research_outcomes.patient_key) comment='Total number of study participants',
        RESEARCH_OUTCOMES.IMPROVEMENT_RATE as AVG(CASE WHEN research_outcomes.improvement_flag THEN 1.0 ELSE 0.0 END) comment='Rate of positive outcomes',
        RESEARCH_OUTCOMES.AVG_OUTCOME_VALUE as AVG(research_outcomes.outcome_value) comment='Average outcome value',
        RESEARCH_OUTCOMES.AVG_BASELINE_VALUE as AVG(research_outcomes.baseline_value) comment='Average baseline value',
        RESEARCH_OUTCOMES.AVG_IMPROVEMENT as AVG(research_outcomes.outcome_value - research_outcomes.baseline_value) comment='Average improvement from baseline'
    )
    comment='Semantic view for research analytics including study outcomes and participant demographics';

-- Financial Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.FINANCIAL_ANALYTICS_VIEW
    tables (
        FINANCIAL_TRANSACTIONS AS FINANCIAL_FACT primary key (TRANSACTION_KEY),
        ENCOUNTERS AS PATIENT_ENCOUNTER_FACT primary key (ENCOUNTER_KEY),
        PATIENTS AS PATIENT_DIM primary key (PATIENT_KEY),
        PAYERS AS PAYER_DIM primary key (PAYER_KEY),
        DEPARTMENTS AS DEPARTMENT_DIM primary key (DEPARTMENT_KEY)
    )
    relationships (
        TRANSACTIONSTOENCOUNTERS as FINANCIAL_TRANSACTIONS(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY),
        TRANSACTIONSTOPAYERS as FINANCIAL_TRANSACTIONS(PAYER_KEY) references PAYERS(PAYER_KEY),
        TRANSACTIONSTODEPARTMENTS as FINANCIAL_TRANSACTIONS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        ENCOUNTERSTOPATIENTS as ENCOUNTERS(PATIENT_KEY) references PATIENTS(PATIENT_KEY)
    )
    facts (
        FINANCIAL_TRANSACTIONS.CHARGE_AMOUNT as charge_amount comment='Charge amount in dollars',
        FINANCIAL_TRANSACTIONS.PAYMENT_AMOUNT as payment_amount comment='Payment amount in dollars',
        FINANCIAL_TRANSACTIONS.ADJUSTMENT_AMOUNT as adjustment_amount comment='Adjustment amount in dollars',
        ENCOUNTERS.TOTAL_CHARGES as total_charges comment='Total charges for encounter'
    )
    dimensions (
        FINANCIAL_TRANSACTIONS.TRANSACTION_DATE as transaction_date with synonyms=('date') comment='Date of financial transaction',
        FINANCIAL_TRANSACTIONS.TRANSACTION_TYPE as transaction_type comment='Type of transaction (Charge, Payment, Adjustment)',
        PATIENTS.INSURANCE_TYPE as insurance_type comment='Patient insurance type',
        PATIENTS.RACE_ETHNICITY as race_ethnicity comment='Patient race and ethnicity',
        PAYERS.PAYER_NAME as payer_name with synonyms=('insurance company','payer') comment='Insurance payer name',
        PAYERS.PAYER_TYPE as payer_type comment='Type of payer (Medicaid, Private, Self-Pay)',
        DEPARTMENTS.DEPARTMENT_NAME as department_name comment='Department generating charges',
        ENCOUNTERS.ENCOUNTER_TYPE as encounter_type comment='Type of encounter generating charges'
    )
    metrics (
        FINANCIAL_TRANSACTIONS.SUM_CHARGES as SUM(financial_transactions.charge_amount) comment='Total charges from transactions',
        FINANCIAL_TRANSACTIONS.TOTAL_PAYMENTS as SUM(financial_transactions.payment_amount) comment='Total payments received',
        FINANCIAL_TRANSACTIONS.TOTAL_ADJUSTMENTS as SUM(financial_transactions.adjustment_amount) comment='Total adjustments',
        FINANCIAL_TRANSACTIONS.NET_REVENUE as SUM(financial_transactions.payment_amount - financial_transactions.adjustment_amount) comment='Net revenue after adjustments',
        FINANCIAL_TRANSACTIONS.COLLECTION_RATE as SUM(financial_transactions.payment_amount) / NULLIF(SUM(financial_transactions.charge_amount), 0) comment='Payment collection rate'
    )
    comment='Semantic view for financial analytics including billing, payments, and revenue analysis';

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Show all semantic views
SHOW SEMANTIC VIEWS;

-- Verify semantic view structure
DESCRIBE SEMANTIC VIEW CLINICAL_ANALYTICS_VIEW;
DESCRIBE SEMANTIC VIEW OPERATIONAL_ANALYTICS_VIEW;
DESCRIBE SEMANTIC VIEW RESEARCH_ANALYTICS_VIEW;
DESCRIBE SEMANTIC VIEW FINANCIAL_ANALYTICS_VIEW;

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT '✅ Step 3 Complete: Semantic views created successfully!' as status;
SELECT 'Next: Run 04_agent_setup.sql' as next_step;

-- ========================================================================
-- EXAMPLE NATURAL LANGUAGE QUERIES
-- ========================================================================

/*
📋 SAMPLE CORTEX ANALYST QUERIES:

Once you have data in your tables, you can use these natural language queries 
with Cortex Analyst:

🏥 CLINICAL QUERIES:
- "What is the average length of stay for pediatric ICU patients?"
- "Show me readmission rates by department"
- "Which diagnoses have the highest charges?"
- "What are the most common abnormal clinical measurements?"

📊 OPERATIONAL QUERIES:
- "Which departments are meeting their quality benchmarks?"
- "Show bed occupancy rates by department"
- "What is our overall quality performance this month?"
- "Which operational metrics are below target?"

🔬 RESEARCH QUERIES:
- "How many patients are enrolled in active research studies?"
- "What is the improvement rate for our oncology studies?"
- "Show research outcomes by principal investigator"
- "Which studies have the best patient outcomes?"

💰 FINANCIAL QUERIES:
- "What is our collection rate by payer type?"
- "Show net revenue by department"
- "Which encounter types generate the most charges?"
- "What percentage of our revenue comes from Medicaid?"

To use these queries:
1. Open Snowsight
2. Navigate to Data > Databases > PEDIATRIC_HOSPITAL_AI_DEMO > CLINICAL_SCHEMA
3. Select any semantic view
4. Click "Query with Analyst" 
5. Type your natural language question

The Cortex Analyst will automatically generate SQL and return results!
*/
