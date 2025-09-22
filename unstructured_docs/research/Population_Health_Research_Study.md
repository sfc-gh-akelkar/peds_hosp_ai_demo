# Population Health Research Study
**Pediatric Asthma Outcomes in Urban Communities**

**Principal Investigator**: Dr. Sarah Johnson, MD, MPH  
**Co-Investigators**: Dr. Michael Chen, MD, Dr. Lisa Rodriguez, PhD  
**Study ID**: LCH-2025-001  
**IRB Approval**: #2024-089  
**Funding**: NIH Grant R01-HL987654

## Study Overview

### Background and Significance

Asthma affects approximately 6.2 million children in the United States, with higher prevalence rates in urban, low-income communities. Children from racial and ethnic minority backgrounds experience disproportionately higher rates of asthma-related emergency department visits, hospitalizations, and mortality. Understanding the complex interplay of environmental, social, and clinical factors affecting pediatric asthma outcomes is crucial for developing targeted interventions.

Lurie Children's Hospital serves a diverse urban population with significant disparities in asthma outcomes. Our hospital data shows:
- 25% higher ED visit rates for asthma in zip codes with <100% federal poverty level
- 40% increased readmission rates among non-English speaking families
- Seasonal variations correlating with air quality indices and housing conditions

### Study Objectives

**Primary Objective**: To identify clinical, environmental, and social determinants of pediatric asthma exacerbations leading to emergency department visits and hospitalizations in urban children.

**Secondary Objectives**:
1. Develop a predictive model for asthma exacerbations using clinical and environmental data
2. Assess the impact of social determinants of health on treatment adherence and outcomes
3. Evaluate the effectiveness of community-based interventions on asthma control
4. Identify genetic biomarkers associated with severe asthma phenotypes in diverse populations

## Methods

### Study Design
Prospective cohort study with retrospective analysis of existing clinical data

### Study Population

**Inclusion Criteria**:
- Children ages 2-17 years
- Physician-confirmed asthma diagnosis (ICD-10 J45.x)
- At least one healthcare encounter at Lurie Children's Hospital in past 12 months
- Primary residence in Chicago metropolitan area
- Parent/guardian willing to provide informed consent

**Exclusion Criteria**:
- Concurrent enrollment in conflicting research studies
- Presence of other significant respiratory conditions (cystic fibrosis, bronchopulmonary dysplasia)
- Inability to complete study procedures due to developmental delays
- Plans to relocate outside study area within 24 months

**Target Enrollment**: 2,500 patients over 36 months

### Data Collection

**Clinical Data (from Snowflake Clinical Data Warehouse)**:
- Electronic health record data including demographics, diagnoses, procedures
- Emergency department visits and hospitalizations
- Medication prescriptions and administration records
- Laboratory results and pulmonary function tests
- Growth parameters and vital signs

**Environmental Data**:
- Air quality indices from EPA monitoring stations
- Allergen levels (pollen, mold) from local monitoring
- Housing quality assessments through partnership with Chicago Department of Public Health
- School environmental data (indoor air quality, presence of triggers)

**Social Determinants Data**:
- Household income and insurance status
- Educational attainment of primary caregivers
- Food security screening results
- Transportation access and healthcare utilization barriers
- Language preferences and health literacy assessments

**Biospecimen Collection**:
- Saliva samples for genetic analysis (subset of 500 patients)
- Nasal swabs for microbiome analysis
- Exhaled nitric oxide measurements

### Snowflake Data Architecture

**Data Sources Integration**:
```sql
-- Clinical data from Epic EHR
CREATE TABLE clinical_encounters AS
SELECT 
    patient_mrn,
    encounter_date,
    diagnosis_codes,
    procedure_codes,
    medications_prescribed,
    vital_signs,
    lab_results
FROM epic_data_warehouse
WHERE diagnosis_codes LIKE 'J45%'

-- Environmental data from external APIs
CREATE TABLE environmental_measures AS
SELECT 
    measurement_date,
    zip_code,
    air_quality_index,
    pm25_level,
    ozone_level,
    pollen_count,
    weather_conditions
FROM environmental_data_feeds

-- Social determinants from screening tools
CREATE TABLE social_determinants AS
SELECT 
    patient_mrn,
    screening_date,
    household_income_category,
    insurance_type,
    food_security_score,
    transportation_access,
    housing_quality_index
FROM patient_screening_data
```

**Data De-identification Process**:
- Patient names replaced with study IDs using consistent tokenization
- Dates shifted by random offset (-90 to +90 days) while preserving temporal relationships
- Geocoding generalized to census tract level
- Direct identifiers removed or generalized per HIPAA Safe Harbor method

**Research Database Structure**:
```sql
-- Main cohort table
CREATE TABLE study_cohort AS
SELECT 
    study_id,
    age_at_enrollment,
    gender,
    race_ethnicity,
    primary_language,
    insurance_type,
    zip_code_census_tract,
    asthma_severity_category,
    comorbid_conditions
FROM patient_dim p
JOIN study_enrollment e ON p.patient_key = e.patient_key

-- Outcomes table
CREATE TABLE asthma_outcomes AS
SELECT 
    study_id,
    outcome_date,
    outcome_type, -- ED visit, hospitalization, urgent care
    severity_score,
    length_of_stay,
    treatment_received,
    discharge_disposition
FROM patient_encounter_fact
WHERE diagnosis_primary LIKE 'J45%'
```

## Statistical Analysis Plan

### Descriptive Analysis
- Patient characteristics summarized by demographic and clinical variables
- Asthma exacerbation rates calculated per patient-year of follow-up
- Geographic mapping of asthma outcomes by census tract
- Seasonal patterns analysis using time series methods

### Predictive Modeling
```sql
-- Feature engineering for ML model
CREATE TABLE model_features AS
SELECT 
    c.study_id,
    c.age_at_enrollment,
    c.gender,
    c.race_ethnicity,
    COUNT(e.encounter_key) as prior_ed_visits,
    AVG(cm.fev1_percent_predicted) as avg_lung_function,
    MAX(env.air_quality_index) as max_aqi_exposure,
    sd.food_security_score,
    sd.housing_quality_index
FROM study_cohort c
LEFT JOIN patient_encounter_fact e ON c.study_id = e.study_id
LEFT JOIN clinical_measures_fact cm ON c.study_id = cm.study_id
LEFT JOIN environmental_measures env ON c.zip_code = env.zip_code
LEFT JOIN social_determinants sd ON c.study_id = sd.study_id
GROUP BY c.study_id, [other grouping columns]
```

**Machine Learning Approach**:
- Random Forest model for exacerbation prediction
- Logistic regression for interpretable risk factors
- Gradient boosting for time-to-event analysis
- Cross-validation with temporal splitting to prevent data leakage

### Subgroup Analyses
- Stratified analyses by age groups (2-5, 6-11, 12-17 years)
- Race/ethnicity-specific analyses to identify disparities
- Socioeconomic status stratification (Medicaid vs. private insurance)
- Seasonal variation analyses by environmental exposure levels

## Preliminary Results

### Cohort Characteristics (N = 1,247 enrolled to date)
- Mean age: 8.3 years (SD 4.2)
- Gender: 55% male, 45% female
- Race/ethnicity: 42% Hispanic/Latino, 35% Black/African American, 15% White, 8% Other
- Insurance: 68% Medicaid, 28% Private, 4% Self-pay
- Primary language: 58% English, 35% Spanish, 7% Other

### Asthma Outcomes (12-month follow-up)
- ED visit rate: 0.82 visits per patient-year
- Hospitalization rate: 0.15 admissions per patient-year
- Median length of stay: 2.1 days (IQR 1.3-3.4)
- 30-day readmission rate: 8.2%

### Environmental Associations
- Air Quality Index >100 associated with 23% increase in ED visits (p<0.001)
- High pollen days (>100 grains/m³) correlated with 15% increase in rescue inhaler use
- Housing quality score <50 associated with 2.1x higher hospitalization risk

### Social Determinants Impact
- Food insecurity present in 34% of families
- Transportation barriers reported by 28% of caregivers
- Limited English proficiency associated with 1.8x higher no-show rates for follow-up visits

## Clinical Decision Support Development

### Real-time Risk Stratification
```sql
-- Risk score calculation for clinical use
CREATE FUNCTION calculate_asthma_risk_score(
    patient_id STRING,
    current_date DATE
) 
RETURNS FLOAT
AS
$$
WITH patient_features AS (
    SELECT 
        p.age,
        p.gender,
        p.race_ethnicity,
        COUNT(e.encounter_key) as ed_visits_last_year,
        AVG(cm.peak_flow_percent) as avg_peak_flow,
        MAX(env.air_quality_index) as current_aqi,
        sd.housing_quality_index
    FROM patient_dim p
    LEFT JOIN patient_encounter_fact e 
        ON p.patient_key = e.patient_key 
        AND e.encounter_date >= DATEADD(year, -1, current_date)
    LEFT JOIN clinical_measures_fact cm 
        ON p.patient_key = cm.patient_key
        AND cm.measure_date >= DATEADD(month, -3, current_date)
    LEFT JOIN environmental_measures env 
        ON p.zip_code = env.zip_code 
        AND env.measurement_date = current_date
    LEFT JOIN social_determinants sd 
        ON p.patient_key = sd.patient_key
    WHERE p.patient_id = patient_id
),
risk_calculation AS (
    SELECT 
        CASE 
            WHEN ed_visits_last_year >= 3 THEN 3.2
            WHEN ed_visits_last_year = 2 THEN 2.1
            WHEN ed_visits_last_year = 1 THEN 1.5
            ELSE 1.0
        END +
        CASE 
            WHEN avg_peak_flow < 60 THEN 2.5
            WHEN avg_peak_flow < 80 THEN 1.2
            ELSE 0.0
        END +
        CASE 
            WHEN current_aqi > 100 THEN 1.8
            WHEN current_aqi > 75 THEN 0.8
            ELSE 0.0
        END +
        CASE 
            WHEN housing_quality_index < 50 THEN 1.5
            ELSE 0.0
        END as risk_score
    FROM patient_features
)
SELECT risk_score FROM risk_calculation
$$;
```

### Predictive Alerts
- High-risk patient identification for proactive outreach
- Environmental trigger alerts during high pollution days
- Medication adherence monitoring through pharmacy data
- Automatic care team notifications for patients exceeding risk thresholds

## Community Health Initiatives

### Targeted Interventions Based on Findings
1. **Air Quality Alert System**: Text messaging to high-risk families during poor air quality days
2. **Community Health Worker Program**: Enhanced support for families with housing quality issues
3. **School-Based Interventions**: Asthma education and trigger reduction in high-prevalence schools
4. **Pharmacy Partnership**: Improved medication access and adherence monitoring

### Policy Implications
- Data shared with Chicago Department of Public Health for environmental health planning
- Evidence provided to support housing quality improvement initiatives
- School district partnerships for indoor air quality improvements
- Healthcare payment model development for value-based asthma care

## Data Sharing and Collaboration

### Northwestern University Partnership
- Shared research database for genetic analysis
- Combined population health initiatives
- Joint grant applications and publications
- Resident and fellow research training programs

### External Collaborations
- Chicago Department of Public Health: Environmental health data
- Chicago Public Schools: School-based intervention programs
- University of Illinois Chicago: Health disparities research
- Children's Hospital Association: Multi-site outcomes research

### Data Sharing Framework
```sql
-- Secure data sharing view for collaborators
CREATE SECURE VIEW external_research_data AS
SELECT 
    study_id,
    age_group, -- Generalized from exact age
    gender,
    race_ethnicity,
    census_tract, -- No exact address
    asthma_severity_category,
    outcome_measures,
    environmental_exposures,
    social_determinant_scores
FROM study_cohort c
JOIN outcomes_summary o ON c.study_id = o.study_id
WHERE data_sharing_consent = 'Yes'
AND enrollment_date >= '2024-01-01';
```

## Quality Assurance

### Data Quality Monitoring
- Real-time data validation rules in Snowflake
- Monthly data quality reports reviewing completeness and accuracy
- Automated alerts for unusual data patterns or missing critical variables
- Regular reconciliation with source systems (Epic, environmental databases)

### Research Integrity
- IRB continuing review every 12 months
- Data Safety Monitoring Board quarterly reviews
- Independent statistical analysis verification
- Publication and presentation compliance with institutional policies

## Future Directions

### Planned Analyses
1. **Genomic Associations**: Genome-wide association study for severe asthma phenotypes
2. **Microbiome Analysis**: Nasal microbiome patterns and asthma control
3. **Intervention Effectiveness**: Community-based intervention impact assessment
4. **Healthcare Utilization**: Cost-effectiveness analysis of predictive modeling

### Technology Enhancements
- Real-time streaming data integration for wearable devices
- Machine learning model deployment in clinical workflows
- Mobile app development for patient-reported outcomes
- Artificial intelligence-driven care recommendations

### Policy Research
- Health insurance coverage impact on outcomes
- Transportation policy effects on healthcare access
- Environmental justice considerations in asthma care
- Social policy interventions and health outcomes

## Dissemination Plan

### Publications
1. Primary outcomes manuscript (target: New England Journal of Medicine)
2. Environmental health findings (Environmental Health Perspectives)
3. Health disparities analysis (Health Affairs)
4. Predictive modeling methodology (Journal of Medical Internet Research)

### Conference Presentations
- American Thoracic Society International Conference
- Pediatric Academic Societies Annual Meeting
- American Public Health Association Annual Meeting
- International Society for Environmental Epidemiology

### Community Engagement
- Results presentation to Community Advisory Board
- Policy briefings for local government officials
- Media outreach for public health messaging
- Educational materials for families and schools

## Study Team

**Principal Investigator**: Dr. Sarah Johnson, MD, MPH  
Division of Pulmonology, Lurie Children's Hospital  
Professor of Pediatrics, Northwestern University Feinberg School of Medicine

**Co-Investigators**:
- Dr. Michael Chen, MD: Clinical outcomes and care quality
- Dr. Lisa Rodriguez, PhD: Environmental health and epidemiology
- Dr. James Wilson, PhD: Biostatistics and data science
- Dr. Maria Gonzalez, MD: Health disparities and community health

**Research Coordinators**:
- Jennifer Smith, RN, MSN: Clinical data coordination
- Carlos Martinez, MPH: Community engagement and recruitment
- Rebecca Johnson, PhD: Data management and analysis

**Community Advisory Board**:
- Parent representatives from participant families
- Community health organization leaders
- School district health coordinators
- Environmental justice advocates

## Contact Information

**Study Coordinator**: Jennifer Smith, RN, MSN  
Email: jsmith@luriechildrens.org  
Phone: (312) 227-4567

**Principal Investigator**: Dr. Sarah Johnson, MD, MPH  
Email: sjohnson@luriechildrens.org  
Phone: (312) 227-4500

**Data Questions**: Rebecca Johnson, PhD  
Email: rjohnson@luriechildrens.org  
Phone: (312) 227-4580

**Last Updated**: January 15, 2025  
**Version**: 2.1
