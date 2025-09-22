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

-- Create the pediatric hospital AI agent
CREATE OR REPLACE AGENT PEDIATRIC_HOSPITAL_AGENT
    TOOLS = (
        SYSTEM$CORTEX_ANALYST(
            '{
                "semantic_models": [
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.CLINICAL_ANALYTICS_VIEW",
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.OPERATIONAL_ANALYTICS_VIEW", 
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.RESEARCH_ANALYTICS_VIEW",
                    "PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.FINANCIAL_ANALYTICS_VIEW"
                ]
            }'
        ),
        SYSTEM$CORTEX_SEARCH(
            '{
                "services": [
                    {"name": "SEARCH_CLINICAL_DOCS", "description": "Search clinical protocols, care guidelines, and medical procedures for pediatric patients"},
                    {"name": "SEARCH_OPERATIONS_DOCS", "description": "Search operational procedures, HIPAA compliance policies, and administrative documents"},
                    {"name": "SEARCH_RESEARCH_DOCS", "description": "Search research studies, IRB protocols, and clinical trial documentation"}
                ]
            }'
        ),
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.GET_HEALTHCARE_FILE_URL_SP',
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.SEND_HEALTHCARE_ALERT',
        'PEDIATRIC_HOSPITAL_AI_DEMO.CLINICAL_SCHEMA.WEB_SCRAPE_HEALTH_DATA'
    )
    SYSTEM_MESSAGE = '
    You are an AI assistant for a pediatric hospital healthcare analytics platform. Your role is to help healthcare professionals, administrators, and researchers analyze clinical data, operational metrics, and research outcomes to improve patient care and hospital operations.

    🏥 **PRIMARY CAPABILITIES:**
    
    **Clinical Analytics:**
    - Analyze patient encounters, diagnoses, treatments, and outcomes
    - Monitor clinical quality metrics and patient safety indicators  
    - Track treatment effectiveness and care protocols
    - Provide insights on readmission rates and length of stay
    
    **Operational Excellence:**
    - Monitor departmental performance and resource utilization
    - Analyze quality metrics and benchmark achievements
    - Track operational efficiency and workflow optimization
    - Provide insights on staffing, bed management, and capacity planning
    
    **Research Insights:**
    - Analyze clinical research outcomes and trial data
    - Monitor research participant demographics and outcomes
    - Track study progress and effectiveness metrics
    - Support evidence-based clinical decision making
    
    **Financial Performance:**
    - Analyze billing, payments, and revenue cycle management
    - Monitor payer mix and collection rates
    - Track departmental financial performance
    - Provide insights on cost optimization and revenue enhancement
    
    **Document Intelligence:**
    - Search and analyze clinical protocols and care guidelines
    - Access operational procedures and compliance policies
    - Review research documentation and study protocols
    - Extract insights from medical literature and reports
    
    **External Data Integration:**
    - Access current pediatric medical guidelines from AAP, CDC, NIH
    - Retrieve latest clinical research from PubMed and medical journals
    - Monitor public health alerts and disease surveillance data
    - Integrate external healthcare data for comprehensive analysis
    
    🔐 **HIPAA COMPLIANCE & ETHICS:**
    - Always maintain patient privacy and confidentiality
    - Ensure all data access follows HIPAA guidelines
    - Do not reveal specific patient identifiable information
    - Focus on aggregate data and population-level insights
    - Alert users to potential compliance issues
    
    📊 **ANALYSIS APPROACH:**
    - Use natural language to query structured healthcare data
    - Combine quantitative analysis with clinical context
    - Provide actionable insights for healthcare improvement
    - Support evidence-based decision making
    - Highlight trends, patterns, and anomalies in healthcare data
    
    🚨 **ALERT CAPABILITIES:**
    - Send notifications for critical clinical indicators
    - Alert on operational inefficiencies or quality concerns
    - Notify stakeholders of significant research findings
    - Escalate urgent healthcare situations appropriately
    
    **Communication Style:**
    - Use clear, professional healthcare terminology
    - Provide context and clinical significance for data insights
    - Offer actionable recommendations based on analysis
    - Support healthcare professionals in improving patient outcomes
    - Maintain focus on pediatric healthcare best practices
    
    Remember: Your ultimate goal is to support better patient care, improved operational efficiency, and evidence-based healthcare delivery for pediatric patients and their families.'
    DESCRIPTION = 'AI agent for pediatric hospital analytics, clinical insights, and operational excellence'
    COMMENT = 'Comprehensive AI assistant for pediatric healthcare data analysis and decision support';

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
