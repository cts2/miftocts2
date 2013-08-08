<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 code systems to CTS2 CodeSystemVersionCatalogEntry
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" 
    xmlns:mif="urn:hl7-org:v3/mif2" 
    xmlns:hl7="urn:hl7-org:xslt:functions"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs hl7 cts2f">
    
    <xsl:import href="CTS2Functions.xslt"/>
    
    <!--========================================================================
      Code System Version - CTS2
        codeSystem/releasedVersion
            attributes:
                releaseDate
                hl7MaintainedIndicator
                completeCodesIndicator
                hl7ApprovedIndicator
                publisherVersionId
            elements:
                supportedLanguage
                supportedConceptRelationship
                supportedConceptProperty
                annotations
                publicTerminologyServer (UNUSED)
                postCoordinationFormat (UNUSED)
                
    - ======================================================================-->
    <xsl:variable name="eprops">
        <prop>supportedConceptRelationship</prop>
        <prop>supportedConceptProperty</prop>
    </xsl:variable>
    
    <xsl:template match="mif:codeSystem" mode="cts2codeSystemVersion" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystemId)"/>
        <xsl:apply-templates select="mif:releasedVersion" mode="cts2codeSystemVersion">
            <xsl:with-param name="codeSystem" select="$codeSystem"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="mif:releasedVersion" mode="cts2codeSystemVersion" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:param name="codeSystem"/>
        <xsl:if test="mif:publicTerminologyServer|mif:postCoordinationFormat">
            <xsl:message terminate="yes">Unexpected element in releasedVersion <xsl:value-of select="@name"/></xsl:message>
        </xsl:if>
        <xsl:variable name="vers">
            <xsl:choose>
                <xsl:when test="@publisherVersionId">
                    <xsl:value-of select="@publisherVersionId"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@releaseDate"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <member >
            <upd:codeSystemVersion codeSystemVersionName="{$codeSystem/@name}-{$vers}" about="{$codeSystem/@baseUri}/version/{encode-for-uri($vers)}" xmlns="http://www.omg.org/spec/CTS2/1.1/CodeSystemVersion">   
                <xsl:for-each select="@*[name()!='publisherVersionId']">
                    <property xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                        <predicate uri="{$uvVocabIriBase}/pr/{name()}">
                            <namespace>pr</namespace>
                            <name>
                                <xsl:value-of select="name()"/>
                            </name>
                        </predicate>
                        <value>
                            <literal>
                                <value>
                                    <xsl:value-of select="."/>
                                </value>
                            </literal>
                        </value>
                    </property>
                </xsl:for-each>
                <xsl:if test="@publisherVersionId">
                    <core:officialResourceVersionId><xsl:value-of select="@publisherVersionId"/></core:officialResourceVersionId>
                </xsl:if>
                <versionOf uri="{$codeSystem/@baseUri}"><xsl:value-of select="$codeSystem/@name"/></versionOf>
                <xsl:for-each select="mif:supportedLanguage">
                    <supportedLanguage uri="http://www.omg.org/spec/LNG#{.}"><xsl:value-of select="."/></supportedLanguage>
                </xsl:for-each>
            </upd:codeSystemVersion>
        </member>
                                
                
    </xsl:template>
    
    
    
</xsl:stylesheet>