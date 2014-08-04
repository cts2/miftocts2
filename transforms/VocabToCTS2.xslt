<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pkg="http://expath.org/ns/pkg" xmlns:impl="urn:x-xspec:compile:xslt:impl" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="xs hl7 cts2f pkg impl xd">


    <xsl:import href="../../hl7owl/transforms/SharedHL7ToOWL.xslt"/>

    <xsl:import href="CTS2Functions.xslt"/>

    <xsl:import href="VocabToCTS2ConceptDomain.xslt"/>

    <xsl:import href="VocabToCTS2ConceptDomainBinding.xslt"/>

    <xsl:import href="VocabToCTS2Concept.xslt"/>

    <xsl:import href="VocabToCTS2Association.xslt"/>

    <xsl:import href="VocabToCTS2ValueSet.xslt"/>

    <xsl:import href="VocabToCTS2ValueSetDefinition.xslt"/>

    <xsl:import href="VocabToCTS2CodeSystem.xslt"/>

    <xsl:import href="VocabToCTS2CodeSystemVersion.xslt"/>

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Converts MIF 2.1.6 files to a CTS2 rendering</xd:b> (c) 2013, Mayo Clinic</xd:p>
            <xd:p><xd:b>Created on:</xd:b> Oct 30, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Harold Solbrig, Mayo Clinic</xd:p>
            <xd:p>This package converts the HL7 MIF vocabulary into the Common Terminology Services (CTS2) equivalent. It transforms the followint elements: <xd:ul>
                    <xd:li><xd:b>conceptDomain</xd:b> is mapped to the CTS2 <xd:i>ConceptDomainCatalogEntry</xd:i> structure</xd:li>
                    <xd:li><xd:b>codeSystem</xd:b> maps to four separate CTS2 structures: <xd:ul>
                            <xd:li><xd:i>CodeSystemCatalogEntry</xd:i> - carries the the <xd:b>header</xd:b> and <xd:b>annotations</xd:b> elements</xd:li>
                            <xd:li><xd:i>CodeSystemVersionCatalogEntry</xd:i> - carries the <xd:b>releasedVersion</xd:b> element(s)</xd:li>
                            <xd:li><xd:i>EntityDescription</xd:i> - carries an entry per MIF <xd:b>concept</xd:b></xd:li>
                            <xd:li><xd:i>Association</xd:i> - carries an entry per MIF <xd:b>conceptRelationship</xd:b></xd:li>
                        </xd:ul>
                    </xd:li>
                    <xd:li><xd:b>valueSet</xd:b> generates: <xd:ul>
                            <xd:li><xd:i>ValueSetCatalogEntry</xd:i> - carries the <xd:b>annotations</xd:b> information about the value set itself</xd:li>
                            <xd:li><xd:i>ValueSetDefinition</xd:i> - carries the <xd:b>version</xd:b> element(s)</xd:li>
                        </xd:ul>
                    </xd:li>
                    <xd:li><xd:b>bindingRealm</xd:b></xd:li>
                    <xd:li><xd:b>contextBinding</xd:b> generates <xd:i>ContextDomainBinding</xd:i></xd:li>
                </xd:ul>
            </xd:p>
        </xd:desc>
    </xd:doc>




    <xsl:strip-space elements="*"/>

    <xsl:param name="doCTS2CodeSystem" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2CodeSystemVersion" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2ConceptDomain" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2ConceptDomainBinding" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2Concept" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2Association" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2ValueSet" as="xs:boolean" select="false()"/>
    <xsl:param name="doCTS2ValueSetDefinition" as="xs:boolean" select="false()"/>

    <!-- If the debugging parameter is set to true(), the output is sent directly to the
        target document rather than gathered in a change set.  This allows one to debug
        and inspect problems.
        -->
    <xsl:param name="debugging" as="xs:boolean" select="false()"/>

    <!-- This parameter carries the list of code systems and/or concept domains
        to actually generate.  If empty, all code systems are output -->
    <xsl:param name="codesystems" as="xs:string*" select="()"/>

    <xd:doc>
        <xd:desc>
            <xd:p>Entry point. Creates a set of changes based on the input document and the list of things to build above. The completed change set is then assigned specific sequence numbers before being generated.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/" as="element(upd:ChangeSet)">

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

    <xd:doc>
        <xd:desc>
            <xd:p>Generate a change set from the requested set of elements.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="genChangeSet" as="element(upd:ChangeSet)">

        <xsl:for-each select="mif:vocabularyModel">
            <ChangeSet xmlns="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.omg.org/spec/CTS2/1.1/Updates http://informatics.mayo.edu/cts2/spec/CTS2/1.1/updates/Updates.xsd" changeSetURI="urn:uuid:{document('http://informatics.mayo.edu/cts2/services/bioportal-rdf/uuid')}" creationDate="{current-dateTime()}">
                <xsl:apply-templates select="if ($doCTS2CodeSystem) then mif:codeSystem[cts2f:qualifies(@name)] else ()" mode="cts2codeSystem"/>
                
                <xsl:apply-templates select="if ($doCTS2CodeSystemVersion) then mif:codeSystem[cts2f:qualifies(@name)] else ()" mode="cts2codeSystemVersion"/>
                
                <xsl:apply-templates select="if ($doCTS2ConceptDomain) then mif:conceptDomain[cts2f:qualifies(@name)] else ()" mode="cts2conceptDomain"/>

                <xsl:apply-templates select="if ($doCTS2ConceptDomainBinding) then mif:contextBinding else ()" mode="cts2conceptDomainBinding"/>

                <xsl:apply-templates select="if ($doCTS2Concept) then mif:codeSystem[cts2f:qualifies(@name)] else ()" mode="cts2concept"/>

                <xsl:apply-templates select="if ($doCTS2Association) then mif:codeSystem[cts2f:qualifies(@name)] else ()" mode="cts2association"/>

                <xsl:apply-templates select="if ($doCTS2ValueSet) then mif:valueSet else ()" mode="cts2valueset"/>

                <xsl:apply-templates select="if ($doCTS2ValueSetDefinition) then mif:valueSet else ()" mode="cts2valuesetdefinition"/>

            </ChangeSet>
        </xsl:for-each>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Sequence the <xd:i>members</xd:i> of a change set</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="upd:ChangeSet" as="element(upd:ChangeSet)" mode="sequenceOutput" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="sequenceOutput"/>
            <xsl:for-each select="upd:member">
                <member entryOrder="{position()}">
                    <xsl:apply-templates select="@*|node()" mode="sequenceOutput"/>
                </member>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Sequence the entries in a value set definition.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="upd:valueSetDefinition" as="element(upd:valueSetDefinition)" mode="sequenceOutput" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()[name()!='entry']" mode="sequenceOutput"/>
            <xsl:for-each select="vsd:entry">
                <entry operator="{@operator}" entryOrder="{position()}">
                    <xsl:apply-templates select="node()" mode="sequenceOutput"/>
                </entry>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p>Default identity function for sequencing.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@*|node()" mode="sequenceOutput">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="sequenceOutput"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()"/>

    <xd:doc>
        <xd:desc>
            <xd:p>Determines whether the supplied <xd:i>name</xd:i> is in the list of code systems to be output.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:function name="cts2f:qualifies" as="xs:boolean">
        <!--
        - Determines whether the supplied name is in the list of code systems to be output.
        -->
        <xsl:param name="name" as="xs:string"/>
        <xsl:value-of select="count($codesystems)=0 or $name=$codesystems"/>
    </xsl:function>

</xsl:stylesheet>
