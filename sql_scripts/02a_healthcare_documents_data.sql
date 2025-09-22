-- ========================================================================
-- Healthcare Documents Data - Sample Content for Cortex Search
-- Insert healthcare document content directly into tables for simplified demo
-- ========================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;
USE SCHEMA CLINICAL_SCHEMA;
USE WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH;

-- Insert sample clinical documents
INSERT INTO healthcare_documents VALUES
('CLINICAL_001', 'unstructured_docs/clinical/Pediatric_Asthma_Care_Protocol.md', 'Pediatric Asthma Care Protocol', 'clinical',
'# Pediatric Asthma Care Protocol

## Overview
This protocol provides evidence-based guidelines for the diagnosis, treatment, and management of asthma in pediatric patients aged 0-18 years.

## Clinical Assessment

### Initial Evaluation
- **History**: Review symptoms, triggers, family history, and previous treatments
- **Physical Examination**: Focus on respiratory system, growth parameters, and allergic signs
- **Diagnostic Tests**: Spirometry (age ≥6), peak flow measurements, allergy testing

### Severity Classification
- **Intermittent**: Symptoms ≤2 days/week, nighttime awakening ≤2x/month
- **Mild Persistent**: Symptoms >2 days/week but not daily
- **Moderate Persistent**: Daily symptoms, nighttime awakening >1x/week
- **Severe Persistent**: Throughout the day symptoms, frequent nighttime awakening

## Treatment Guidelines

### Step-Care Approach
1. **Step 1**: Short-acting bronchodilator as needed
2. **Step 2**: Low-dose inhaled corticosteroid + SABA PRN
3. **Step 3**: Medium-dose ICS or low-dose ICS + LABA
4. **Step 4**: Medium-dose ICS + LABA
5. **Step 5**: High-dose ICS + LABA + oral corticosteroid

### Emergency Management
- **Mild Exacerbation**: Increase bronchodilator frequency, continue controller therapy
- **Moderate Exacerbation**: Oral prednisolone, frequent bronchodilators
- **Severe Exacerbation**: Immediate medical attention, IV corticosteroids, oxygen

## Patient Education
- Proper inhaler technique demonstration
- Asthma action plan development
- Trigger identification and avoidance
- When to seek emergency care

## Follow-up Schedule
- Initial diagnosis: 2-6 weeks
- Stable patients: Every 3-6 months
- Poor control: Every 2-6 weeks
- Emergency visits: 1-3 days post-discharge

## Quality Metrics
- Asthma control assessment
- Emergency department visits
- Hospitalization rates
- Medication adherence
- Patient/family satisfaction', CURRENT_TIMESTAMP()),

('CLINICAL_002', 'unstructured_docs/clinical/Emergency_Treatment_Guidelines.md', 'Emergency Treatment Guidelines', 'clinical',
'# Emergency Department Pediatric Treatment Guidelines

## Triage Protocols

### Pediatric Early Warning System (PEWS)
- Respiratory: Rate, effort, oxygen saturation
- Cardiovascular: Heart rate, blood pressure, perfusion
- Neurological: Consciousness level, response to stimuli

### Priority Categories
- **Level 1**: Life-threatening conditions requiring immediate intervention
- **Level 2**: Urgent conditions requiring treatment within 15 minutes
- **Level 3**: Less urgent conditions, treatment within 30 minutes
- **Level 4**: Non-urgent conditions, treatment within 60 minutes

## Common Emergency Presentations

### Respiratory Emergencies
- **Severe Asthma**: Continuous bronchodilators, corticosteroids, oxygen
- **Pneumonia**: Antibiotics, supportive care, oxygen therapy
- **Bronchiolitis**: Supportive care, suction, oxygen, hydration

### Cardiovascular Emergencies
- **Shock**: Fluid resuscitation, vasopressors, immediate cardiology consult
- **Arrhythmias**: ECG monitoring, antiarrhythmic medications
- **Heart Failure**: Diuretics, ACE inhibitors, oxygen therapy

### Neurological Emergencies
- **Seizures**: Anticonvulsants, airway protection, blood glucose check
- **Head Injury**: CT scan, neurological monitoring, neurosurgical evaluation
- **Altered Mental Status**: Blood work, toxicology screen, LP if indicated

## Pain Management
- **Mild Pain (1-3)**: Acetaminophen, comfort measures
- **Moderate Pain (4-6)**: Ibuprofen, topical anesthetics
- **Severe Pain (7-10)**: Opioid analgesics, regional blocks

## Discharge Criteria
- Stable vital signs for minimum observation period
- Adequate oral intake and hydration
- Pain controlled with oral medications
- Follow-up arranged with primary care provider
- Family education completed and understood

## Quality Indicators
- Door-to-provider time
- Length of stay by condition
- Return visits within 72 hours
- Patient satisfaction scores
- Medication error rates', CURRENT_TIMESTAMP());

-- Insert sample operational documents  
INSERT INTO healthcare_documents VALUES
('OPERATIONS_001', 'unstructured_docs/operations/HIPAA_Compliance_Policy.md', 'HIPAA Compliance Policy', 'operations',
'# HIPAA Compliance Policy for Pediatric Hospital

## Policy Statement
This policy ensures compliance with the Health Insurance Portability and Accountability Act (HIPAA) to protect patient health information and maintain confidentiality standards.

## Scope
This policy applies to all employees, contractors, volunteers, and business associates who have access to Protected Health Information (PHI).

## Definitions

### Protected Health Information (PHI)
Any individually identifiable health information transmitted or maintained by the hospital including:
- Medical records and billing information
- Verbal communications about patients
- Electronic health records and databases
- Patient photographs and videos

### Minimum Necessary Standard
Only the minimum amount of PHI necessary to accomplish the intended purpose should be used or disclosed.

## Privacy Requirements

### Patient Rights
- Right to access their medical records
- Right to request amendments to their records
- Right to accounting of disclosures
- Right to request restrictions on use/disclosure
- Right to complain about privacy practices

### Use and Disclosure Limitations
PHI may only be used or disclosed for:
- Treatment purposes
- Payment activities  
- Healthcare operations
- Other purposes authorized by patient or required by law

## Security Safeguards

### Administrative Safeguards
- HIPAA Security Officer designation
- Workforce training and access management
- Information system access procedures
- Security incident response procedures

### Physical Safeguards
- Workstation security controls
- Media controls and disposal procedures
- Facility access restrictions
- Equipment disposal protocols

### Technical Safeguards
- Access control systems with unique user identification
- Automatic logoff capabilities
- Encryption of PHI in transit and at rest
- Audit logging and monitoring systems

## Breach Response Protocol

### Incident Assessment (Within 24 hours)
- Determine if incident constitutes a breach
- Assess risk to individuals affected
- Document incident details and timeline
- Notify HIPAA Security Officer

### Notification Requirements
- **Individuals**: Within 60 days of discovery
- **HHS**: Within 60 days of discovery  
- **Media**: If breach affects >500 residents of state/jurisdiction
- **Business Associates**: Without unreasonable delay

## Training Requirements
- Initial HIPAA training for all staff
- Annual refresher training
- Role-specific training for specialized positions
- Documentation of all training completion

## Enforcement and Penalties
- Verbal warning for minor infractions
- Written warning for repeated violations
- Suspension for serious breaches
- Termination for willful neglect or criminal activity

## Business Associate Agreements
All third-party vendors with PHI access must sign Business Associate Agreements outlining:
- Permitted uses and disclosures
- Safeguarding requirements
- Breach notification procedures
- Termination procedures', CURRENT_TIMESTAMP()),

('OPERATIONS_002', 'unstructured_docs/operations/Quality_Improvement_Procedures.md', 'Quality Improvement Procedures', 'operations',
'# Quality Improvement Procedures

## Quality Management Framework

### Mission Statement
To continuously improve patient safety, clinical outcomes, and family satisfaction through systematic quality improvement initiatives.

### Quality Committee Structure
- **Quality Council**: Executive oversight and strategic direction
- **Patient Safety Committee**: Incident analysis and prevention strategies
- **Clinical Quality Committee**: Clinical outcome improvement initiatives
- **Performance Improvement Teams**: Department-specific improvement projects

## Quality Metrics and Indicators

### Patient Safety Indicators
- Hospital-acquired infection rates
- Medication error rates
- Patient falls with injury
- Unplanned readmissions within 30 days
- Adverse events and near misses

### Clinical Quality Indicators
- Length of stay by diagnosis
- Mortality rates by service line
- Surgical site infection rates
- Emergency department wait times
- Patient satisfaction scores

### Operational Efficiency Metrics
- Bed utilization rates
- Operating room efficiency
- Laboratory turnaround times
- Discharge before noon rates
- Staff satisfaction scores

## Improvement Methodology

### Plan-Do-Study-Act (PDSA) Cycles
1. **Plan**: Define objective, predict outcomes, develop action plan
2. **Do**: Implement intervention, collect data
3. **Study**: Analyze results, compare to predictions
4. **Act**: Standardize or modify based on learnings

### Root Cause Analysis (RCA)
- Systematic investigation of serious adverse events
- Identification of contributing factors
- Development of action plans to prevent recurrence
- Follow-up monitoring of effectiveness

## Data Collection and Analysis

### Data Sources
- Electronic health records
- Incident reporting systems
- Patient satisfaction surveys
- Clinical registries
- Administrative databases

### Statistical Methods
- Control charts for monitoring performance
- Pareto analysis for prioritizing improvement opportunities
- Correlation analysis for identifying relationships
- Benchmarking against national standards

## Performance Improvement Projects

### Project Selection Criteria
- High volume, high risk, or problem-prone processes
- Alignment with strategic priorities
- Availability of resources and expertise
- Potential for measurable improvement

### Project Management
- Charter development with clear objectives
- Multidisciplinary team formation
- Timeline and milestone establishment
- Regular progress monitoring and reporting

## Communication and Reporting

### Internal Reporting
- Monthly quality dashboards
- Quarterly performance reports
- Annual quality improvement summary
- Real-time alerts for critical indicators

### External Reporting
- Joint Commission quality measures
- CMS reporting requirements
- State health department notifications
- Public quality scorecards

## Staff Engagement

### Quality Culture Development
- Leadership commitment and visibility
- Non-punitive error reporting environment
- Recognition and reward programs
- Quality improvement education and training

### Professional Development
- Quality improvement methodology training
- Data analysis and interpretation skills
- Change management competencies
- Team leadership development', CURRENT_TIMESTAMP());

-- Insert sample research documents
INSERT INTO healthcare_documents VALUES
('RESEARCH_001', 'unstructured_docs/research/Population_Health_Research_Study.md', 'Population Health Research Study', 'research',
'# Population Health Research Study: Pediatric Chronic Disease Management

## Study Overview

### Background
Chronic diseases affect approximately 20% of children and adolescents, with conditions such as asthma, diabetes, and obesity representing significant health burdens for families and healthcare systems.

### Objective
To evaluate the effectiveness of a comprehensive population health management program on clinical outcomes, healthcare utilization, and family quality of life for pediatric patients with chronic conditions.

### Study Design
Retrospective cohort study comparing outcomes before and after implementation of population health management program.

## Methods

### Study Population
- **Inclusion Criteria**: Patients aged 0-18 years with diagnosis of asthma, Type 1 diabetes, or obesity
- **Exclusion Criteria**: Patients with complex comorbidities, temporary residents
- **Sample Size**: 2,500 patients across three chronic condition groups
- **Study Period**: January 2020 - December 2023

### Intervention Components
1. **Care Coordination**: Dedicated nurse care coordinators for each condition
2. **Patient Registries**: Electronic tracking of care gaps and outcomes
3. **Decision Support**: Clinical alerts and evidence-based care protocols
4. **Patient Education**: Structured education programs for families
5. **Community Partnerships**: School health programs and community resources

### Data Collection
- **Electronic Health Records**: Clinical data, medications, procedures
- **Administrative Claims**: Healthcare utilization and costs
- **Patient Surveys**: Quality of life, satisfaction, adherence measures
- **School Records**: Attendance, academic performance (with consent)

## Primary Outcomes

### Clinical Measures
- **Asthma**: Emergency department visits, hospitalizations, asthma control test scores
- **Diabetes**: HbA1c levels, diabetic ketoacidosis episodes, blood glucose monitoring frequency
- **Obesity**: BMI percentiles, blood pressure, lipid profiles

### Healthcare Utilization
- Primary care visit frequency and adherence
- Specialist referral patterns and completion rates
- Emergency department utilization
- Hospital admission rates and length of stay

### Quality of Life Measures
- Pediatric Quality of Life Inventory (PedsQL)
- Family satisfaction with care coordination
- School absenteeism rates
- Caregiver burden and stress levels

## Preliminary Results

### Asthma Cohort (n=800)
- 35% reduction in ED visits (p<0.001)
- 28% reduction in hospitalizations (p<0.01)
- Improved asthma control test scores (6.2 to 8.1, p<0.001)
- 15% reduction in school absences (p<0.05)

### Diabetes Cohort (n=650)  
- Mean HbA1c improvement from 8.9% to 7.8% (p<0.001)
- 45% reduction in DKA episodes (p<0.01)
- Increased blood glucose monitoring (3.2 to 4.8 checks/day, p<0.001)
- Higher clinic visit adherence (72% to 89%, p<0.001)

### Obesity Cohort (n=1,050)
- Mean BMI percentile reduction from 97.2 to 94.1 (p<0.001)
- 22% of patients achieved ≥5% weight reduction
- Improved lipid profiles in 68% of participants
- Increased physical activity participation (p<0.01)

## Economic Analysis

### Cost Savings
- **Per Patient Annual Savings**: $2,847 across all conditions
- **Total Program Savings**: $7.1 million over 3-year period
- **Return on Investment**: $3.20 for every $1.00 invested
- **Cost Drivers**: Reduced emergency care, fewer hospitalizations

### Implementation Costs
- Care coordinator salaries and benefits
- Technology infrastructure and maintenance
- Staff training and education programs
- Patient education materials and resources

## Implications

### Clinical Practice
- Population health management improves outcomes across chronic conditions
- Care coordination reduces fragmentation and improves care quality
- Patient registries enable proactive identification of care gaps
- Family education and engagement are critical success factors

### Policy Considerations
- Value-based payment models support population health investments
- Technology infrastructure requires significant upfront investment
- Workforce development for care coordinators is essential
- Community partnerships enhance program effectiveness

## Limitations
- Single-center study may limit generalizability
- Pre-post design without control group
- Potential confounding by secular trends
- Loss to follow-up in mobile population

## Future Research
- Multi-site randomized controlled trial
- Cost-effectiveness analysis from societal perspective
- Long-term outcomes assessment (5-10 years)
- Implementation science evaluation of scalability', CURRENT_TIMESTAMP()),

('RESEARCH_002', 'unstructured_docs/research/Clinical_Trial_Protocol.md', 'Clinical Trial Protocol', 'research',
'# Clinical Trial Protocol: Novel Therapeutic Intervention for Pediatric Epilepsy

## Protocol Summary

### Study Title
A Phase II, Randomized, Double-Blind, Placebo-Controlled Trial of XYZ-123 as Adjunctive Therapy in Children with Treatment-Resistant Epilepsy

### Principal Investigator
Dr. Sarah Johnson, MD, PhD - Pediatric Neurology

### Study Objectives
- **Primary**: Evaluate efficacy of XYZ-123 in reducing seizure frequency
- **Secondary**: Assess safety, tolerability, and quality of life improvements
- **Exploratory**: Identify biomarkers predictive of treatment response

## Background and Rationale

### Unmet Medical Need
Approximately 30% of children with epilepsy have treatment-resistant epilepsy (TRE), defined as failure to achieve seizure freedom with two appropriately chosen antiepileptic drugs.

### Mechanism of Action
XYZ-123 is a novel GABA-A receptor positive allosteric modulator with demonstrated neuroprotective properties in preclinical models.

### Preclinical Evidence
- Reduced seizure frequency by 65% in juvenile animal models
- Favorable safety profile with no significant adverse effects
- Improved cognitive function compared to standard therapies

## Study Design

### Design Overview
- **Phase**: II
- **Design**: Randomized, double-blind, placebo-controlled
- **Duration**: 24-week treatment period + 4-week follow-up
- **Randomization**: 2:1 (XYZ-123:placebo)
- **Primary Endpoint**: Percent reduction in seizure frequency

### Inclusion Criteria
- Age 6-17 years at enrollment
- Confirmed diagnosis of epilepsy with ≥4 seizures per month
- Treatment failure with ≥2 appropriate AEDs
- Stable AED regimen for ≥4 weeks prior to enrollment
- Written informed consent and age-appropriate assent

### Exclusion Criteria
- Progressive neurological disease
- History of psychosis or major psychiatric disorder
- Pregnancy or risk of pregnancy
- Recent participation in another clinical trial
- Known hypersensitivity to study drug components

## Study Procedures

### Screening Period (4 weeks)
- Medical history and physical examination
- Neurological assessment and EEG
- Laboratory tests (CBC, CMP, LFTs)
- Seizure diary training and baseline recording
- Quality of life questionnaires

### Treatment Period (24 weeks)
- **Visits**: Weeks 2, 4, 8, 12, 16, 20, 24
- **Assessments**: Seizure frequency, adverse events, vital signs
- **Laboratory Monitoring**: Weeks 4, 12, 24
- **Drug Level Monitoring**: XYZ-123 and concomitant AEDs
- **EEG Monitoring**: Weeks 12 and 24

### Follow-up Period (4 weeks)
- Safety assessment and adverse event monitoring
- Seizure frequency recording
- Laboratory tests for safety

## Dosing and Administration

### XYZ-123 Dosing
- **Starting Dose**: 5 mg twice daily
- **Titration**: Increase by 5 mg BID every 2 weeks
- **Target Dose**: 15-20 mg twice daily based on efficacy and tolerability
- **Maximum Dose**: 25 mg twice daily
- **Administration**: Oral tablets with or without food

### Dose Modifications
- Reduce dose for intolerable side effects
- Temporary discontinuation for serious adverse events
- Permanent discontinuation for safety concerns

## Outcome Measures

### Primary Efficacy Endpoint
Percent reduction in seizure frequency from baseline to treatment period (weeks 20-24)

### Secondary Efficacy Endpoints
- ≥50% responder rate (proportion with ≥50% seizure reduction)
- Seizure-free rate during maintenance period
- Time to first seizure during treatment
- Change in seizure severity scores

### Safety Endpoints
- Incidence of treatment-emergent adverse events
- Changes in laboratory parameters
- Changes in vital signs and weight
- Suicidality assessment scores

### Quality of Life Endpoints
- Pediatric Quality of Life Inventory (PedsQL)
- Quality of Life in Childhood Epilepsy (QOLCE)
- Caregiver strain and family functioning measures

## Statistical Analysis

### Sample Size Calculation
- **Target Effect Size**: 30% difference in seizure reduction
- **Power**: 80%
- **Alpha Level**: 0.05 (two-sided)
- **Planned Enrollment**: 120 patients (80 active, 40 placebo)
- **Dropout Rate**: 20% assumed

### Primary Analysis
Modified intent-to-treat analysis using mixed-effects models for repeated measures

### Safety Analysis
All patients receiving ≥1 dose of study medication

## Data Safety Monitoring

### Data Safety Monitoring Board (DSMB)
Independent board reviewing safety data every 6 months

### Stopping Rules
- Unacceptable safety profile emerges
- Futility analysis suggests low probability of success
- External safety information changes benefit-risk profile

## Regulatory and Ethical Considerations

### Regulatory Status
- IND application submitted to FDA
- IRB approval obtained
- Clinical trial registration on ClinicalTrials.gov

### Ethical Considerations
- Pediatric assent process age-appropriate
- Regular safety monitoring and reporting
- Data privacy and confidentiality protection
- Fair participant recruitment and selection

## Timeline and Milestones

### Study Timeline
- **First Patient Enrolled**: Q2 2024
- **Last Patient Enrolled**: Q4 2024  
- **Last Patient Completed**: Q2 2025
- **Database Lock**: Q3 2025
- **Final Study Report**: Q4 2025

### Key Milestones
- 50% enrollment: Q3 2024
- Interim safety analysis: Q1 2025
- Primary endpoint analysis: Q3 2025', CURRENT_TIMESTAMP());

-- Verify document insertion
SELECT 
    category,
    COUNT(*) as document_count,
    LISTAGG(title, ', ') as documents
FROM healthcare_documents 
GROUP BY category
ORDER BY category;

SELECT '✅ Healthcare documents loaded successfully!' as status;
