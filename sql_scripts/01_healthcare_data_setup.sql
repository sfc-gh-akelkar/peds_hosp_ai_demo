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

-- Insert sample patients
INSERT INTO patient_dim VALUES
(1, 'MRN001234', 'Emma', 'Johnson', '2015-03-15', 'F', 'White', 'English', 'Private Insurance', '60601', TRUE),
(2, 'MRN001235', 'Noah', 'Williams', '2018-07-22', 'M', 'Hispanic', 'Spanish', 'Medicaid', '60602', TRUE),
(3, 'MRN001236', 'Olivia', 'Brown', '2012-11-08', 'F', 'African American', 'English', 'Private Insurance', '60603', TRUE),
(4, 'MRN001237', 'Liam', 'Davis', '2019-01-30', 'M', 'White', 'English', 'Medicaid', '60604', TRUE),
(5, 'MRN001238', 'Sophia', 'Garcia', '2016-09-12', 'F', 'Hispanic', 'Spanish', 'Private Insurance', '60605', TRUE),
(6, 'MRN001239', 'Jackson', 'Martinez', '2014-05-25', 'M', 'Hispanic', 'English', 'Medicaid', '60606', TRUE),
(7, 'MRN001240', 'Ava', 'Anderson', '2017-12-03', 'F', 'White', 'English', 'Private Insurance', '60607', TRUE),
(8, 'MRN001241', 'Lucas', 'Taylor', '2013-08-17', 'M', 'African American', 'English', 'Medicaid', '60608', TRUE),
(9, 'MRN001242', 'Mia', 'Thomas', '2020-02-14', 'F', 'Asian', 'English', 'Private Insurance', '60609', TRUE),
(10, 'MRN001243', 'Ethan', 'Jackson', '2011-10-05', 'M', 'White', 'English', 'Medicaid', '60610', TRUE);

-- Insert sample providers
INSERT INTO provider_dim VALUES
(1, 'PROV001', 'Dr. Sarah Johnson', 'Physician', 'Pediatric Critical Care', 1, '2018-06-15', TRUE),
(2, 'PROV002', 'Dr. Michael Chen', 'Physician', 'Pediatric Emergency Medicine', 3, '2019-03-20', TRUE),
(3, 'PROV003', 'Dr. Lisa Rodriguez', 'Physician', 'Pediatric Cardiology', 4, '2017-09-10', TRUE),
(4, 'PROV004', 'Dr. James Wilson', 'Physician', 'Pediatric Oncology', 5, '2016-01-25', TRUE),
(5, 'PROV005', 'Dr. Amanda Davis', 'Physician', 'General Pediatrics', 6, '2020-07-08', TRUE),
(6, 'PROV006', 'Dr. Robert Kim', 'Physician', 'Pediatric Surgery', 7, '2015-11-12', TRUE),
(7, 'PROV007', 'Nurse Jennifer Smith', 'Nurse Practitioner', 'Pediatric ICU', 1, '2019-02-28', TRUE),
(8, 'PROV008', 'Dr. Maria Gonzalez', 'Physician', 'Neonatology', 2, '2018-05-17', TRUE),
(9, 'PROV009', 'Dr. David Thompson', 'Physician', 'Pediatric Neurology', 6, '2017-08-22', TRUE),
(10, 'PROV010', 'Dr. Rachel Lee', 'Physician', 'Pediatric Endocrinology', 6, '2019-10-30', TRUE);

-- Insert sample patient encounters (including PICU stays) - Current quarter data
INSERT INTO patient_encounter_fact VALUES
(1, 'ENC001', 1, 1, 1, '2024-07-15', 'Inpatient', '2024-07-15', '2024-07-20', 5, 15000.00, 1, FALSE),
(2, 'ENC002', 2, 2, 3, '2024-07-18', 'Emergency', '2024-07-18', '2024-07-18', 0, 2500.00, 6, FALSE),
(3, 'ENC003', 3, 3, 4, '2024-07-20', 'Outpatient', '2024-07-20', '2024-07-20', 0, 800.00, 5, FALSE),
(4, 'ENC004', 4, 1, 1, '2024-07-22', 'Inpatient', '2024-07-22', '2024-07-28', 6, 18000.00, 2, FALSE),
(5, 'ENC005', 5, 4, 5, '2024-07-25', 'Inpatient', '2024-07-25', '2024-08-08', 14, 45000.00, 7, FALSE),
(6, 'ENC006', 6, 5, 6, '2024-07-28', 'Outpatient', '2024-07-28', '2024-07-28', 0, 350.00, 1, FALSE),
(7, 'ENC007', 7, 1, 1, '2024-08-01', 'Inpatient', '2024-08-01', '2024-08-04', 3, 12000.00, 1, FALSE),
(8, 'ENC008', 8, 6, 7, '2024-08-03', 'Inpatient', '2024-08-03', '2024-08-05', 2, 25000.00, 5, FALSE),
(9, 'ENC009', 9, 8, 2, '2024-08-05', 'Inpatient', '2024-08-05', '2024-08-25', 20, 55000.00, 8, FALSE),
(10, 'ENC010', 10, 9, 6, '2024-08-08', 'Outpatient', '2024-08-08', '2024-08-08', 0, 450.00, 4, FALSE),
(11, 'ENC011', 1, 1, 1, '2024-08-15', 'Inpatient', '2024-08-15', '2024-08-19', 4, 14500.00, 1, TRUE),
(12, 'ENC012', 3, 2, 3, '2024-08-18', 'Emergency', '2024-08-18', '2024-08-19', 1, 3200.00, 6, FALSE),
(13, 'ENC013', 5, 1, 1, '2024-08-20', 'Inpatient', '2024-08-20', '2024-08-27', 7, 19500.00, 7, FALSE),
(14, 'ENC014', 7, 4, 5, '2024-08-22', 'Inpatient', '2024-08-22', '2024-09-10', 16, 48000.00, 7, FALSE),
(15, 'ENC015', 2, 2, 3, '2024-09-05', 'Emergency', '2024-09-05', '2024-09-05', 0, 1800.00, 6, FALSE);

-- Insert sample clinical measures
INSERT INTO clinical_measures_fact VALUES
(1, 1, 1, 1, '2024-07-15 08:00:00', 'Vital Signs', 'Heart Rate', 95.0, 'bpm', 80.0, 120.0, FALSE),
(2, 1, 1, 1, '2024-07-15 08:00:00', 'Vital Signs', 'Temperature', 98.6, 'F', 97.0, 99.5, FALSE),
(3, 2, 2, 2, '2024-07-18 14:30:00', 'Lab Results', 'White Blood Count', 12500.0, 'cells/uL', 4000.0, 11000.0, TRUE),
(4, 3, 3, 3, '2024-07-20 10:15:00', 'Vital Signs', 'Blood Pressure Systolic', 110.0, 'mmHg', 90.0, 120.0, FALSE),
(5, 4, 4, 1, '2024-07-22 06:45:00', 'Vital Signs', 'Oxygen Saturation', 92.0, '%', 95.0, 100.0, TRUE),
(6, 5, 5, 4, '2024-07-25 12:20:00', 'Lab Results', 'Hemoglobin', 8.2, 'g/dL', 11.0, 16.0, TRUE),
(7, 6, 6, 5, '2024-07-28 09:30:00', 'Vital Signs', 'Heart Rate', 88.0, 'bpm', 70.0, 110.0, FALSE),
(8, 7, 7, 1, '2024-08-01 16:45:00', 'Vital Signs', 'Temperature', 101.2, 'F', 97.0, 99.5, TRUE),
(9, 8, 8, 6, '2024-08-03 11:00:00', 'Lab Results', 'Glucose', 180.0, 'mg/dL', 70.0, 140.0, TRUE),
(10, 9, 9, 8, '2024-08-05 07:15:00', 'Vital Signs', 'Respiratory Rate', 28.0, 'breaths/min', 12.0, 25.0, TRUE);

-- Insert sample medication administration
INSERT INTO medication_fact VALUES
(1, 1, 1, 1, 1, '2024-07-15 10:00:00', 2.5, 'mg', 'Inhalation', 'Every 4 hours'),
(2, 2, 2, 3, 2, '2024-07-18 15:00:00', 150.0, 'mg', 'Oral', 'Twice daily'),
(3, 4, 4, 1, 1, '2024-07-22 08:00:00', 2.5, 'mg', 'Inhalation', 'Every 6 hours'),
(4, 5, 5, 5, 4, '2024-07-25 14:30:00', 1.5, 'mg/m2', 'IV', 'Weekly'),
(5, 7, 7, 1, 1, '2024-08-01 18:00:00', 2.5, 'mg', 'Inhalation', 'Every 4 hours'),
(6, 8, 8, 9, 6, '2024-08-03 12:00:00', 0.125, 'mg', 'Oral', 'Daily'),
(7, 9, 9, 10, 8, '2024-08-05 09:00:00', 1.0, 'g', 'IV', 'Twice daily'),
(8, 1, 11, 8, 1, '2024-08-15 11:30:00', 160.0, 'mg', 'Oral', 'Every 6 hours'),
(9, 5, 13, 5, 1, '2024-08-20 16:45:00', 2.5, 'mg', 'Inhalation', 'Every 4 hours'),
(10, 7, 14, 5, 4, '2024-08-22 13:20:00', 1.5, 'mg/m2', 'IV', 'Weekly');

-- Insert sample financial transactions
INSERT INTO financial_fact VALUES
(1, 1, 1, 2, 1, '2024-07-20', '2024-07-15', 15000.00, 12000.00, 500.00, 'Charge'),
(2, 2, 2, 1, 3, '2024-07-18', '2024-07-18', 2500.00, 2000.00, 100.00, 'Charge'),
(3, 3, 3, 2, 4, '2024-07-20', '2024-07-20', 800.00, 640.00, 40.00, 'Charge'),
(4, 4, 4, 1, 1, '2024-07-28', '2024-07-22', 18000.00, 14400.00, 600.00, 'Charge'),
(5, 5, 5, 5, 5, '2024-08-08', '2024-07-25', 45000.00, 36000.00, 1500.00, 'Charge'),
(6, 6, 6, 2, 6, '2024-07-28', '2024-07-28', 350.00, 280.00, 20.00, 'Charge'),
(7, 7, 7, 2, 1, '2024-08-04', '2024-08-01', 12000.00, 9600.00, 400.00, 'Charge'),
(8, 8, 8, 5, 7, '2024-08-05', '2024-08-03', 25000.00, 20000.00, 800.00, 'Charge'),
(9, 9, 9, 1, 2, '2024-08-25', '2024-08-05', 55000.00, 44000.00, 2000.00, 'Charge'),
(10, 10, 10, 2, 6, '2024-08-08', '2024-08-08', 450.00, 360.00, 25.00, 'Charge');

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
