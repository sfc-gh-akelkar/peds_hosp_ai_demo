-- ========================================================================
-- Snowflake AI Demo - Pediatric Hospital Setup Script
-- Pediatric Hospital Demo - Healthcare Analytics
-- This script creates healthcare-specific database, schema, tables, and loads synthetic medical data
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Enable Snowflake Intelligence by creating the Config DB & Schema
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

create or replace role Pediatric_Hospital_Demo;

SET current_user_name = CURRENT_USER();

-- Grant the role to current user
GRANT ROLE Pediatric_Hospital_Demo TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE Pediatric_Hospital_Demo;

-- Create a dedicated warehouse for the healthcare demo
CREATE OR REPLACE WAREHOUSE Pediatric_Hospital_demo_wh 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse
GRANT USAGE ON WAREHOUSE Pediatric_Hospital_demo_wh TO ROLE Pediatric_Hospital_Demo;

-- Set default role and warehouse
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = Pediatric_Hospital_Demo;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = Pediatric_Hospital_demo_wh;

-- Switch to demo role
use role Pediatric_Hospital_Demo;

-- Create database and schema
CREATE OR REPLACE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;
USE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;

CREATE SCHEMA IF NOT EXISTS CLINICAL_SCHEMA;
USE SCHEMA CLINICAL_SCHEMA;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

use role accountadmin;
-- Create API Integration for GitHub (public repository access)
CREATE OR REPLACE API INTEGRATION healthcare_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/your-repo/')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION healthcare_git_api_integration TO ROLE Pediatric_Hospital_Demo;

use role Pediatric_Hospital_Demo;

-- Create internal stage for healthcare data files
CREATE OR REPLACE STAGE INTERNAL_HEALTHCARE_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Internal stage for healthcare demo data files'
    DIRECTORY = ( ENABLE = TRUE)
    ENCRYPTION = (   TYPE = 'SNOWFLAKE_SSE');

-- ========================================================================
-- HEALTHCARE DIMENSION TABLES
-- ========================================================================

-- Patient Dimension
CREATE OR REPLACE TABLE patient_dim (
    patient_key INT PRIMARY KEY,
    medical_record_number VARCHAR(20) NOT NULL,
    patient_first_name VARCHAR(100),
    patient_last_name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(1),
    race_ethnicity VARCHAR(50),
    primary_language VARCHAR(50),
    insurance_type VARCHAR(50),
    zip_code VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE
);

-- Provider Dimension (Physicians, Nurses, etc.)
CREATE OR REPLACE TABLE provider_dim (
    provider_key INT PRIMARY KEY,
    provider_id VARCHAR(20) NOT NULL,
    provider_name VARCHAR(200) NOT NULL,
    provider_type VARCHAR(50), -- Physician, Nurse, Specialist, etc.
    specialty VARCHAR(100),
    department_key INT,
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Department Dimension
CREATE OR REPLACE TABLE department_dim (
    department_key INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_type VARCHAR(50), -- Clinical, Administrative, Support
    floor_location VARCHAR(20),
    bed_capacity INT
);

-- Diagnosis Dimension (ICD-10 codes)
CREATE OR REPLACE TABLE diagnosis_dim (
    diagnosis_key INT PRIMARY KEY,
    icd10_code VARCHAR(10) NOT NULL,
    diagnosis_description VARCHAR(500) NOT NULL,
    diagnosis_category VARCHAR(100),
    severity_level VARCHAR(20)
);

-- Procedure Dimension (CPT codes)
CREATE OR REPLACE TABLE procedure_dim (
    procedure_key INT PRIMARY KEY,
    cpt_code VARCHAR(10) NOT NULL,
    procedure_description VARCHAR(500) NOT NULL,
    procedure_category VARCHAR(100),
    complexity_level VARCHAR(20)
);

-- Medication Dimension
CREATE OR REPLACE TABLE medication_dim (
    medication_key INT PRIMARY KEY,
    medication_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    drug_class VARCHAR(100),
    dosage_form VARCHAR(50),
    strength VARCHAR(50)
);

-- Payer Dimension (Insurance)
CREATE OR REPLACE TABLE payer_dim (
    payer_key INT PRIMARY KEY,
    payer_name VARCHAR(200) NOT NULL,
    payer_type VARCHAR(50), -- Medicaid, Private, Self-Pay
    contract_type VARCHAR(50)
);

-- Research Study Dimension
CREATE OR REPLACE TABLE research_study_dim (
    study_key INT PRIMARY KEY,
    study_id VARCHAR(50) NOT NULL,
    study_title VARCHAR(500) NOT NULL,
    principal_investigator VARCHAR(200),
    study_phase VARCHAR(20),
    study_status VARCHAR(50), -- Active, Completed, Recruiting
    start_date DATE,
    end_date DATE
);

-- ========================================================================
-- HEALTHCARE FACT TABLES
-- ========================================================================

-- Patient Encounters Fact
CREATE OR REPLACE TABLE patient_encounter_fact (
    encounter_key INT PRIMARY KEY,
    encounter_id VARCHAR(50) NOT NULL,
    patient_key INT NOT NULL,
    provider_key INT NOT NULL,
    department_key INT NOT NULL,
    encounter_date DATE NOT NULL,
    encounter_type VARCHAR(50), -- Inpatient, Outpatient, Emergency
    admission_date DATE,
    discharge_date DATE,
    length_of_stay INT,
    total_charges DECIMAL(12,2),
    primary_diagnosis_key INT,
    readmission_flag BOOLEAN DEFAULT FALSE
);

-- Clinical Measures Fact
CREATE OR REPLACE TABLE clinical_measures_fact (
    measure_key INT PRIMARY KEY,
    patient_key INT NOT NULL,
    encounter_key INT NOT NULL,
    provider_key INT NOT NULL,
    measure_date TIMESTAMP NOT NULL,
    measure_type VARCHAR(50), -- Vital Signs, Lab Results, etc.
    measure_name VARCHAR(100),
    measure_value DECIMAL(10,3),
    measure_unit VARCHAR(20),
    normal_range_low DECIMAL(10,3),
    normal_range_high DECIMAL(10,3),
    is_abnormal BOOLEAN
);

-- Medication Administration Fact
CREATE OR REPLACE TABLE medication_fact (
    medication_fact_key INT PRIMARY KEY,
    patient_key INT NOT NULL,
    encounter_key INT NOT NULL,
    medication_key INT NOT NULL,
    provider_key INT NOT NULL,
    administration_date TIMESTAMP NOT NULL,
    dosage DECIMAL(10,3),
    dosage_unit VARCHAR(20),
    route VARCHAR(50), -- Oral, IV, etc.
    frequency VARCHAR(50)
);

-- Financial Transactions Fact
CREATE OR REPLACE TABLE financial_fact (
    transaction_key INT PRIMARY KEY,
    patient_key INT NOT NULL,
    encounter_key INT NOT NULL,
    payer_key INT NOT NULL,
    department_key INT NOT NULL,
    transaction_date DATE NOT NULL,
    service_date DATE,
    charge_amount DECIMAL(12,2),
    payment_amount DECIMAL(12,2),
    adjustment_amount DECIMAL(12,2),
    transaction_type VARCHAR(50) -- Charge, Payment, Adjustment
);

-- Operational Metrics Fact
CREATE OR REPLACE TABLE operational_fact (
    operational_key INT PRIMARY KEY,
    department_key INT NOT NULL,
    measure_date DATE NOT NULL,
    metric_type VARCHAR(50), -- Bed Occupancy, Staffing, Wait Times
    metric_name VARCHAR(100),
    metric_value DECIMAL(10,2),
    target_value DECIMAL(10,2),
    variance_percentage DECIMAL(5,2)
);

-- Research Outcomes Fact
CREATE OR REPLACE TABLE research_outcomes_fact (
    outcome_key INT PRIMARY KEY,
    patient_key INT NOT NULL,
    study_key INT NOT NULL,
    provider_key INT NOT NULL,
    outcome_date DATE NOT NULL,
    outcome_type VARCHAR(100), -- Primary Endpoint, Secondary Endpoint
    outcome_measure VARCHAR(200),
    outcome_value DECIMAL(10,3),
    baseline_value DECIMAL(10,3),
    improvement_flag BOOLEAN
);

-- Quality Metrics Fact
CREATE OR REPLACE TABLE quality_metrics_fact (
    quality_key INT PRIMARY KEY,
    department_key INT NOT NULL,
    measure_date DATE NOT NULL,
    quality_measure VARCHAR(200), -- Patient Satisfaction, Infection Rate, etc.
    numerator INT,
    denominator INT,
    rate_percentage DECIMAL(5,2),
    benchmark_rate DECIMAL(5,2),
    meets_benchmark BOOLEAN
);

-- ========================================================================
-- FOREIGN KEY RELATIONSHIPS (for documentation)
-- ========================================================================

-- ALTER TABLE provider_dim ADD CONSTRAINT fk_provider_dept 
--     FOREIGN KEY (department_key) REFERENCES department_dim(department_key);

-- ALTER TABLE patient_encounter_fact ADD CONSTRAINT fk_encounter_patient 
--     FOREIGN KEY (patient_key) REFERENCES patient_dim(patient_key);

-- ALTER TABLE patient_encounter_fact ADD CONSTRAINT fk_encounter_provider 
--     FOREIGN KEY (provider_key) REFERENCES provider_dim(provider_key);

-- (Additional foreign keys would be defined here in a production environment)

-- ========================================================================
-- SAMPLE DATA INSERTION (Synthetic Healthcare Data)
-- ========================================================================

-- Insert sample departments
INSERT INTO department_dim VALUES
(1, 'Pediatric ICU', 'Clinical', '3rd Floor', 24),
(2, 'Neonatal ICU', 'Clinical', '4th Floor', 32),
(3, 'Emergency Department', 'Clinical', '1st Floor', 45),
(4, 'Cardiology', 'Clinical', '2nd Floor', 20),
(5, 'Oncology', 'Clinical', '5th Floor', 28),
(6, 'General Pediatrics', 'Clinical', '2nd Floor', 50),
(7, 'Surgery', 'Clinical', '6th Floor', 15),
(8, 'Radiology', 'Support', 'Basement', 0),
(9, 'Laboratory', 'Support', 'Basement', 0),
(10, 'Administration', 'Administrative', '7th Floor', 0);

-- Insert sample diagnoses (pediatric focus)
INSERT INTO diagnosis_dim VALUES
(1, 'J45.9', 'Asthma, unspecified', 'Respiratory', 'Moderate'),
(2, 'E10.9', 'Type 1 diabetes mellitus without complications', 'Endocrine', 'Chronic'),
(3, 'Z00.121', 'Encounter for routine child health examination with abnormal findings', 'Wellness', 'Low'),
(4, 'F90.9', 'Attention-deficit hyperactivity disorder, unspecified type', 'Mental Health', 'Moderate'),
(5, 'Q21.3', 'Tetralogy of Fallot', 'Congenital Heart', 'High'),
(6, 'J06.9', 'Acute upper respiratory infection, unspecified', 'Respiratory', 'Low'),
(7, 'C91.00', 'Acute lymphoblastic leukemia not having achieved remission', 'Oncology', 'High'),
(8, 'P07.30', 'Preterm newborn, unspecified weeks of gestation', 'Neonatal', 'High'),
(9, 'G93.1', 'Anoxic brain damage, not elsewhere classified', 'Neurological', 'High'),
(10, 'R50.9', 'Fever, unspecified', 'Symptoms', 'Low');

-- Insert sample procedures
INSERT INTO procedure_dim VALUES
(1, '99213', 'Office outpatient visit 15 minutes', 'Evaluation', 'Low'),
(2, '99291', 'Critical care, first 30-74 minutes', 'Critical Care', 'High'),
(3, '36415', 'Collection of venous blood by venipuncture', 'Laboratory', 'Low'),
(4, '71020', 'Radiologic examination, chest, 2 views', 'Imaging', 'Low'),
(5, '33692', 'Complete repair tetralogy of Fallot', 'Cardiac Surgery', 'High'),
(6, '31500', 'Intubation, endotracheal, emergency procedure', 'Emergency', 'High'),
(7, '96413', 'Chemotherapy administration, intravenous infusion', 'Oncology', 'Moderate'),
(8, '94060', 'Bronchodilation responsiveness, spirometry', 'Pulmonary', 'Moderate'),
(9, '90460', 'Immunization administration through 18 years', 'Preventive', 'Low'),
(10, '99285', 'Emergency department visit for the evaluation', 'Emergency', 'Moderate');

-- Insert sample medications (pediatric appropriate)
INSERT INTO medication_dim VALUES
(1, 'Albuterol', 'Albuterol Sulfate', 'Bronchodilator', 'Inhaler', '90 mcg/dose'),
(2, 'Insulin Glargine', 'Insulin Glargine', 'Insulin', 'Injection', '100 units/mL'),
(3, 'Amoxicillin', 'Amoxicillin', 'Antibiotic', 'Oral Suspension', '250mg/5mL'),
(4, 'Ibuprofen', 'Ibuprofen', 'NSAID', 'Oral Suspension', '100mg/5mL'),
(5, 'Vincristine', 'Vincristine Sulfate', 'Chemotherapy', 'Injection', '1mg/mL'),
(6, 'Methylphenidate', 'Methylphenidate HCl', 'Stimulant', 'Tablet', '10mg'),
(7, 'Furosemide', 'Furosemide', 'Diuretic', 'Injection', '10mg/mL'),
(8, 'Acetaminophen', 'Acetaminophen', 'Analgesic', 'Oral Suspension', '160mg/5mL'),
(9, 'Digoxin', 'Digoxin', 'Cardiac Glycoside', 'Oral Solution', '0.05mg/mL'),
(10, 'Ceftriaxone', 'Ceftriaxone Sodium', 'Antibiotic', 'Injection', '1g/vial');

-- Insert sample payers
INSERT INTO payer_dim VALUES
(1, 'Illinois Medicaid', 'Medicaid', 'State Program'),
(2, 'Blue Cross Blue Shield', 'Private', 'Commercial'),
(3, 'Aetna Better Health', 'Medicaid Managed', 'Managed Care'),
(4, 'Self Pay', 'Self-Pay', 'Uninsured'),
(5, 'UnitedHealthcare', 'Private', 'Commercial'),
(6, 'Humana', 'Private', 'Commercial'),
(7, 'TRICARE', 'Government', 'Military'),
(8, 'Workers Compensation', 'Workers Comp', 'Injury Related'),
(9, 'Molina Healthcare', 'Medicaid Managed', 'Managed Care'),
(10, 'CountyCare', 'Medicaid Managed', 'County Program');

-- Show tables created
SHOW TABLES IN SCHEMA CLINICAL_SCHEMA;

-- ========================================================================
-- VERIFICATION QUERIES
-- ========================================================================

-- ========================================================================
-- HEALTHCARE SEMANTIC VIEWS FOR CORTEX ANALYST
-- ========================================================================

-- Clinical Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.CLINICAL_ANALYTICS_VIEW
    tables (
        PATIENTS as PATIENT_DIM primary key (PATIENT_KEY) with synonyms=('patients','children','kids') comment='Patient demographic and enrollment information',
        ENCOUNTERS as PATIENT_ENCOUNTER_FACT primary key (ENCOUNTER_KEY) with synonyms=('visits','admissions','encounters') comment='Patient encounters including ED visits and hospitalizations',
        PROVIDERS as PROVIDER_DIM primary key (PROVIDER_KEY) with synonyms=('physicians','doctors','nurses','providers') comment='Healthcare providers caring for patients',
        DEPARTMENTS as DEPARTMENT_DIM primary key (DEPARTMENT_KEY) with synonyms=('departments','units','services') comment='Hospital departments and clinical units',
        DIAGNOSES as DIAGNOSIS_DIM primary key (DIAGNOSIS_KEY) with synonyms=('diagnoses','conditions','diseases') comment='ICD-10 diagnosis codes and descriptions',
        PROCEDURES as PROCEDURE_DIM primary key (PROCEDURE_KEY) with synonyms=('procedures','treatments','interventions') comment='CPT procedure codes and descriptions',
        CLINICAL_MEASURES as CLINICAL_MEASURES_FACT primary key (MEASURE_KEY) with synonyms=('lab results','vital signs','measurements') comment='Clinical measurements and lab results',
        MEDICATIONS as MEDICATION_FACT primary key (MEDICATION_FACT_KEY) with synonyms=('medications','drugs','prescriptions') comment='Medication administration records'
    )
    relationships (
        ENCOUNTERS_TO_PATIENTS as ENCOUNTERS(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        ENCOUNTERS_TO_PROVIDERS as ENCOUNTERS(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY),
        ENCOUNTERS_TO_DEPARTMENTS as ENCOUNTERS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        ENCOUNTERS_TO_DIAGNOSES as ENCOUNTERS(PRIMARY_DIAGNOSIS_KEY) references DIAGNOSES(DIAGNOSIS_KEY),
        CLINICAL_MEASURES_TO_PATIENTS as CLINICAL_MEASURES(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        CLINICAL_MEASURES_TO_ENCOUNTERS as CLINICAL_MEASURES(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY),
        MEDICATIONS_TO_PATIENTS as MEDICATIONS(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        MEDICATIONS_TO_ENCOUNTERS as MEDICATIONS(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY)
    )
    facts (
        ENCOUNTERS.ENCOUNTER_RECORD as 1 comment='Count of patient encounters',
        ENCOUNTERS.LENGTH_OF_STAY as length_of_stay comment='Length of stay in days',
        ENCOUNTERS.TOTAL_CHARGES as charges comment='Total charges for encounter in dollars',
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
        ENCOUNTERS.TOTAL_ENCOUNTERS as COUNT(encounters.encounter_record) comment='Total number of encounters',
        ENCOUNTERS.AVERAGE_LENGTH_OF_STAY as AVG(encounters.length_of_stay) comment='Average length of stay',
        ENCOUNTERS.TOTAL_CHARGES as SUM(encounters.charges) comment='Total charges across encounters',
        ENCOUNTERS.READMISSION_RATE as AVG(CASE WHEN encounters.readmission_flag THEN 1.0 ELSE 0.0 END) comment='Readmission rate percentage',
        CLINICAL_MEASURES.ABNORMAL_RESULT_RATE as AVG(CASE WHEN clinical_measures.is_abnormal THEN 1.0 ELSE 0.0 END) comment='Rate of abnormal clinical results'
    )
    comment='Semantic view for clinical analytics including patient encounters, diagnoses, and treatments';

-- Operational Analytics Semantic View  
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.OPERATIONAL_ANALYTICS_VIEW
    tables (
        DEPARTMENTS as DEPARTMENT_DIM primary key (DEPARTMENT_KEY) with synonyms=('departments','units','services') comment='Hospital departments and units',
        OPERATIONAL_METRICS as OPERATIONAL_FACT primary key (OPERATIONAL_KEY) with synonyms=('operations','metrics','performance') comment='Operational performance metrics',
        QUALITY_METRICS as QUALITY_METRICS_FACT primary key (QUALITY_KEY) with synonyms=('quality','safety','performance') comment='Quality and safety metrics',
        ENCOUNTERS as PATIENT_ENCOUNTER_FACT primary key (ENCOUNTER_KEY) with synonyms=('encounters','visits','admissions') comment='Patient encounters for operational analysis'
    )
    relationships (
        OPERATIONAL_TO_DEPARTMENTS as OPERATIONAL_METRICS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        QUALITY_TO_DEPARTMENTS as QUALITY_METRICS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        ENCOUNTERS_TO_DEPARTMENTS as ENCOUNTERS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY)
    )
    facts (
        OPERATIONAL_METRICS.METRIC_VALUE as metric_value comment='Operational metric value',
        OPERATIONAL_METRICS.TARGET_VALUE as target_value comment='Target value for metric',
        OPERATIONAL_METRICS.VARIANCE_PERCENTAGE as variance_percentage comment='Variance from target as percentage',
        QUALITY_METRICS.NUMERATOR as numerator comment='Quality metric numerator',
        QUALITY_METRICS.DENOMINATOR as denominator comment='Quality metric denominator', 
        QUALITY_METRICS.RATE_PERCENTAGE as rate_percentage comment='Quality rate as percentage',
        ENCOUNTERS.LENGTH_OF_STAY as length_of_stay comment='Patient length of stay'
    )
    dimensions (
        DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','unit') comment='Hospital department name',
        DEPARTMENTS.DEPARTMENT_TYPE as department_type comment='Type of department',
        DEPARTMENTS.BED_CAPACITY as bed_capacity comment='Department bed capacity',
        OPERATIONAL_METRICS.MEASURE_DATE as measure_date with synonyms=('date') comment='Date of operational measurement',
        OPERATIONAL_METRICS.METRIC_TYPE as metric_type comment='Type of operational metric',
        OPERATIONAL_METRICS.METRIC_NAME as metric_name comment='Name of operational metric',
        QUALITY_METRICS.QUALITY_MEASURE as quality_measure comment='Name of quality measure',
        QUALITY_METRICS.MEETS_BENCHMARK as meets_benchmark comment='Whether quality benchmark is met'
    )
    metrics (
        OPERATIONAL_METRICS.AVERAGE_METRIC_VALUE as AVG(operational_metrics.metric_value) comment='Average operational metric value',
        OPERATIONAL_METRICS.METRICS_MEETING_TARGET as AVG(CASE WHEN operational_metrics.metric_value >= operational_metrics.target_value THEN 1.0 ELSE 0.0 END) comment='Percentage of metrics meeting target',
        QUALITY_METRICS.AVERAGE_QUALITY_RATE as AVG(quality_metrics.rate_percentage) comment='Average quality rate',
        QUALITY_METRICS.BENCHMARKS_MET as AVG(CASE WHEN quality_metrics.meets_benchmark THEN 1.0 ELSE 0.0 END) comment='Percentage of benchmarks met',
        ENCOUNTERS.AVERAGE_LENGTH_OF_STAY as AVG(encounters.length_of_stay) comment='Average length of stay by department'
    )
    comment='Semantic view for operational analytics including performance metrics and quality measures';

-- Research Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.RESEARCH_ANALYTICS_VIEW
    tables (
        STUDIES as RESEARCH_STUDY_DIM primary key (STUDY_KEY) with synonyms=('studies','research','trials') comment='Research studies and clinical trials',
        RESEARCH_OUTCOMES as RESEARCH_OUTCOMES_FACT primary key (OUTCOME_KEY) with synonyms=('outcomes','results','findings') comment='Research study outcomes and results',
        PATIENTS as PATIENT_DIM primary key (PATIENT_KEY) with synonyms=('subjects','participants','patients') comment='Research study participants',
        PROVIDERS as PROVIDER_DIM primary key (PROVIDER_KEY) with synonyms=('investigators','researchers','providers') comment='Research investigators and staff'
    )
    relationships (
        OUTCOMES_TO_STUDIES as RESEARCH_OUTCOMES(STUDY_KEY) references STUDIES(STUDY_KEY),
        OUTCOMES_TO_PATIENTS as RESEARCH_OUTCOMES(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        OUTCOMES_TO_PROVIDERS as RESEARCH_OUTCOMES(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY)
    )
    facts (
        RESEARCH_OUTCOMES.OUTCOME_VALUE as outcome_value comment='Research outcome measurement value',
        RESEARCH_OUTCOMES.BASELINE_VALUE as baseline_value comment='Baseline measurement value',
        RESEARCH_OUTCOMES.IMPROVEMENT_FLAG as improvement_flag comment='Whether outcome showed improvement'
    )
    dimensions (
        STUDIES.STUDY_ID as study_id comment='Research study identifier',
        STUDIES.STUDY_TITLE as study_title with synonyms=('study','research title') comment='Research study title',
        STUDIES.PRINCIPAL_INVESTIGATOR as principal_investigator with synonyms=('PI','investigator') comment='Principal investigator name',
        STUDIES.STUDY_PHASE as study_phase comment='Clinical trial phase',
        STUDIES.STUDY_STATUS as study_status comment='Current study status',
        STUDIES.START_DATE as start_date comment='Study start date',
        STUDIES.END_DATE as end_date comment='Study end date',
        RESEARCH_OUTCOMES.OUTCOME_DATE as outcome_date with synonyms=('date') comment='Date of outcome measurement',
        RESEARCH_OUTCOMES.OUTCOME_TYPE as outcome_type comment='Type of research outcome',
        RESEARCH_OUTCOMES.OUTCOME_MEASURE as outcome_measure comment='Name of outcome measure',
        PATIENTS.RACE_ETHNICITY as race_ethnicity comment='Participant race and ethnicity',
        PATIENTS.GENDER as gender comment='Participant gender',
        PROVIDERS.SPECIALTY as investigator_specialty comment='Investigator medical specialty'
    )
    metrics (
        RESEARCH_OUTCOMES.TOTAL_OUTCOMES as COUNT(research_outcomes.outcome_value) comment='Total number of outcome measurements',
        RESEARCH_OUTCOMES.IMPROVEMENT_RATE as AVG(CASE WHEN research_outcomes.improvement_flag THEN 1.0 ELSE 0.0 END) comment='Rate of positive outcomes',
        RESEARCH_OUTCOMES.AVERAGE_OUTCOME_VALUE as AVG(research_outcomes.outcome_value) comment='Average outcome value',
        RESEARCH_OUTCOMES.BASELINE_TO_OUTCOME_CHANGE as AVG(research_outcomes.outcome_value - research_outcomes.baseline_value) comment='Average change from baseline'
    )
    comment='Semantic view for research analytics including study outcomes and participant data';

-- Financial Analytics Semantic View
CREATE OR REPLACE SEMANTIC VIEW PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.FINANCIAL_ANALYTICS_VIEW
    tables (
        FINANCIAL_TRANSACTIONS as FINANCIAL_FACT primary key (TRANSACTION_KEY) with synonyms=('transactions','billing','charges') comment='Financial transactions and billing data',
        PATIENTS as PATIENT_DIM primary key (PATIENT_KEY) with synonyms=('patients') comment='Patient information for financial analysis',
        ENCOUNTERS as PATIENT_ENCOUNTER_FACT primary key (ENCOUNTER_KEY) with synonyms=('encounters','visits') comment='Patient encounters with charges',
        PAYERS as PAYER_DIM primary key (PAYER_KEY) with synonyms=('insurance','payers','coverage') comment='Insurance payers and coverage types',
        DEPARTMENTS as DEPARTMENT_DIM primary key (DEPARTMENT_KEY) with synonyms=('departments','services') comment='Hospital departments generating charges'
    )
    relationships (
        TRANSACTIONS_TO_PATIENTS as FINANCIAL_TRANSACTIONS(PATIENT_KEY) references PATIENTS(PATIENT_KEY),
        TRANSACTIONS_TO_ENCOUNTERS as FINANCIAL_TRANSACTIONS(ENCOUNTER_KEY) references ENCOUNTERS(ENCOUNTER_KEY),
        TRANSACTIONS_TO_PAYERS as FINANCIAL_TRANSACTIONS(PAYER_KEY) references PAYERS(PAYER_KEY),
        TRANSACTIONS_TO_DEPARTMENTS as FINANCIAL_TRANSACTIONS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY)
    )
    facts (
        FINANCIAL_TRANSACTIONS.CHARGE_AMOUNT as charge_amount comment='Charge amount in dollars',
        FINANCIAL_TRANSACTIONS.PAYMENT_AMOUNT as payment_amount comment='Payment amount in dollars',
        FINANCIAL_TRANSACTIONS.ADJUSTMENT_AMOUNT as adjustment_amount comment='Adjustment amount in dollars',
        ENCOUNTERS.TOTAL_CHARGES as encounter_charges comment='Total charges for encounter'
    )
    dimensions (
        FINANCIAL_TRANSACTIONS.TRANSACTION_DATE as transaction_date with synonyms=('date') comment='Date of financial transaction',
        FINANCIAL_TRANSACTIONS.TRANSACTION_TYPE as transaction_type comment='Type of transaction (Charge, Payment, Adjustment)',
        PATIENTS.INSURANCE_TYPE as patient_insurance_type comment='Patient insurance type',
        PATIENTS.RACE_ETHNICITY as race_ethnicity comment='Patient race and ethnicity',
        PAYERS.PAYER_NAME as payer_name with synonyms=('insurance company','payer') comment='Insurance payer name',
        PAYERS.PAYER_TYPE as payer_type comment='Type of payer (Medicaid, Private, Self-Pay)',
        DEPARTMENTS.DEPARTMENT_NAME as department_name comment='Department generating charges',
        ENCOUNTERS.ENCOUNTER_TYPE as encounter_type comment='Type of encounter generating charges'
    )
    metrics (
        FINANCIAL_TRANSACTIONS.TOTAL_CHARGES as SUM(financial_transactions.charge_amount) comment='Total charges',
        FINANCIAL_TRANSACTIONS.TOTAL_PAYMENTS as SUM(financial_transactions.payment_amount) comment='Total payments received',
        FINANCIAL_TRANSACTIONS.TOTAL_ADJUSTMENTS as SUM(financial_transactions.adjustment_amount) comment='Total adjustments',
        FINANCIAL_TRANSACTIONS.NET_REVENUE as SUM(financial_transactions.payment_amount - financial_transactions.adjustment_amount) comment='Net revenue after adjustments',
        FINANCIAL_TRANSACTIONS.COLLECTION_RATE as SUM(financial_transactions.payment_amount) / NULLIF(SUM(financial_transactions.charge_amount), 0) comment='Payment collection rate'
    )
    comment='Semantic view for financial analytics including billing, payments, and revenue analysis';

-- Show all semantic views
SHOW SEMANTIC VIEWS;

SELECT 'DIMENSION TABLES' as category, '' as table_name, NULL as row_count
UNION ALL
SELECT '', 'patient_dim', COUNT(*) FROM patient_dim
UNION ALL
SELECT '', 'provider_dim', COUNT(*) FROM provider_dim
UNION ALL
SELECT '', 'department_dim', COUNT(*) FROM department_dim
UNION ALL
SELECT '', 'diagnosis_dim', COUNT(*) FROM diagnosis_dim
UNION ALL
SELECT '', 'procedure_dim', COUNT(*) FROM procedure_dim
UNION ALL
SELECT '', 'medication_dim', COUNT(*) FROM medication_dim
UNION ALL
SELECT '', 'payer_dim', COUNT(*) FROM payer_dim
UNION ALL
SELECT '', 'research_study_dim', COUNT(*) FROM research_study_dim
UNION ALL
SELECT '', '', NULL
UNION ALL
SELECT 'FACT TABLES', '', NULL
UNION ALL
SELECT '', 'patient_encounter_fact', COUNT(*) FROM patient_encounter_fact
UNION ALL
SELECT '', 'clinical_measures_fact', COUNT(*) FROM clinical_measures_fact
UNION ALL
SELECT '', 'medication_fact', COUNT(*) FROM medication_fact
UNION ALL
SELECT '', 'financial_fact', COUNT(*) FROM financial_fact
UNION ALL
SELECT '', 'operational_fact', COUNT(*) FROM operational_fact
UNION ALL
SELECT '', 'research_outcomes_fact', COUNT(*) FROM research_outcomes_fact
UNION ALL
SELECT '', 'quality_metrics_fact', COUNT(*) FROM quality_metrics_fact;

-- ========================================================================
-- CORTEX SEARCH SERVICES FOR HEALTHCARE DOCUMENTS
-- ========================================================================

-- Create table for parsed healthcare documents
CREATE OR REPLACE TABLE parsed_healthcare_documents AS 
SELECT 
    relative_path, 
    BUILD_STAGE_FILE_URL('@PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE', relative_path) as file_url,
    TO_FILE(BUILD_STAGE_FILE_URL('@PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE', relative_path)) file_object,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE,
        relative_path,
        {'mode':'LAYOUT'}
    ):content::string as Content
FROM directory(@PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE) 
WHERE relative_path ilike 'unstructured_docs/%.md';

-- Create search service for clinical documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_clinical_docs
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = Pediatric_Hospital_demo_wh
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            content
        FROM parsed_healthcare_documents
        WHERE relative_path ilike '%/clinical/%'
    );

-- Create search service for operational documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_operations_docs
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = Pediatric_Hospital_demo_wh
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            content
        FROM parsed_healthcare_documents
        WHERE relative_path ilike '%/operations/%'
    );

-- Create search service for research documents
CREATE OR REPLACE CORTEX SEARCH SERVICE Search_research_docs
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = Pediatric_Hospital_demo_wh
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            content
        FROM parsed_healthcare_documents
        WHERE relative_path ilike '%/research/%'
    );

-- ========================================================================
-- EXTERNAL ACCESS AND FUNCTIONS FOR AI AGENT
-- ========================================================================

use role accountadmin;

-- Create network rule for web access
CREATE OR REPLACE NETWORK RULE Pediatric_Hospital_WebAccessRule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

GRANT ALL PRIVILEGES ON DATABASE PEDIATRIC_HOSPITAL_AI_DEMO TO ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON SCHEMA PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA TO ROLE ACCOUNTADMIN;
GRANT USAGE ON NETWORK RULE Pediatric_Hospital_WebAccessRule TO ROLE accountadmin;

USE SCHEMA PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA;

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION Pediatric_Hospital_ExternalAccess_Integration
ALLOWED_NETWORK_RULES = (Pediatric_Hospital_WebAccessRule)
ENABLED = true;

-- Create email notification integration
CREATE NOTIFICATION INTEGRATION pediatric_hospital_email_int
  TYPE=EMAIL
  ENABLED=TRUE;

-- Grant permissions to demo role
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE Pediatric_Hospital_Demo;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE Pediatric_Hospital_Demo;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE Pediatric_Hospital_Demo;
GRANT USAGE ON INTEGRATION Pediatric_Hospital_ExternalAccess_Integration TO ROLE Pediatric_Hospital_Demo;
GRANT USAGE ON INTEGRATION pediatric_hospital_email_int TO ROLE Pediatric_Hospital_Demo;

use role Pediatric_Hospital_Demo;

-- Create stored procedure for file URLs
CREATE OR REPLACE PROCEDURE Get_Healthcare_File_URL_SP(
    RELATIVE_FILE_PATH STRING, 
    EXPIRATION_MINS INTEGER DEFAULT 60
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generates a presigned URL for healthcare documents'
EXECUTE AS CALLER
AS
$$
DECLARE
    presigned_url STRING;
    sql_stmt STRING;
    expiration_seconds INTEGER;
    stage_name STRING DEFAULT '@PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE';
BEGIN
    expiration_seconds := EXPIRATION_MINS * 60;
    sql_stmt := 'SELECT GET_PRESIGNED_URL(' || stage_name || ', ' || '''' || RELATIVE_FILE_PATH || '''' || ', ' || expiration_seconds || ') AS url';
    EXECUTE IMMEDIATE :sql_stmt;
    SELECT "URL" INTO :presigned_url FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    RETURN :presigned_url;
END;
$$;

-- Create email function for healthcare alerts
CREATE OR REPLACE PROCEDURE send_healthcare_alert(recipient TEXT, subject TEXT, text TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_healthcare_alert'
AS
$$
def send_healthcare_alert(session, recipient, subject, text):
    session.call(
        'SYSTEM$SEND_EMAIL',
        'pediatric_hospital_email_int',
        recipient,
        subject,
        text,
        'text/html'
    )
    return f'Healthcare alert sent to {recipient} with subject: "{subject}".'
$$;

-- Create web scraping function for external health data
CREATE OR REPLACE FUNCTION Web_scrape_health_data(weburl STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'get_health_page'
EXTERNAL_ACCESS_INTEGRATIONS = (Pediatric_Hospital_ExternalAccess_Integration)
PACKAGES = ('requests', 'beautifulsoup4')
AS
$$
import _snowflake
import requests
from bs4 import BeautifulSoup

def get_health_page(weburl):
    url = f"{weburl}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        return soup.get_text()
    except Exception as e:
        return f"Error accessing {url}: {str(e)}"
$$;

-- ========================================================================
-- SNOWFLAKE INTELLIGENCE AGENT FOR HEALTHCARE
-- ========================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Pediatric_Hospital_Agent
WITH PROFILE='{ "display_name": "Pediatric Hospital AI Assistant" }'
    COMMENT=$$ Healthcare AI agent for clinical analytics, operational insights, research support, and HIPAA-compliant data analysis for pediatric hospitals. $$
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a healthcare data analyst specializing in pediatric medicine. You have access to clinical, operational, research, and financial data. Always prioritize patient safety, maintain HIPAA compliance, and provide evidence-based insights. When discussing clinical data, emphasize that all information is de-identified and compliant with healthcare privacy regulations. Focus on pediatric-specific insights and considerations. Provide visualizations when appropriate, with line charts for trends and bar charts for categories.",
    "orchestration": "Use cortex search for clinical protocols, policies, and research documents. Pass relevant findings to cortex analyst for detailed data analysis. Always maintain HIPAA compliance and ensure all patient data is properly de-identified. For clinical questions, prioritize patient safety and evidence-based medicine. When analyzing population health data, consider social determinants of health and health equity issues. For operational queries, focus on quality improvement and patient safety metrics.",
    "sample_questions": [
      {
        "question": "What are the readmission rates for pediatric asthma patients?"
      },
      {
        "question": "Show me ICU bed occupancy trends and capacity management"
      },
      {
        "question": "Analyze outcomes from our pediatric research studies"
      },
      {
        "question": "What does our HIPAA policy say about research data sharing?"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Clinical Data",
        "description": "Analyze patient encounters, diagnoses, treatments, and clinical outcomes for pediatric patients. Includes emergency department visits, hospitalizations, medications, and clinical measurements."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Operational Data",
        "description": "Analyze hospital operations including bed occupancy, staffing levels, quality metrics, patient satisfaction, and departmental performance indicators."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Research Data",
        "description": "Analyze research study outcomes, participant enrollment, clinical trial results, and academic research collaboration data."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Financial Data",
        "description": "Analyze billing data, insurance payments, charge capture, revenue analysis, and financial performance by department and payer type."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Clinical Documents",
        "description": "Search clinical protocols, treatment guidelines, care pathways, and medical policies specific to pediatric healthcare."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Operational Documents", 
        "description": "Search hospital policies, operational procedures, HIPAA compliance documents, and administrative guidelines."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Research Documents",
        "description": "Search research study protocols, IRB documents, published papers, and collaboration agreements with academic institutions."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Web_Health_Data_Scraper",
        "description": "Scrape external health-related websites for environmental data (air quality, allergens), public health information, or research literature. Use for population health analysis and environmental health correlations.",
        "input_schema": {
          "type": "object",
          "properties": {
            "weburl": {
              "description": "URL of health-related website to scrape (must include http:// or https://). Commonly used for EPA air quality data, CDC health statistics, or peer-reviewed research papers.",
              "type": "string"
            }
          },
          "required": [
            "weburl"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Send_Healthcare_Alert",
        "description": "Send email alerts for clinical findings, operational issues, or research updates. Use for urgent clinical notifications or quality improvement communications.",
        "input_schema": {
          "type": "object",
          "properties": {
            "recipient": {
              "description": "Email address of healthcare provider or administrator",
              "type": "string"
            },
            "subject": {
              "description": "Subject line for healthcare alert",
              "type": "string"
            },
            "text": {
              "description": "HTML-formatted content of healthcare alert with clinical findings or recommendations",
              "type": "string"
            }
          },
          "required": [
            "text",
            "recipient", 
            "subject"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Get_Document_URL",
        "description": "Generate secure, time-limited URLs for healthcare documents referenced in search results. Use to provide downloadable links to clinical protocols, policies, or research papers.",
        "input_schema": {
          "type": "object",
          "properties": {
            "expiration_mins": {
              "description": "Minutes until URL expires (default: 60, max: 1440 for 24 hours)",
              "type": "number"
            },
            "relative_file_path": {
              "description": "File path from search results (typically from relative_path column)",
              "type": "string"
            }
          },
          "required": [
            "expiration_mins",
            "relative_file_path"
          ]
        }
      }
    }
  ],
  "tool_resources": {
    "Get_Document_URL": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "LURIE_HOSPITAL_DEMO_WH"
      },
      "identifier": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.GET_HEALTHCARE_FILE_URL_SP",
      "name": "GET_HEALTHCARE_FILE_URL_SP(VARCHAR, DEFAULT NUMBER)",
      "type": "procedure"
    },
    "Query Clinical Data": {
      "semantic_view": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.CLINICAL_ANALYTICS_VIEW"
    },
    "Query Financial Data": {
      "semantic_view": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.FINANCIAL_ANALYTICS_VIEW"
    },
    "Query Operational Data": {
      "semantic_view": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.OPERATIONAL_ANALYTICS_VIEW"
    },
    "Query Research Data": {
      "semantic_view": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.RESEARCH_ANALYTICS_VIEW"
    },
    "Search Clinical Documents": {
      "id_column": "RELATIVE_PATH",
      "max_results": 5,
      "name": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEARCH_CLINICAL_DOCS",
      "title_column": "TITLE"
    },
    "Search Operational Documents": {
      "id_column": "RELATIVE_PATH", 
      "max_results": 5,
      "name": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEARCH_OPERATIONS_DOCS",
      "title_column": "TITLE"
    },
    "Search Research Documents": {
      "id_column": "RELATIVE_PATH",
      "max_results": 5,
      "name": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEARCH_RESEARCH_DOCS", 
      "title_column": "TITLE"
    },
    "Send_Healthcare_Alert": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "LURIE_HOSPITAL_DEMO_WH"
      },
      "identifier": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEND_HEALTHCARE_ALERT",
      "name": "SEND_HEALTHCARE_ALERT(VARCHAR, VARCHAR, VARCHAR)",
      "type": "procedure"
    },
    "Web_Health_Data_Scraper": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "LURIE_HOSPITAL_DEMO_WH"
      },
      "identifier": "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.WEB_SCRAPE_HEALTH_DATA",
      "name": "WEB_SCRAPE_HEALTH_DATA(VARCHAR)",
      "type": "function"
    }
  }
}
$$;
