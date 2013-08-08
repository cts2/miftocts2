<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 VocabularyModeluriSubstitutions files to a CTS2 rendering
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates"
    xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="mif xs hl7 cts2f">
    
    <xsl:import href="CTS2Functions.xslt"/>
   
    <!--========================================================================
    -  Value Set - CTS2
    -    Attributes:
            id - value set OID      core:alternateID
            isImmutable - workflow... indicates that value set cannot be 'revised'.  Property
            isPostcoordinationProhibited - UNUSED
            name - value set name
            use  - UNUSED
          Elements:
            businessName - UNUSED
            annotations
              documentation
              appInfo
                deprecationInfo - if present, the value set is deprecated.  
                  @deprecationEffectiveVersion
                  text
            statusInfo (0..*) - UNUSED
            version (1..*)
    - ======================================================================-->
    <xsl:template match="mif:valueSet" mode="cts2valueset" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:if test="mif:statusInfo|mif:businessName|mif:annotations/*[name()!='documentation' and name()!='appInfo']|@isPostcoordinationProhibited|@use">
            <xsl:message>Unexpected value set parameter in: <xsl:value-of select="@name"></xsl:value-of></xsl:message>
        </xsl:if>
        <xsl:variable name="maxVersion" as="xs:string" select="$uriSubstitutions[@type='vs' and @oid=current()/@id]/@date"> 
            <!-- Grab the date of the most recent version -->
        </xsl:variable>

        <xsl:variable name="deprecated" select="boolean(mif:annotations/mif:appInfo/mif:deprecationInfo)"/>
        <xsl:variable name="vs" select="encode-for-uri(@name)"/>

 
        <member>
            <xsl:if test="$comments">
                <xsl:text>&#x0a;  </xsl:text>
                <xsl:comment select="concat('Value Set: ', @name)"/>
                <xsl:text>&#x0a;  </xsl:text>
            </xsl:if>
            
            <upd:valueSet valueSetName="{encode-for-uri(@name)}" about="{$vocabIri}/vs/{$vs}"
                xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSet">
                <xsl:if test="$deprecated">
                    <xsl:attribute name="entryState">INACTIVE</xsl:attribute>
                </xsl:if>
                <xsl:if test="mif:annotations/mif:documentation">
                    <resourceSynopsis xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                        <value>
                            <xsl:copy-of select="mif:annotations/mif:documentation/mif:description"/>
                        </value>
                    </resourceSynopsis>
                </xsl:if>

                <xsl:if test="$deprecated">
                    <note xmlns="http://www.omg.org/spec/CTS2/1.1/Core" type="HistoryNote">
                        <value>
                            <xsl:copy-of select="mif:annotations/mif:appInfo/mif:deprecationInfo"/>
                        </value>
                    </note>
                </xsl:if>
                <xsl:if test="@isImmutable">
                    <property xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                        <predicate uri="{$uvVocabIriBase}/pr/{name(@isImmutable)}">
                            <namespace>pr</namespace>
                            <name>
                                <xsl:value-of select="name(@isImmutable)"/>
                            </name>
                        </predicate>
                        <value>
                            <literal>
                                <value>
                                    <xsl:value-of select="@isImmutable"/>
                                </value>
                            </literal>
                        </value>
                    </property>
                </xsl:if>
                <core:alternateID>
                    <xsl:value-of select="concat('urn:oid:',@id)"/>
                </core:alternateID>
                <definitions>definitions</definitions>
                <xsl:if test="not($deprecated)">
                    <currentDefinition>
                        <core:valueSetDefinition uri="{$vocabIri}/vs/{$vs}/{$maxVersion}"
                            href="definition/{$maxVersion}">
                            <xsl:value-of select="concat($vs,'-',$maxVersion)"/>
                        </core:valueSetDefinition>
                    </currentDefinition>
                </xsl:if>

            </upd:valueSet>
        </member>
    </xsl:template>
</xsl:stylesheet>