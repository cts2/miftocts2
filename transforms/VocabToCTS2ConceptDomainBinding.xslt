<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Convert MIF 2.1.6 context bindings to CTS2 ConceptDomainBinding
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" 
    xmlns:hl7="urn:hl7-org:xslt:functions" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" 
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" 
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs hl7 cts2f">
    
    <xsl:import href="CTS2Functions.xslt"/>
    <!-- ContextBinding
            attributes:
                conceptDomain    - reference to the concept domain
                bindingRealmName - name of the binding realm - from hl7Realm code system
                bindingPriority  - (UNUSED)
                effectiveDate    - date that the binding takes effect
                expiryDate       - (UNUSED)
                valueSet         - (NOT In SCHEMA) oid of bound value set
                codingStrength   - (NOT IN SCHEMA) from VocabularyDomainQualifier code system
            elements:
                valueSetAssertion - (UNUSED)
    -->    
    <xsl:template match="mif:contextBinding" mode="cts2conceptDomainBinding" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:variable name="vs" select="$uriSubstitutions[@type='vs' and @oid=current()/@valueSet]"/>
        <xsl:if test="@bindingPriority|@expiryDate|mif:valueSetAssertion">
            <xsl:message terminate="yes">Unexpected field in contextBinding for <xsl:value-of select="@conceptDomain"/></xsl:message>
        </xsl:if>
        <!-- TODO: figure out what to do with effectiveDate
                   update for valueSetAssertion once it gets used
        -->
        <member>
            <upd:conceptDomainBinding xmlns="http://www.omg.org/spec/CTS2/1.1/ConceptDomainBinding">
                <bindingURI>
                    <xsl:value-of select="concat($uvVocabIriBase,'/cdb/',@conceptDomain,'-',count(preceding-sibling::node()[@conceptDomain=current/@conceptDomain])+1)"/>
                </bindingURI>
                <bindingFor uri="{$uvVocabIriBase}/cd/{encode-for-uri(@conceptDomain)}"><xsl:value-of select="@conceptDomain"/></bindingFor>
                <boundValueSet uri="{$vs/@baseUri}"><xsl:value-of select="$vs/@name"/></boundValueSet>
                <applicableContext uri="{$uvVocabIriBase}/cs/hl7Realm/Concept#{@bindingRealmName}">
                    <xsl:value-of select="@bindingRealmName"/>
                </applicableContext>
                <bindingQualifier uri="{$uvVocabIriBase}/cs/VocabularyDomainQualifier/Concept#{@codingStrength}">
                    <xsl:value-of select="@codingStrength"/>
                </bindingQualifier>
            </upd:conceptDomainBinding>
        </member>
    </xsl:template>
</xsl:stylesheet>