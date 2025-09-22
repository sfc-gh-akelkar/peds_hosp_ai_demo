-- ========================================================================
-- Healthcare Demo - Step 2: Cortex Search Components Setup  
-- Creates document parsing and search services for unstructured data
-- Prerequisites: Run 01_healthcare_data_setup.sql first
-- ========================================================================

-- Switch to the healthcare demo role and database
USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE PEDIATRIC_HOSPITAL_AI_DEMO;
USE SCHEMA CLINICAL_SCHEMA;
USE WAREHOUSE PEDIATRIC_HOSPITAL_DEMO_WH;

-- ========================================================================
-- CORTEX SEARCH SERVICES FOR HEALTHCARE DOCUMENTS
-- ========================================================================

-- Create table for healthcare documents with embedded content
CREATE OR REPLACE TABLE healthcare_documents (
    document_id VARCHAR(100) PRIMARY KEY,
    relative_path VARCHAR(500),
    title VARCHAR(200),
    category VARCHAR(50),
    content TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Create search service for clinical documents
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_CLINICAL_DOCS
    ON content
    ATTRIBUTES document_id, relative_path, title, category
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            document_id,
            relative_path,
            title,
            category,
            content
        FROM healthcare_documents
        WHERE category = 'clinical'
    );

-- Create search service for operational documents
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_OPERATIONS_DOCS
    ON content
    ATTRIBUTES document_id, relative_path, title, category
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            document_id,
            relative_path,
            title,
            category,
            content
        FROM healthcare_documents
        WHERE category = 'operations'
    );

-- Create search service for research documents
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_RESEARCH_DOCS
    ON content
    ATTRIBUTES document_id, relative_path, title, category
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            document_id,
            relative_path,
            title,
            category,
            content
        FROM healthcare_documents
        WHERE category = 'research'
    );

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Show all Cortex Search services
SHOW CORTEX SEARCH SERVICES;

-- Verify healthcare documents loaded
SELECT 
    'Healthcare Documents' as component,
    COUNT(*) as total_documents,
    LISTAGG(DISTINCT category, ', ') as categories
FROM healthcare_documents;

-- Show documents by category
SELECT 
    category,
    COUNT(*) as document_count,
    LISTAGG(title, ', ') as document_titles
FROM healthcare_documents 
GROUP BY category
ORDER BY category;

-- Test search services with embedded documents
-- Uncomment these queries to test your search services:

/*
-- Test clinical documents search
SELECT 
    document_id,
    title,
    category,
    relative_path
FROM TABLE(
    SEARCH_CLINICAL_DOCS(
        'pediatric asthma treatment protocol',
        {'limit': 3}
    )
);

-- Test operations documents search  
SELECT 
    document_id,
    title,
    category,
    relative_path
FROM TABLE(
    SEARCH_OPERATIONS_DOCS(
        'HIPAA compliance policy training',
        {'limit': 3}
    )
);

-- Test research documents search
SELECT 
    document_id,
    title,
    category,
    relative_path
FROM TABLE(
    SEARCH_RESEARCH_DOCS(
        'population health chronic disease management',
        {'limit': 3}
    )
);
*/

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT '✅ Step 2 Complete: Cortex Search services created successfully!' as status;
SELECT 'Next: Run 02a_healthcare_documents_data.sql to load sample documents' as next_step;
SELECT 'Then: Run 03_semantic_views_setup.sql' as final_step;

-- ========================================================================
-- SIMPLIFIED DOCUMENT APPROACH
-- ========================================================================

/*
📋 SIMPLIFIED CORTEX SEARCH SETUP:

This approach uses embedded document content directly in tables instead of 
file uploads, making the demo completely self-contained:

✅ BENEFITS:
• No file upload requirements - documents embedded in SQL
• Immediate availability - no stage setup needed
• Self-contained demo - all content included
• Easier to run and demonstrate
• Version controlled document content

📊 DOCUMENT STRUCTURE:
• healthcare_documents table with embedded content
• 6 sample documents across 3 categories:
  - Clinical: Asthma care protocol, Emergency guidelines
  - Operations: HIPAA policy, Quality improvement procedures  
  - Research: Population health study, Clinical trial protocol

🔍 SEARCH SERVICES:
• SEARCH_CLINICAL_DOCS - Clinical protocols and care guidelines
• SEARCH_OPERATIONS_DOCS - HIPAA policies and operational procedures
• SEARCH_RESEARCH_DOCS - Research studies and trial documentation

📋 NEXT STEPS:
1. Run 02a_healthcare_documents_data.sql to load sample documents
2. Run 03_semantic_views_setup.sql to create semantic views
3. Run 04_agent_setup.sql to configure the AI agent
4. Test search services with provided example queries

💡 ADDING MORE DOCUMENTS:
To add additional documents, simply INSERT more rows into the 
healthcare_documents table with appropriate category and content.

Example:
INSERT INTO healthcare_documents VALUES
('CLINICAL_003', 'path/to/new_protocol.md', 'New Clinical Protocol', 'clinical',
'Document content here...', CURRENT_TIMESTAMP());

Then refresh the search services to index new content.
*/
