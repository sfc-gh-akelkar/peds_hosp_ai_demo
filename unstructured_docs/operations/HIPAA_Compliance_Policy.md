# HIPAA Compliance Policy
**Lurie Children's Hospital**  
**Document Version**: 4.1  
**Effective Date**: January 1, 2025  
**Review Date**: December 31, 2025  
**Policy Owner**: Chief Privacy Officer

## Purpose

This policy establishes comprehensive guidelines for protecting Protected Health Information (PHI) and ensuring compliance with the Health Insurance Portability and Accountability Act (HIPAA) Privacy and Security Rules at Lurie Children's Hospital.

## Scope

This policy applies to all:
- Employees, medical staff, volunteers, and contractors
- Business associates and their subcontractors
- Students, residents, and fellows
- Anyone with access to PHI in any format

## Policy Statement

Lurie Children's Hospital is committed to protecting the privacy and security of patient health information while supporting quality patient care, education, research, and healthcare operations. All PHI must be handled in accordance with HIPAA regulations and hospital policies.

## Definitions

**Protected Health Information (PHI)**: Individually identifiable health information transmitted or maintained in any form or medium by a covered entity or business associate.

**Minimum Necessary**: The smallest amount of PHI necessary to accomplish the intended purpose of the use, disclosure, or request.

**Breach**: Unauthorized acquisition, access, use, or disclosure of PHI that compromises the security or privacy of the information.

**Business Associate**: External entities that perform functions or activities on behalf of the hospital involving PHI.

## Privacy Principles

### 1. Patient Rights

**Right to Notice**: Patients receive Notice of Privacy Practices at first encounter and upon request.

**Right to Access**: Patients may inspect and obtain copies of their PHI within 30 days of request.

**Right to Amendment**: Patients may request amendments to their PHI if they believe it is inaccurate or incomplete.

**Right to Restriction**: Patients may request restrictions on uses and disclosures of their PHI.

**Right to Accounting**: Patients may request an accounting of disclosures of their PHI for the past six years.

**Right to Confidential Communications**: Patients may request to receive PHI by alternative means or at alternative locations.

### 2. Permitted Uses and Disclosures

**Treatment**: Providing, coordinating, or managing healthcare and related services.

**Payment**: Activities related to obtaining payment for healthcare services.

**Healthcare Operations**: Quality assessment, credentialing, training, and other operational activities.

**Authorized Disclosures**: When patient provides written authorization.

**Required by Law**: Disclosures mandated by federal, state, or local law.

### 3. Special Situations

**Minors**: Parents/guardians generally have access rights, with exceptions for:
- Confidential mental health services (age 12+)
- Substance abuse treatment (age 12+)
- Reproductive health services (state-specific regulations)
- Court-appointed guardianship situations

**Research**: PHI use requires IRB approval and may require patient authorization or waiver.

**Public Health**: Reporting requirements for communicable diseases, adverse events, and quality measures.

## Security Safeguards

### Administrative Safeguards

**Security Officer**: Designated individual responsible for developing and implementing security policies.

**Access Management**: Procedures for granting, modifying, and terminating access to PHI.

**Workforce Training**: All workforce members receive HIPAA training within 30 days of hire and annually thereafter.

**Incident Response**: Procedures for identifying, responding to, and documenting security incidents.

**Business Associate Agreements**: Written contracts with all business associates handling PHI.

### Physical Safeguards

**Facility Access Controls**: Restricted access to areas containing PHI with badge access and visitor management.

**Workstation Security**: Computers and mobile devices secured with automatic screen locks and encryption.

**Device Controls**: Procedures for disposing of, reusing, and maintaining devices containing PHI.

**Portable Media**: USB drives, laptops, and mobile devices encrypted and password-protected.

### Technical Safeguards

**Access Controls**: Unique user identification, automatic logoff, and role-based access permissions.

**Audit Controls**: Electronic monitoring and reporting of system access and PHI use.

**Integrity**: PHI protected from improper alteration or destruction.

**Transmission Security**: End-to-end encryption for PHI transmitted electronically.

## Snowflake Data Platform Security

### Data Classification
- **Highly Sensitive**: Direct patient identifiers (names, SSN, MRN)
- **Sensitive**: Clinical data, research data, operational metrics
- **Internal**: De-identified datasets, aggregated reports
- **Public**: Published research, general hospital information

### Snowflake-Specific Controls

**Role-Based Access Control (RBAC)**:
- Clinical_Researcher_Role: Access to de-identified research datasets
- Clinical_Provider_Role: Access to patient care data for assigned patients
- Analytics_Role: Access to aggregated operational and quality metrics
- Admin_Role: Full administrative access with enhanced monitoring

**Data Masking and Tokenization**:
- Patient names replaced with study IDs in research datasets
- Social Security Numbers tokenized for analytics
- Dates shifted consistently to preserve temporal relationships
- Geographic data generalized to zip code level

**Audit and Monitoring**:
- All query activity logged with user identification
- Automated alerts for unusual access patterns
- Monthly access reviews by department supervisors
- Annual comprehensive audit of all PHI access

**Secure Data Sharing**:
- Researcher access through secure Snowflake shares
- External collaborations via data clean rooms
- Time-limited access with automatic expiration
- No data download capabilities for most users

## Breach Response Procedures

### Discovery and Assessment (0-24 hours)
1. Immediately contain the breach
2. Assess the scope and nature of PHI involved
3. Notify Privacy Officer and Security Officer
4. Document all actions taken
5. Preserve evidence for investigation

### Investigation (24-72 hours)
1. Conduct thorough investigation of root cause
2. Determine if notification requirements apply
3. Assess risk of harm to patients
4. Develop mitigation strategies
5. Prepare preliminary incident report

### Notification Requirements

**Patients**: Within 60 days if breach affects 500+ individuals or presents significant risk

**HHS**: Within 60 days for breaches affecting 500+ individuals; annually for smaller breaches

**Media**: Within 60 days for breaches affecting 500+ individuals in same state/jurisdiction

**Business Associates**: Immediately upon discovery

### Post-Incident Actions
1. Implement corrective measures
2. Update policies and procedures as needed
3. Provide additional training if required
4. Monitor for future incidents
5. Report to Quality Committee

## Research Data Governance

### Institutional Review Board (IRB) Requirements
- All research involving PHI requires IRB approval
- HIPAA authorization or waiver of authorization required
- Data use agreements for multi-institutional studies
- Annual continuing review for ongoing studies

### Data De-identification Standards
- Expert determination method for complex datasets
- Safe harbor method following 18 HIPAA identifiers
- Statistical disclosure control for small cell counts
- Re-identification risk assessment required

### Research Data in Snowflake
- Separate database instances for research vs. clinical operations
- Time-limited access with automatic expiration
- Enhanced monitoring for research queries
- Collaboration through secure data sharing features

## Training and Awareness

### Initial Training (Required within 30 days)
- HIPAA Privacy and Security Rules overview
- Hospital-specific policies and procedures
- Role-based responsibilities and restrictions
- Incident reporting procedures
- Snowflake platform security features

### Annual Refresher Training
- Policy updates and regulatory changes
- Case studies and lessons learned
- New technology implementations
- Breach prevention strategies

### Specialized Training
- **Researchers**: Additional training on de-identification and data sharing
- **IT Staff**: Technical security controls and monitoring
- **Supervisors**: Access management and incident response
- **Clinical Staff**: Minimum necessary principles and patient rights

## Compliance Monitoring

### Regular Assessments
- Monthly access audits for high-risk areas
- Quarterly risk assessments
- Annual comprehensive HIPAA compliance review
- Penetration testing of technical safeguards

### Key Performance Indicators
- Training completion rates (target: 100%)
- Incident response time (target: <24 hours)
- Unauthorized access attempts (target: 0)
- Patient complaints related to privacy (target: <5 annually)

### Reporting Structure
- Monthly reports to Privacy Committee
- Quarterly reports to Quality Committee
- Annual report to Board of Directors
- Immediate escalation for significant incidents

## Enforcement and Sanctions

### Progressive Discipline
1. **First Violation**: Counseling and additional training
2. **Second Violation**: Written warning and mandatory training
3. **Third Violation**: Suspension and formal review
4. **Severe Violations**: Immediate termination and legal action

### Factors Considered
- Intent and severity of violation
- Patient harm or risk
- Previous violations
- Cooperation with investigation
- Position and access level

## Business Associate Management

### Contract Requirements
- Written agreement addressing all HIPAA requirements
- Specific requirements for Snowflake-based PHI processing
- Incident notification procedures
- Right to audit and monitor compliance
- Termination procedures for non-compliance

### Ongoing Oversight
- Annual compliance attestations
- Regular security assessments
- Incident reporting requirements
- Performance monitoring and reviews

## International Considerations

### Research Collaborations
- Additional privacy laws may apply (GDPR, local regulations)
- Data transfer agreements required
- Enhanced security measures for international data sharing
- Legal review required for all international research

## Contact Information

**Chief Privacy Officer**: Dr. Maria Gonzalez, JD  
Email: privacy@luriechildrens.org  
Phone: (312) 227-6000

**Information Security Officer**: John Smith, CISSP  
Email: security@luriechildrens.org  
Phone: (312) 227-6100

**HIPAA Compliance Hotline**: 1-800-PRIVACY  
Available 24/7 for reporting incidents or concerns

## References

1. Health Insurance Portability and Accountability Act of 1996
2. HIPAA Privacy Rule (45 CFR Part 160 and Part 164, Subparts A and E)
3. HIPAA Security Rule (45 CFR Part 164, Subpart C)
4. HHS Guidance on De-identification of Protected Health Information
5. Snowflake Security and Compliance Documentation

**Document Owner**: Chief Privacy Officer  
**Last Updated**: January 1, 2025  
**Next Review**: December 31, 2025
