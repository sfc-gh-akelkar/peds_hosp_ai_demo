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
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_CLINICAL_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
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
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_OPERATIONS_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
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
CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH_RESEARCH_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = PEDIATRIC_HOSPITAL_DEMO_WH
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
-- VERIFICATION
-- ========================================================================

-- Show all Cortex Search services
SHOW CORTEX SEARCH SERVICES;

-- Verify document parsing results
SELECT 
    'Parsed Documents' as component,
    COUNT(*) as count,
    LISTAGG(DISTINCT SPLIT_PART(relative_path, '/', 2), ', ') as document_types
FROM parsed_healthcare_documents;

-- Test search services (if documents are available)
-- Uncomment and modify these queries to test your search services:

/*
-- Test clinical documents search
SELECT * FROM TABLE(
    SEARCH_CLINICAL_DOCS(
        'pediatric asthma treatment protocol',
        {'limit': 3}
    )
);

-- Test operations documents search  
SELECT * FROM TABLE(
    SEARCH_OPERATIONS_DOCS(
        'HIPAA compliance policy',
        {'limit': 3}
    )
);

-- Test research documents search
SELECT * FROM TABLE(
    SEARCH_RESEARCH_DOCS(
        'population health study Northwestern',
        {'limit': 3}
    )
);
*/

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT '✅ Step 2 Complete: Cortex Search services created successfully!' as status;
SELECT 'Next: Run 03_semantic_views_setup.sql' as next_step;

-- ========================================================================
-- NOTES FOR DOCUMENT LOADING
-- ========================================================================

/*
📋 DOCUMENT LOADING INSTRUCTIONS:

To load your healthcare documents into the search services:

1. Upload your documents to the INTERNAL_HEALTHCARE_STAGE:
   PUT file://path/to/your/documents/* @INTERNAL_HEALTHCARE_STAGE/unstructured_docs/

2. Organize documents in subdirectories:
   - unstructured_docs/clinical/     (Clinical protocols, care guidelines)
   - unstructured_docs/operations/   (HIPAA policies, operational procedures)  
   - unstructured_docs/research/     (Research studies, IRB documents)

3. Supported document types:
   - Markdown (.md)
   - PDF files (.pdf) 
   - Word documents (.docx)
   - PowerPoint presentations (.pptx)

4. After uploading, refresh the stage and re-run the search service creation:
   ALTER STAGE INTERNAL_HEALTHCARE_STAGE REFRESH;

5. The search services will automatically index the documents for semantic search.

Example document structure:
📁 unstructured_docs/
├── 📁 clinical/
│   ├── Pediatric_Asthma_Care_Protocol.md
│   ├── Emergency_Treatment_Guidelines.pdf
│   └── Clinical_Decision_Support_Tools.docx
├── 📁 operations/
│   ├── HIPAA_Compliance_Policy.md
│   ├── Quality_Improvement_Procedures.pdf
│   └── Patient_Safety_Protocols.docx
└── 📁 research/
    ├── Population_Health_Research_Study.md
    ├── IRB_Protocol_Template.pdf
    └── Research_Collaboration_Agreement.docx
*/
