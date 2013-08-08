<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 code systems to CTS2 CodeSystemCatalogEntry
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
      Code Systems - CTS2
         attributes:
             name          - becomes the code system name
             title         - if present becomes the formal name
             codeSystemId  - code system oid. Becomes an alternate identifier
             primaryRealm  - UNUSED 
             codeSystemNamespaceId - UNUSED
         elements:
             businessName - UNUSED
             header       - general metadata
                 attributes:
                   primaryRepository - UNUSED
                 elements:
                   renderingInformation - UNUSED
                   legalese - 
                      attributes: 
                         copyrightOwner - UNUSED
                         copyrightYears - UNUSED
                       elements:
                           notation - details about copyright assertion
                           disclaimer - UNUSED
                           licenseTerms -
                           versioningPolicy - 
                  responsibleGroup - @groupId/@groupName/@organizationName/email
                  contributor - role/name/affiliation/email/notes
                  supplementInformation - UNUSED
                           
             annotations  - map to CTS2 annotation types
             supportedRelationship -
             supportedProperty -
             supportedRepresentation -
             supportedLanguage
    - ======================================================================-->
    <xsl:template match="mif:codeSystem" mode="cts2codeSystem" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystemId)"/>
        <xsl:if test="@primaryRealm|@codeSystemNamespaceId">
            <xsl:message terminate="yes">Unexpected attributes in codeSystem <xsl:value-of select="@name"/></xsl:message>
        </xsl:if>

        <member>
            <upd:codeSystem codeSystemName="{@name}" about="{$codeSystem/@baseUri}" xmlns="http://www.omg.org/spec/CTS2/1.1/CodeSystem">
                <xsl:if test="@title">
                    <xsl:attribute name="formalName" select="@title"/>
                </xsl:if>
                <xsl:if test="mif:annotations/mif:appInfo/mif:deprecationInfo">
                    <xsl:attribute name="entryState">INACTIVE</xsl:attribute>
                </xsl:if>
                <core:keyword>HL7</core:keyword>
                <core:keyword><xsl:value-of select="@name"/></core:keyword>
                <core:resourceType uri="http://www.w3.org/2004/02/skos/core#ConceptScheme">
                    <core:namespace>skos</core:namespace>
                    <core:name>ConceptScheme</core:name>
                </core:resourceType>
                <xsl:if test="mif:annotations/*[name() != 'documentation' and name() != 'appInfo']|mif:annotations/mif:documentation/*[name() != 'description']|mif:annotations/mif:documentation/mif:description/*[name()!='text']">
                    <xsl:message terminate="yes">Unrecognized elements in annotations on code system: <xsl:value-of select="@name"/></xsl:message>
                </xsl:if>
                <xsl:variable name="descs" select="cts2f:parseCodeSystemDocumentation(mif:annotations)"/>
                <xsl:for-each select="$descs/core:resourceSynopsis">
                    <xsl:copy-of select="."/>
                </xsl:for-each>

                <xsl:apply-templates select="mif:header" mode="cts2codeSystem1"/>
                <xsl:for-each select="$descs/core:note">
                    <xsl:copy-of select="."/>
                </xsl:for-each>
                <xsl:apply-templates select="mif:annotations/mif:appInfo/mif:deprecationInfo" mode="cts2codeSystem"/>
                <xsl:apply-templates select="mif:header" mode="cts2codeSystem2"/>
            </upd:codeSystem>
        </member>
    </xsl:template>
    
    <xsl:template match="mif:deprecationInfo" mode="cts2codeSystem">
        <core:note type="EditorialNote">
            <core:value xmlns="urn:hl7-org:v3/mif2">
                <xsl:copy-of select="mif:text"/>
                <xsl:if test="@deprecationEffectiveVersion">
                    <xsl:value-of select="concat(' (',@deprecationEffectiveVersion,')')"/>
                </xsl:if>
            </core:value>
        </core:note>
    </xsl:template>
    
    <xsl:template match="mif:header" mode="cts2codeSystem1">
        <xsl:if test="@primaryRepository|mif:renderingInformation|mif:supplementInformation">
            <xsl:message terminate="yes">Unexpected attributes in codeSystem header <xsl:value-of select="../@name"/></xsl:message>
        </xsl:if>
        <xsl:for-each select="mif:responsibleGroup">
            <core:sourceAndRole>
                <core:source><xsl:value-of select="@organizationName"/></core:source>
                <core:role uri="http://purl.org/dc/terms/1.1/publisher">publisher</core:role>
            </core:sourceAndRole>
        </xsl:for-each>
        <xsl:for-each select="mif:contributor">
            <core:sourceAndRole>
                <core:source>
                    <xsl:choose>
                        <xsl:when test="mif:name/@name='(See notes)'">
                            <xsl:value-of select="mif:notes"/>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="mif:name/@name"/></xsl:otherwise>
                    </xsl:choose>
                </core:source>
                <!-- TODO find HL7 role sets and map to dcterms -->
                <core:role uri=""><xsl:value-of select="mif:role"/></core:role>
            </core:sourceAndRole>
        </xsl:for-each>
        <xsl:for-each select="mif:legalese/mif:licenseTerms">
            <core:rights>
                <core:value xmlns="urn:hl7-org:v3/mif2">
                    <xsl:copy-of select="*|text()"/>
                </core:value>
            </core:rights>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="mif:header" mode="cts2codeSystem2">
        <core:alternateID>urn:oid:<xsl:value-of select="../@codeSystemId"/></core:alternateID>
        <xsl:for-each select="mif:legalese/mif:versioningPolicy">
            <core:releaseDocumentation>
                <core:value xmlns="urn:hl7-org:v3/mif2">
                    <xsl:copy-of select="*|text()"/>
                </core:value>
            </core:releaseDocumentation>
        </xsl:for-each>
        <xsl:for-each select="mif:legalese/mif:notation">
            <core:releaseFormat>
                <core:sourceAndNotationDescription xmlns="urn:hl7-org:v3/mif2">
                    <xsl:copy-of select="*|text()"/>
                </core:sourceAndNotationDescription>
            </core:releaseFormat>
        </xsl:for-each>

    </xsl:template>
    

</xsl:stylesheet>