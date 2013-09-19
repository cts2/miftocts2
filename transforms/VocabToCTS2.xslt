<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 files to a CTS2 rendering
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pkg="http://expath.org/ns/pkg" xmlns:impl="urn:x-xspec:compile:xslt:impl"
    exclude-result-prefixes="xs hl7 cts2f pkg impl">

    <xsl:import href="../../hl7owl/transforms/VocabToOWL.xslt"/>

    <xsl:import href="CTS2Functions.xslt"/>

    <xsl:import href="VocabToCTS2ConceptDomain.xslt"/>

    <xsl:import href="VocabToCTS2ConceptDomainBinding.xslt"/>

    <xsl:import href="VocabToCTS2Concept.xslt"/>

    <xsl:import href="VocabToCTS2Association.xslt"/>

    <xsl:import href="VocabToCTS2ValueSet.xslt"/>

    <xsl:import href="VocabToCTS2ValueSetDefinition.xslt"/>

    <xsl:import href="VocabToCTS2CodeSystem.xslt"/>
    
    <xsl:import href="VocabToCTS2CodeSystemVersion.xslt"/>
    
    
    <!-- Embed comments in output.  Have to switch off for unit tests -->
    <xsl:param name="comments" as="xs:boolean" select="true()"/>
    

    <xsl:strip-space elements="*"/>


    <xsl:param name="owlOrCTS2" as="xs:string" select="'CTS2'">
        <!-- owl - generate OWL output, CTS2 - generate CTS2 -->
    </xsl:param>

    <xsl:param name="doCTS2CodeSystem" as="xs:boolean" select="true()"/>
    <xsl:param name="doCTS2CodeSystemVersion" as="xs:boolean" select="true()"/>
    <xsl:param name="doCTS2ConceptDomain" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2ConceptDomainBinding" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2Concept" as="xs:boolean" select="true()"/>
    <xsl:param name="doCTS2Association" as="xs:boolean" select="true()"/>
    <xsl:param name="doCTS2ValueSet" as="xs:boolean" select="true()"/>
    <xsl:param name="doCTS2ValueSetDefinition" as="xs:boolean" select="true()"/>

    <xsl:param name="debugging" as="xs:boolean" select="false()"/>

    <xsl:param name="codesystems" as="xs:string*" select="()"/>

    <!--========================================================================
    -  MAIN - CTS2 code generation
    - ======================================================================-->
    <xsl:template match="/" as="element(upd:ChangeSet)">

        <!-- Build a change set. This is done as a variable to allow the members and entries to be sequenced after the
             creation is complete.
        -->
        <xsl:choose>
            <xsl:when test="$debugging">
                <xsl:call-template name="genChangeSet"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="changeset">
                    <xsl:call-template name="genChangeSet"/>
                </xsl:variable>
                <xsl:apply-templates select="$changeset" mode="sequenceOutput"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="genChangeSet" as="element(upd:ChangeSet)">

        <xsl:for-each select="mif:vocabularyModel">
            <ChangeSet xmlns="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.omg.org/spec/CTS2/1.1/Updates http://informatics.mayo.edu/cts2/spec/CTS2/1.1/updates/Updates.xsd"
                changeSetURI="urn:uuid:{document('http://informatics.mayo.edu/cts2/services/bioportal-rdf/uuid')}" creationDate="{current-dateTime()}">
                <xsl:if test="$doCTS2CodeSystem">
                    <xsl:apply-templates select="mif:codeSystem[cts2f:qualifies(@name)]" mode="cts2codeSystem"/>
                </xsl:if>
                <xsl:if test="$doCTS2CodeSystemVersion">
                    <xsl:apply-templates select="mif:codeSystem[cts2f:qualifies(@name)]" mode="cts2codeSystemVersion"/>
                </xsl:if>
                <xsl:if test="$doCTS2ConceptDomain">
                    <xsl:apply-templates select="mif:conceptDomain[cts2f:qualifies(@name)]" mode="cts2conceptDomain"/>
                </xsl:if>
                <xsl:if test="$doCTS2ConceptDomainBinding">
                    <xsl:apply-templates select="mif:contextBinding" mode="cts2conceptDomainBinding"/>
                </xsl:if>
                <xsl:if test="$doCTS2Concept">
                    <xsl:apply-templates select="mif:codeSystem[cts2f:qualifies(@name)]" mode="cts2concept"/>
                </xsl:if>
                <xsl:if test="$doCTS2Association">
                    <xsl:apply-templates select="mif:codeSystem[cts2f:qualifies(@name)]" mode="cts2association"/>
                </xsl:if>
                <xsl:if test="$doCTS2ValueSet">
                    <xsl:apply-templates select="mif:valueSet" mode="cts2valueset"/>
                </xsl:if>
                <xsl:if test="$doCTS2ValueSetDefinition">
                    <xsl:apply-templates select="mif:valueSet" mode="cts2valuesetdefinition"/>
                </xsl:if>
            </ChangeSet>
        </xsl:for-each>

    </xsl:template>

    <!-- Sequence the various output components in the change set -->
    <xsl:template match="upd:ChangeSet" mode="sequenceOutput" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="sequenceOutput"/>
            <xsl:for-each select="upd:member">
                <member entryOrder="{position()}">
                    <xsl:apply-templates select="@*|node()" mode="sequenceOutput"/>
                </member>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="upd:valueSetDefinition" mode="sequenceOutput" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()[name()!='entry']" mode="sequenceOutput"/>
            <xsl:for-each select="vsd:entry">
                <entry operator="{@operator}" entryOrder="{position()}">
                    <xsl:apply-templates select="node()" mode="sequenceOutput"/>
                </entry>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="@*|node()" mode="sequenceOutput">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="sequenceOutput"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()"/>
    
    <xsl:function name="cts2f:qualifies" as="xs:boolean">
        <xsl:param name="name"/>
        <xsl:value-of select="count($codesystems)=0 or $name=$codesystems"/>
    </xsl:function>

</xsl:stylesheet>
