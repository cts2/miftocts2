<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 VocabularyModeluriSubstitutions files to a CTS2 rendering
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="xs hl7 cts2f">
    
    <xsl:import href="../../hl7owl/transforms/VocabToOWL.xslt"/>
    <xsl:param name="comments"/>

    <!--========================================================================
    -  Concept Domains - CTS2
    -     attributes:
    -         name       - becomes the conceptDomainName
    -         isBindable - UNUSED (parameter that controls HL7 binding rules)
    -     elements:
    -         businessName - UNUSED
    -         annotations  - map to CTS2 annotation types
    -         specializesDomain - add this to the ConceptDomain ontology
    -         statusInfo   - UNUSED
    -         property     - @name/@value
    -         specializedByDomain - UNUSED  (derived in codee system)
    - ======================================================================-->
    <xsl:template match="mif:conceptDomain" mode="cts2conceptDomain" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:if test="mif:businessName|mif:statusInfo|mif:specializedByDomain|@isBindable">
            <xsl:message>Unexpected attribute or parameter in concept domain:<xsl:copy-of select="."/></xsl:message>
        </xsl:if>
        
        <xsl:if test="$useComments">
            <xsl:text>&#x0a;  </xsl:text>
            <xsl:comment select="concat('Concept Domain: ', @name)"/>
            <xsl:text>&#x0a;  </xsl:text>
        </xsl:if>
        
        <member>
            <upd:conceptDomain conceptDomainName="{@name}" about="{$uvVocabIriBase}/cd/{encode-for-uri(@name)}" xmlns="http://www.omg.org/spec/CTS2/1.1/ConceptDomain">
                <core:resourceSynopsis>
                    <core:value xmlns="urn:hl7-org:v3/mif2">
                        <xsl:copy-of select="mif:annotations/mif:documentation/mif:definition/mif:text"/>
                    </core:value>
                </core:resourceSynopsis>
                <xsl:for-each select="mif:annotations/mif:appInfo/*">
                    <core:note type="EditorialNote">
                        <core:value xmlns="urn:hl7-org:v3/mif2"><xsl:copy-of select="."/></core:value>
                    </core:note>
                </xsl:for-each>
                <xsl:for-each select="mif:property">
                    <!-- TODO: figure out the correct URI and namespace for this predicate -->
                    <property xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                        <predicate uri="{$uvVocabIriBase}/pr/{encode-for-uri(@name)}">
                            <namespace>pr</namespace>
                            <name>
                                <xsl:value-of select="@name"/>
                            </name>
                        </predicate>
                        <value>
                            <xsl:choose>
                                <xsl:when test="@name='ConceptualSpaceForClassCode'">
                                    <xsl:variable name="csns" select="substring-before(@value,'.')"/>
                                    <xsl:variable name="code" select="substring-after(@value,'.')"/>
                                    <entity uri="{$uvVocabIriBase}/cs/{encode-for-uri($csns)}/{encode-for-uri($code)}">
                                        <namespace>
                                            <xsl:value-of select="$csns"/>
                                        </namespace>
                                        <name>
                                            <xsl:value-of select="$code"/>
                                        </name>
                                    </entity>
                                </xsl:when>
                                <xsl:otherwise>
                                    <literal>
                                        <value>
                                            <xsl:value-of select="@value"/>
                                        </value>
                                    </literal>
                                </xsl:otherwise>
                            </xsl:choose>
                        </value>
                    </property>
                </xsl:for-each>
                <xsl:for-each select="@isBindable">
                    <property xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                        <predicate uri="{$uvVocabIriBase}/pr/isBindable">
                            <namespace>pr</namespace>
                            <name>
                                <xsl:value-of select="'isBindable'"/>
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
                <!-- TODO: add URIandEntityName to this link -->
                <definingEntity uri="{$uvVocabIriBase}/cd#{encode-for-uri(@name)}"/>
            </upd:conceptDomain>
        </member>
    </xsl:template>
</xsl:stylesheet>
