-- ========================================================================
-- Healthcare Demo - Step 1: Data Infrastructure Setup
-- Creates database, schema, tables, and loads healthcare data
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Enable Snowflake Intelligence by creating the Config DB & Schema
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

-- Reuse existing SF_INTELLIGENCE_DEMO role instead of creating new role
-- Note: Assumes SF_INTELLIGENCE_DEMO role already exists and user has access

SET current_user_name = CURRENT_USER();

-- Grant additional permissions to existing role for healthcare demo
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SF_INTELLIGENCE_DEMO;

-- Create a dedicated warehouse for the healthcare demo
CREATE OR REPLACE WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse
GRANT USAGE ON WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH TO ROLE SF_INTELLIGENCE_DEMO;

-- Set default warehouse (keeping existing role)
-- ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = SF_INTELLIGENCE_DEMO;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH;

-- Switch to existing demo role
USE ROLE SF_INTELLIGENCE_DEMO;

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

USE ROLE SF_INTELLIGENCE_DEMO;

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
-- VERIFICATION
-- ========================================================================

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
-- COMPLETION MESSAGE
-- ========================================================================

SELECT '✅ Step 1 Complete: Healthcare data infrastructure created successfully!' as status;
SELECT 'Next: Run 02_cortex_search_setup.sql' as next_step;
