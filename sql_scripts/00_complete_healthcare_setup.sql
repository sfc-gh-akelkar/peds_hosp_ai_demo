-- ========================================================================
-- PEDIATRIC HOSPITAL AI DEMO - COMPLETE SETUP
-- Master script that runs all 4 modular setup scripts in sequence
-- ========================================================================

/*
🏥 PEDIATRIC HOSPITAL AI DEMO - MODULAR SETUP

This demo has been organized into 4 focused scripts for better modularity:

📋 **SCRIPT OVERVIEW:**
1. 📊 01_healthcare_data_setup.sql     - Database, tables, sample data
2. 🔍 02_cortex_search_setup.sql       - Document search services  
3. 🧠 03_semantic_views_setup.sql      - Natural language query views
4. 🤖 04_agent_setup.sql               - AI agent and custom functions

📋 **EXECUTION OPTIONS:**

**Option A: Run All Scripts Automatically**
Execute this master script to run all 4 scripts in sequence.

**Option B: Run Scripts Individually** 
Execute each script separately for step-by-step setup:
- Allows for testing and validation at each stage
- Easier troubleshooting if issues arise
- Better understanding of each component

**Option C: Custom Setup**
Run only the scripts you need for your specific demo requirements.
*/

-- ========================================================================
-- OPTION A: AUTOMATED COMPLETE SETUP
-- ========================================================================

/*
-- Uncomment the following lines to run all scripts automatically:

-- Step 1: Data Infrastructure
!source 01_healthcare_data_setup.sql;

-- Step 2: Cortex Search Services
!source 02_cortex_search_setup.sql;

-- Step 3: Semantic Views
!source 03_semantic_views_setup.sql;

-- Step 4: AI Agent Setup
!source 04_agent_setup.sql;

*/

-- ========================================================================
-- MANUAL SETUP INSTRUCTIONS
-- ========================================================================

SELECT '🏥 PEDIATRIC HOSPITAL AI DEMO SETUP' as title;
SELECT '📋 Follow these steps to set up your healthcare demo:' as instructions;

SELECT 
    '1️⃣' as step,
    'Run 01_healthcare_data_setup.sql' as script,
    'Creates database, tables, and sample healthcare data' as description
UNION ALL
SELECT 
    '2️⃣',
    'Run 02_cortex_search_setup.sql',
    'Sets up document search for clinical protocols and policies'
UNION ALL
SELECT 
    '3️⃣',
    'Run 03_semantic_views_setup.sql', 
    'Creates semantic views for natural language queries'
UNION ALL
SELECT 
    '4️⃣',
    'Run 04_agent_setup.sql',
    'Configures AI agent with healthcare-specific capabilities'
UNION ALL
SELECT 
    '🎯',
    'Demo Ready!',
    '15-minute pediatric hospital intelligence demo'
ORDER BY step;

-- ========================================================================
-- PREREQUISITES CHECK
-- ========================================================================

SELECT '🔍 PREREQUISITES CHECK' as check_type;

-- Check if SF_INTELLIGENCE_DEMO role exists
SELECT 
    'SF_INTELLIGENCE_DEMO Role' as requirement,
    CASE 
        WHEN CURRENT_ROLE() = 'SF_INTELLIGENCE_DEMO' 
        THEN '✅ Role is active'
        ELSE '⚠️ Switch to SF_INTELLIGENCE_DEMO role'
    END as status;

-- Check Snowflake Intelligence access
SELECT 
    'Snowflake Intelligence' as requirement,
    '✅ Access through Snowsight UI' as status;

-- ========================================================================
-- MODULAR SETUP BENEFITS
-- ========================================================================

SELECT '🚀 MODULAR SETUP BENEFITS' as benefits;

SELECT 
    '🔧' as icon,
    'Easier Maintenance' as benefit,
    'Each component can be updated independently' as description
UNION ALL
SELECT 
    '🐛',
    'Better Debugging',
    'Isolate issues to specific functional areas'
UNION ALL
SELECT 
    '📚',
    'Learning Focused',
    'Understand each Snowflake Intelligence capability separately'
UNION ALL
SELECT 
    '⚡',
    'Faster Development',
    'Modify or extend specific components without affecting others'
UNION ALL
SELECT 
    '🎯',
    'Demo Flexibility',
    'Choose which components to include in different demo scenarios'
ORDER BY icon;

-- ========================================================================
-- NEXT STEPS
-- ========================================================================

SELECT '🎯 READY TO START YOUR HEALTHCARE DEMO!' as message;
SELECT 'Begin with script 01_healthcare_data_setup.sql' as next_action;
