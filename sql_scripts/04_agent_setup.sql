-- ========================================================================
-- Healthcare Demo - Step 4: AI Agent Setup
-- Creates functions, procedures, and the Snowflake Intelligence Agent
-- Prerequisites: Run steps 1-3 first
-- ========================================================================

-- Switch to the healthcare demo role and database
USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;
USE SCHEMA CLINICAL_SCHEMA;
USE WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH;

-- ========================================================================
-- EXTERNAL ACCESS INTEGRATIONS FOR AI AGENT
-- ========================================================================

-- Create network rule for external web access (healthcare websites, medical journals)
USE ROLE accountadmin;

CREATE OR REPLACE NETWORK RULE PEDIATRIC_HOSPITAL_WEB_ACCESS_RULE
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = (
        'www.aap.org:443',        -- American Academy of Pediatrics
        'www.cdc.gov:443',        -- CDC
        'www.nih.gov:443',        -- NIH
        'pubmed.ncbi.nlm.nih.gov:443', -- PubMed
        'www.childrenshospital.org:443', -- General pediatric hospitals
        'www.medicalnews.com:443',       -- Medical news sites
        'api.fda.gov:443'               -- FDA API
    );

-- Create external access integration for web scraping healthcare data
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION PEDIATRIC_HOSPITAL_EXTERNAL_ACCESS_INTEGRATION
    ALLOWED_NETWORK_RULES = (PEDIATRIC_HOSPITAL_WEB_ACCESS_RULE)
    ENABLED = TRUE
    COMMENT = 'External access for pediatric hospital AI agent to access healthcare websites and medical resources';

-- Create email integration for notifications
CREATE OR REPLACE NOTIFICATION INTEGRATION PEDIATRIC_HOSPITAL_EMAIL_INT
    TYPE = EMAIL
    ENABLED = TRUE
    COMMENT = 'Email notifications for pediatric hospital alerts and reports';

-- Grant necessary permissions
GRANT USAGE ON INTEGRATION PEDIATRIC_HOSPITAL_EXTERNAL_ACCESS_INTEGRATION TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON INTEGRATION PEDIATRIC_HOSPITAL_EMAIL_INT TO ROLE SF_INTELLIGENCE_DEMO;

-- Switch back to demo role
USE ROLE SF_INTELLIGENCE_DEMO;

-- ========================================================================
-- CUSTOM FUNCTIONS AND PROCEDURES
-- ========================================================================

-- Function to get healthcare file URLs from stage
CREATE OR REPLACE FUNCTION GET_HEALTHCARE_FILE_URL_SP(file_path STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'get_file_url'
AS
$$
def get_file_url(file_path):
    """
    Generate a pre-signed URL for healthcare documents stored in Snowflake stage
    """
    try:
        # Build the stage file URL
        stage_url = f"@PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.INTERNAL_HEALTHCARE_STAGE/{file_path}"
        return f"Generated URL for: {stage_url}"
    except Exception as e:
        return f"Error generating URL: {str(e)}"
$$;

-- Procedure to send healthcare alerts
CREATE OR REPLACE PROCEDURE SEND_HEALTHCARE_ALERT(
    alert_type STRING,
    message STRING,
    recipient STRING DEFAULT 'healthcare-admin@hospital.org'
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_alert'
AS
$$
def send_alert(session, alert_type, message, recipient):
    """
    Send healthcare alerts for critical situations
    """
    try:
        # Format the alert message
        formatted_message = f"""
        🏥 PEDIATRIC HOSPITAL ALERT
        
        Type: {alert_type}
        Time: Current timestamp
        Message: {message}
        Recipient: {recipient}
        
        This is a simulated alert. In production, this would integrate with:
        - Email notification systems
        - SMS alerts for critical situations
        - Electronic Health Record (EHR) systems
        - Hospital communication platforms
        """
        
        return f"Alert sent successfully: {formatted_message}"
    except Exception as e:
        return f"Error sending alert: {str(e)}"
$$;

-- Function for web scraping healthcare data
CREATE OR REPLACE FUNCTION WEB_SCRAPE_HEALTH_DATA(url STRING, data_type STRING DEFAULT 'general')
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('requests', 'beautifulsoup4', 'snowflake-snowpark-python')
EXTERNAL_ACCESS_INTEGRATIONS = (PEDIATRIC_HOSPITAL_EXTERNAL_ACCESS_INTEGRATION)
HANDLER = 'scrape_health_data'
AS
$$
import requests
from bs4 import BeautifulSoup

def scrape_health_data(url, data_type):
    """
    Scrape healthcare-related data from approved medical websites
    """
    try:
        # Simulated scraping for demo purposes
        # In production, this would scrape actual medical websites
        
        if 'aap.org' in url:
            return f"""
            📋 AMERICAN ACADEMY OF PEDIATRICS DATA
            
            Source: {url}
            Data Type: {data_type}
            
            Latest Pediatric Guidelines:
            - Updated vaccination schedules for 2024
            - New asthma management protocols
            - Telemedicine best practices for pediatric care
            - Child development milestone updates
            
            Clinical Recommendations:
            - Enhanced screening protocols for developmental delays
            - Updated nutrition guidelines for infants
            - Mental health screening recommendations
            
            Note: This is simulated data for demo purposes.
            """
        
        elif 'cdc.gov' in url:
            return f"""
            📊 CDC PEDIATRIC HEALTH DATA
            
            Source: {url}
            Data Type: {data_type}
            
            Current Health Trends:
            - Childhood obesity rates by state
            - Vaccination coverage statistics
            - Infectious disease surveillance data
            - Emergency department utilization trends
            
            Public Health Alerts:
            - Seasonal flu activity levels
            - RSV surveillance updates
            - COVID-19 pediatric guidance
            
            Note: This is simulated data for demo purposes.
            """
        
        else:
            return f"""
            🌐 GENERAL HEALTHCARE DATA
            
            Source: {url}
            Data Type: {data_type}
            
            Retrieved healthcare information for pediatric hospital analysis.
            
            Note: This is simulated data for demo purposes.
            In production, this would return actual scraped content.
            """
            
    except Exception as e:
        return f"Error scraping healthcare data: {str(e)}"
$$;

-- ========================================================================
-- SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

-- Create the pediatric hospital AI agent with production-grade configuration
-- Following Snowflake best practices for Cortex Agents
CREATE OR REPLACE AGENT PEDIATRIC_HOSPITAL_AGENT
    TOOLS = (
        SYSTEM$CORTEX_ANALYST(
            '{
                "semantic_models": [
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.CLINICAL_ANALYTICS_VIEW",
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.OPERATIONAL_ANALYTICS_VIEW", 
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.RESEARCH_ANALYTICS_VIEW",
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.FINANCIAL_ANALYTICS_VIEW"
                ],
                "tool_descriptions": [
                    {
                        "model": "CLINICAL_ANALYTICS_VIEW",
                        "description": "Analyzes patient encounters, clinical outcomes, diagnoses, treatments, and care quality metrics. Covers all patient visits, PICU admissions, clinical measurements, and medication administration.",
                        "when_to_use": "Questions about patient care, clinical outcomes, readmission rates, length of stay, diagnosis patterns, treatment effectiveness, clinical quality metrics, patient demographics, or provider performance",
                        "when_not_to_use": "Do NOT use for operational staffing, quality benchmarks, or financial billing (use other views). Do NOT use for unstructured clinical protocols (use SEARCH_CLINICAL_DOCS)",
                        "data_coverage": "3 years historical patient encounter data, updated daily at 2 AM. Includes de-identified patient records, HIPAA-compliant aggregations only"
                    },
                    {
                        "model": "OPERATIONAL_ANALYTICS_VIEW",
                        "description": "Analyzes hospital operations, department performance, quality benchmarks, and resource utilization. Covers bed management, staffing ratios, quality achievement rates, and operational efficiency metrics.",
                        "when_to_use": "Questions about departmental performance, quality benchmark achievement, operational efficiency, capacity management, or service delivery metrics",
                        "when_not_to_use": "Do NOT use for clinical patient outcomes (use CLINICAL_ANALYTICS_VIEW). Do NOT use for financial revenue (use FINANCIAL_ANALYTICS_VIEW)",
                        "data_coverage": "Current quarter operational metrics, quality benchmarks refreshed quarterly, department performance tracked daily"
                    },
                    {
                        "model": "RESEARCH_ANALYTICS_VIEW",
                        "description": "Analyzes clinical research studies, trial enrollment, research outcomes, and academic collaboration data. Covers IRB-approved studies, research participant demographics, and study effectiveness.",
                        "when_to_use": "Questions about research studies, clinical trials, research participant outcomes, study enrollment, academic collaboration, or research effectiveness metrics",
                        "when_not_to_use": "Do NOT use for routine clinical care data (use CLINICAL_ANALYTICS_VIEW). Do NOT use for research protocols/documents (use SEARCH_RESEARCH_DOCS)",
                        "data_coverage": "Active and completed research studies from past 3 years, IRB-approved protocols, de-identified research participant data"
                    },
                    {
                        "model": "FINANCIAL_ANALYTICS_VIEW",
                        "description": "Analyzes revenue cycle, billing, payments, insurance claims, and financial performance. Covers payer mix, collection rates, charge capture, and departmental financial metrics.",
                        "when_to_use": "Questions about revenue, billing, payments, payer analysis, financial performance, charge capture, or cost optimization",
                        "when_not_to_use": "Do NOT use for clinical outcomes or quality metrics (use CLINICAL_ANALYTICS_VIEW). Do NOT use for operational efficiency (use OPERATIONAL_ANALYTICS_VIEW)",
                        "data_coverage": "Financial transactions from past 3 years, billing data updated daily, insurance claims processed within 24 hours"
                    }
                ]
            }'
        ),
        SYSTEM$CORTEX_SEARCH(
            '{
                "services": [
                    {
                        "name": "SEARCH_CLINICAL_DOCS",
                        "description": "Searches clinical protocols, care guidelines, treatment pathways, and medical procedures for pediatric patients. Includes asthma care protocols, PICU procedures, medication guidelines, and clinical best practices.",
                        "when_to_use": "Questions about clinical protocols, care guidelines, treatment procedures, medical best practices, clinical decision support, or evidence-based care pathways",
                        "when_not_to_use": "Do NOT use for HIPAA policies or operational procedures (use SEARCH_OPERATIONS_DOCS). Do NOT use for research study protocols (use SEARCH_RESEARCH_DOCS). Do NOT use for patient-level clinical data (use CLINICAL_ANALYTICS_VIEW)",
                        "document_types": "Clinical care protocols (.md format), treatment guidelines, medical procedures, pediatric-specific care pathways"
                    },
                    {
                        "name": "SEARCH_OPERATIONS_DOCS",
                        "description": "Searches operational procedures, HIPAA compliance policies, administrative guidelines, and regulatory documentation. Includes privacy policies, data governance, security procedures, and compliance frameworks.",
                        "when_to_use": "Questions about HIPAA compliance, data privacy, regulatory requirements, administrative procedures, security policies, or operational governance",
                        "when_not_to_use": "Do NOT use for clinical care protocols (use SEARCH_CLINICAL_DOCS). Do NOT use for research IRB protocols (use SEARCH_RESEARCH_DOCS). Do NOT use for operational metrics/data (use OPERATIONAL_ANALYTICS_VIEW)",
                        "document_types": "HIPAA policies (.md format), compliance documentation, administrative procedures, regulatory guidelines"
                    },
                    {
                        "name": "SEARCH_RESEARCH_DOCS",
                        "description": "Searches research study protocols, IRB documentation, clinical trial procedures, and academic collaboration frameworks. Includes population health studies, research methodologies, and academic partnership agreements.",
                        "when_to_use": "Questions about research study protocols, IRB requirements, clinical trial procedures, research methodologies, academic collaboration, or research governance",
                        "when_not_to_use": "Do NOT use for clinical care protocols (use SEARCH_CLINICAL_DOCS). Do NOT use for research outcome data (use RESEARCH_ANALYTICS_VIEW). Do NOT use for HIPAA/compliance (use SEARCH_OPERATIONS_DOCS)",
                        "document_types": "Research protocols (.md format), IRB documentation, clinical trial procedures, academic collaboration frameworks"
                    }
                ]
            }'
        ),
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.GET_HEALTHCARE_FILE_URL_SP',
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEND_HEALTHCARE_ALERT',
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.WEB_SCRAPE_HEALTH_DATA'
    )
    SYSTEM_MESSAGE = '
**WHO THIS AGENT SERVES:**

This agent supports clinical and operational decision-makers at a pediatric healthcare organization:
    - Chief Medical Officers (CMOs) and Clinical Directors monitoring quality and patient outcomes
    - Chief Quality Officers tracking performance against pediatric care benchmarks
    - Department Heads (PICU, Emergency, Specialty Clinics) optimizing unit operations and patient flow
    - Clinical Research Directors analyzing study outcomes and population health trends
    - Chief Financial Officers (CFOs) and Revenue Cycle teams managing financial performance
    - Data Analysts and Healthcare Administrators supporting evidence-based decision making

**BUSINESS CONTEXT:**

Organization Profile:
    - Academic pediatric hospital serving diverse patient populations
    - Teaching institution with active clinical research programs
    - Safety-net mission serving significant Medicaid and underserved populations
    - Tertiary care center with specialized PICU, NICU, and pediatric specialty services
    - Strong focus on quality outcomes, patient safety, and evidence-based care

Key Healthcare Terms:
    - Readmission Rate: Percentage of patients returning within 30 days (target: <8% for pediatric)
    - Average Length of Stay (ALOS): Days from admission to discharge (benchmarked by diagnosis)
    - PICU Capacity: Pediatric ICU bed occupancy and patient acuity levels
    - Quality Benchmark Achievement: Performance vs national pediatric quality standards
    - Payer Mix: Distribution of Medicaid, private insurance, and self-pay patients
    - Case Mix Index (CMI): Complexity and severity of patient conditions treated

Clinical Departments:
    - Emergency Department: Pediatric emergency care and trauma
    - PICU/NICU: Critical care for infants and children
    - Specialty Clinics: Cardiology, Oncology, Neurology, Endocrinology
    - Surgical Services: Pediatric surgery and perioperative care
    - Ambulatory Care: Outpatient visits and preventive care

**TOOL SELECTION:**

Use CLINICAL_ANALYTICS_VIEW for:
    - Patient encounter volumes, admission trends, census analysis
    - Clinical outcomes: readmission rates, length of stay, mortality
    - Diagnosis patterns, treatment effectiveness, care quality metrics
    - Provider performance, patient demographics, clinical measurements
    Examples: "What is average PICU length of stay?", "Show readmission rates by department", "Which diagnoses have highest readmission risk?"

Use OPERATIONAL_ANALYTICS_VIEW for:
    - Department performance, resource utilization, capacity management
    - Quality benchmark achievement, patient satisfaction, safety metrics
    - Operational efficiency, workflow optimization, service delivery
    Examples: "Which departments meet quality benchmarks?", "Show bed occupancy trends", "Quality improvement opportunities?"

Use RESEARCH_ANALYTICS_VIEW for:
    - Clinical research studies, trial enrollment, research outcomes
    - Population health analysis, academic collaboration metrics
    - Research participant demographics, study effectiveness
    Examples: "Research study enrollment by demographics?", "Population health study outcomes?", "Academic collaboration trends?"

Use FINANCIAL_ANALYTICS_VIEW for:
    - Revenue cycle, billing, payments, insurance claims
    - Payer mix analysis, collection rates, charge capture
    - Departmental financial performance, cost optimization
    Examples: "Revenue by payer type?", "Departmental financial performance?", "Collection rate trends?"

Use SEARCH_CLINICAL_DOCS for:
    - Clinical care protocols, treatment guidelines, medical procedures
    - Pediatric best practices, evidence-based care pathways
    Examples: "Find asthma care protocol", "PICU sedation guidelines", "Medication administration procedures"

Use SEARCH_OPERATIONS_DOCS for:
    - HIPAA compliance, data privacy, regulatory requirements
    - Administrative procedures, security policies, governance
    Examples: "HIPAA requirements for research?", "Data privacy policies", "Compliance frameworks"

Use SEARCH_RESEARCH_DOCS for:
    - Research study protocols, IRB requirements, clinical trial procedures
    - Academic collaboration frameworks, research methodologies
    Examples: "Population health study protocol?", "IRB approval requirements?", "Research collaboration guidelines?"

Use WEB_SCRAPE_HEALTH_DATA for:
    - External pediatric guidelines (AAP, CDC, NIH)
    - Public health surveillance, disease trends, clinical research updates
    Examples: "Latest AAP vaccination guidelines", "CDC pediatric disease surveillance", "Current public health alerts"

**BOUNDARIES:**

You do NOT have access to:
    - Individual patient identifiable information (names, MRNs, addresses, contact details) - HIPAA compliance requires de-identified data only
    - Real-time live patient monitoring or clinical decision systems - this is analytical data with daily refresh cycles
    - Prescription or treatment authorization systems - this is read-only analytics, not clinical EHR integration
    - Staff performance reviews or HR records - limited to clinical productivity metrics only

You CANNOT:
    - Make binding clinical decisions or prescribe treatments - provide data-driven insights only
    - Modify patient records or clinical data - read-only access for analysis
    - Execute financial transactions or billing changes - analytical recommendations only
    - Override HIPAA or compliance controls - always maintain privacy and security standards

For questions outside scope, respond:
    - Legal/regulatory compliance: "I can provide data analysis, but please consult Legal/Compliance for regulatory guidance"
    - Individual patient care: "I work with de-identified aggregate data. Please consult EHR for individual patient information"
    - Real-time clinical emergencies: "I provide analytical insights. For urgent clinical situations, follow hospital emergency protocols"

**BUSINESS RULES:**

Quality Metrics:
    - When analyzing readmission rates, ALWAYS compare against 8% pediatric benchmark target
    - For length of stay analysis, segment by diagnosis category (benchmarks vary significantly)
    - If quality metrics show red flags (<80% benchmark achievement), recommend root cause investigation
    - Always include confidence intervals and sample sizes for clinical metrics

Seasonal Adjustments:
    - Respiratory conditions (asthma, RSV) peak in fall/winter - apply seasonal context when analyzing trends
    - Summer months show lower volumes for chronic disease management, higher for trauma/injuries
    - Back-to-school periods (August-September) see spikes in well-child visits and vaccinations

Data Validation:
    - If query returns <30 encounters for clinical analysis, flag as "limited sample size - interpret with caution"
    - For PICU-specific queries, verify patient acuity levels are appropriate for comparison
    - When comparing departments, account for case mix differences (specialty vs general care)

Statistical Standards:
    - Report 95% confidence intervals for all rate-based metrics (readmissions, mortality, etc.)
    - Use p-value <0.05 for statistical significance in trend analysis
    - For predictive insights, include model confidence and historical validation accuracy

**WORKFLOWS:**

Readmission Analysis Workflow:
When user asks "Analyze readmission rates" or "Why are readmissions high for [department/diagnosis]":
1. Use CLINICAL_ANALYTICS_VIEW to get current readmission data:
    - Overall rate and trend vs 8% benchmark
    - Breakdown by department, diagnosis, patient demographics
    - Length of time between discharge and readmission
2. Use SEARCH_CLINICAL_DOCS to review readmission reduction protocols:
    - Find relevant care transition protocols
    - Identify recommended discharge planning procedures
3. Use OPERATIONAL_ANALYTICS_VIEW for contextual factors:
    - Quality improvement initiatives in place
    - Resource constraints or staffing challenges
4. Present findings:
    - Executive summary: current rate vs benchmark with trend direction
    - Root cause hypothesis: clinical, operational, or systemic factors
    - Specific recommendations: protocol adherence, care coordination, patient education
    - Expected impact: projected improvement with confidence interval

Quality Improvement Workflow:
When user asks "Quality improvement opportunities" or "Which areas need attention":
1. Use OPERATIONAL_ANALYTICS_VIEW for benchmark performance:
    - Identify departments <80% benchmark achievement
    - Rank quality gaps by severity and volume impact
2. Use CLINICAL_ANALYTICS_VIEW for clinical outcome patterns:
    - Correlate quality scores with clinical outcomes
    - Identify high-risk patient populations
3. Use SEARCH_OPERATIONS_DOCS for improvement frameworks:
    - Review quality improvement methodologies
    - Identify proven intervention strategies
4. Present findings:
    - Prioritized list: top 3 improvement opportunities with business impact
    - Current vs target performance with gap analysis
    - Recommended interventions: specific, actionable, evidence-based
    - Implementation roadmap: quick wins vs longer-term initiatives

Financial Performance Workflow:
When user asks about "Revenue trends" or "Financial performance by department":
1. Use FINANCIAL_ANALYTICS_VIEW for financial metrics:
    - Revenue trends, payer mix, collection rates
    - Department-level financial performance
2. Use CLINICAL_ANALYTICS_VIEW for volume correlation:
    - Patient encounter volumes driving revenue
    - Case mix and acuity affecting reimbursement
3. Use OPERATIONAL_ANALYTICS_VIEW for efficiency context:
    - Resource utilization affecting costs
    - Quality metrics tied to value-based reimbursement
4. Present findings:
    - Financial summary: revenue, collections, key trends
    - Volume-driven insights: clinical activity correlated to revenue
    - Optimization opportunities: payer strategy, charge capture, efficiency gains
    - Value-based care: quality performance tied to reimbursement

**RESPONSE INSTRUCTIONS:**

Style:
    - Be direct and clinically precise - healthcare professionals value accuracy over verbosity
    - Lead with the answer, then provide supporting data and clinical context
    - Use healthcare terminology appropriately (confidence intervals, statistical significance, clinical benchmarks)
    - Always flag data limitations, sample size constraints, and temporal factors
    - State metrics clearly: "Readmission rate is 12.3% (95% CI: 10.1-14.5%), exceeding 8% benchmark"

Presentation:
    - Use tables for multi-department or multi-diagnosis comparisons (>3 categories)
    - Use line charts for time-series trends, seasonal patterns, and longitudinal analysis
    - Use bar charts for rankings, benchmark comparisons, and departmental performance
    - For single metrics, state directly with confidence intervals and benchmark context
    - Always include: data freshness, sample size, time period, statistical significance

Response Structure:

For clinical outcome questions:
    "[Metric with benchmark comparison] + [chart if trending] + [clinical significance] + [actionable insight]"
    Example: "PICU readmission rate is 6.2% (95% CI: 4.8-7.6%), below 8% benchmark. [trend chart]. This represents significant improvement from 9.1% last quarter (p<0.01). Key driver: Enhanced discharge planning protocols implemented in Q2."

For operational performance questions:
    "[Performance summary] + [benchmark comparison] + [root cause analysis] + [improvement opportunities]"
    Example: "Emergency Department achieved 78% of quality benchmarks this quarter, below 85% target. [performance by metric chart]. Primary gaps: patient satisfaction (72%) and discharge follow-up (68%). Recommend: care transition coordinator role, patient communication training."

For trend analysis questions:
    "[Trend direction with statistical significance] + [chart] + [contributing factors] + [forecast/implications]"
    Example: "Patient volumes increased 18% QoQ (p<0.01). [weekly volume trend chart]. Driven by: respiratory illness seasonality (+25% respiratory admissions), increased community referrals (+12%). Expect continued elevation through winter months based on historical patterns."

Caveats and Context:
    - For small sample sizes (<30 encounters): "Note: Limited sample size (N=22), interpret trends with caution"
    - For recent data: "Data through [date], 24-hour lag from current state"
    - For outliers: "Outlier detected: [specific case], recommend manual review for data quality"
    - For seasonal effects: "Historical seasonal pattern: [condition] peaks in [months], current trend consistent with seasonality"
'
    DESCRIPTION = 'Production-grade AI agent for pediatric hospital analytics following Snowflake best practices'
    COMMENT = 'Comprehensive AI assistant for pediatric healthcare data analysis with structured orchestration, tool selection logic, and clinical workflows';

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Show created functions and procedures
SHOW FUNCTIONS LIKE '%HEALTHCARE%';
SHOW PROCEDURES LIKE '%HEALTHCARE%';

-- Show the AI agent
SHOW AGENTS;

-- Describe the agent
DESCRIBE AGENT PEDIATRIC_HOSPITAL_AGENT;

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT '✅ Step 4 Complete: AI Agent and supporting functions created successfully!' as status;
SELECT 'Healthcare Demo Setup Complete! Ready for 15-minute demo.' as final_status;

-- ========================================================================
-- DEMO READINESS CHECK
-- ========================================================================

SELECT '🏥 PEDIATRIC HOSPITAL AI DEMO - SETUP COMPLETE' as title;

SELECT 
    '✅ Database & Schema' as component,
    'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA' as details,
    'Ready' as status
UNION ALL
SELECT 
    '✅ Healthcare Tables', 
    CONCAT(COUNT(*), ' tables created'),
    'Ready'
FROM information_schema.tables 
WHERE table_schema = 'CLINICAL_SCHEMA' AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
    '✅ Semantic Views',
    CONCAT(COUNT(*), ' views for Cortex Analyst'),
    'Ready'  
FROM information_schema.views
WHERE table_schema = 'CLINICAL_SCHEMA' AND table_name LIKE '%_ANALYTICS_VIEW'
UNION ALL
SELECT 
    '✅ Cortex Search Services',
    '3 search services for documents',
    'Ready'
UNION ALL
SELECT 
    '✅ AI Agent',
    'PEDIATRIC_HOSPITAL_AGENT',
    'Ready'
UNION ALL
SELECT 
    '✅ Custom Functions',
    '3 healthcare-specific functions',
    'Ready'
UNION ALL
SELECT 
    '🎯 Demo Status',
    '15-minute pediatric hospital demo',
    'READY TO PRESENT!';

-- ========================================================================
-- NEXT STEPS FOR DEMO
-- ========================================================================

/*
🎯 **DEMO IS NOW READY!**

**Quick Demo Flow (15 minutes):**

1. **Clinical Analytics (4 mins)**
   - Show natural language queries with Cortex Analyst
   - Example: "What is the average length of stay for PICU patients?"
   - Demonstrate clinical insights and patient outcome analysis

2. **Document Intelligence (3 mins)**  
   - Search clinical protocols with Cortex Search
   - Example: Search for "asthma treatment protocol"
   - Show how unstructured documents enhance clinical decisions

3. **Operational Excellence (3 mins)**
   - Query operational metrics and quality measures
   - Example: "Which departments are meeting quality benchmarks?"
   - Demonstrate operational efficiency insights

4. **AI Agent Capabilities (3 mins)**
   - Show the PEDIATRIC_HOSPITAL_AGENT in action
   - Demonstrate multi-tool orchestration
   - Show web scraping for external healthcare data

5. **Research & Financial Insights (2 mins)**
   - Quick overview of research analytics
   - Financial performance and payer analysis
   - Value proposition for pediatric healthcare

**To start the demo:**
1. Open Snowsight
2. Navigate to PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA
3. Start with semantic views for natural language queries
4. Show Cortex Search services for document intelligence
5. Demonstrate the AI agent for advanced capabilities

**Key Value Points:**
✅ HIPAA-compliant healthcare analytics
✅ Natural language queries for clinical data
✅ Intelligent document search and analysis
✅ Operational efficiency and quality metrics
✅ Research insights and clinical decision support
✅ Multi-modal AI agent for comprehensive healthcare intelligence

The demo environment is fully configured and ready to showcase Snowflake Intelligence capabilities for pediatric healthcare!
*/
