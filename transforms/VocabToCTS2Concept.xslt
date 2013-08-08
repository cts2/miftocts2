<?xml version="1.0" encoding="UTF-8"?>
    <!--
  - Converts MIF 2.1.6 VocabularyModeluriSubstitutions files to a CTS2 rendering
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" 
    xmlns:hl7="urn:hl7-org:xslt:functions" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" 
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" 
    xmlns:entity="http://www.omg.org/spec/CTS2/1.1/Entity"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="mif xs hl7 cts2f">

    <xsl:import href="CTS2Functions.xslt"/>
    
    <xsl:template match="mif:codeSystem" mode="cts2concept">
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystemId)"/>
        <xsl:for-each select="mif:releasedVersion">
            <xsl:apply-templates mode="cts2concept">
                <xsl:with-param name="codeSystem" select="$codeSystem"/>
                <xsl:with-param name="releaseDate" select="@releaseDate"/>
                <xsl:with-param name="publisherVersionId" select="@publisherVersionId"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="mif:supportedConceptRelationship" mode="cts2concept"/>

    <xsl:template match="mif:supportedLanguage|mif:supportedConceptProperty" mode="cts2concept">
        <!-- TODO: decide what to do with these -->
    </xsl:template>

    <xsl:template match="mif:concept" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates" mode="cts2concept">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <xsl:param name="releaseDate"/>
        <xsl:param name="publisherVersionId"/>

        <xsl:variable name="uri">
            <xsl:choose>
                <xsl:when test="mif:code[@status='active']">
                    <xsl:value-of select="concat($codeSystem/@baseUri,'/Concept#',encode-for-uri(mif:code[@status='active'][1]/@code))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($codeSystem/@baseUri,'/Concept#',encode-for-uri(mif:code[1]/@code))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="doc" select="cts2f:parseDocumentation(mif:annotations)"/>
        <member>
            <upd:entityDescription xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">

                <namedEntity about="{$uri}">
                    <xsl:for-each select="mif:conceptProperty[@name='status']">
                        <xsl:if test="@value='retired'">
                            <xsl:attribute name="entryState">INACTIVE</xsl:attribute>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:choose>
                        <xsl:when test="mif:code[@status='active']">
                            <xsl:for-each select="mif:code[@status='active']">
                                <xsl:choose>
                                    <xsl:when test="position()=1">
                                        <entityID>
                                            <core:namespace>
                                                <xsl:value-of select="$codeSystem/@name"/>
                                            </core:namespace>
                                            <core:name>
                                                <xsl:value-of select="@code"/>
                                            </core:name>
                                        </entityID>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <alternateEntityID>
                                            <core:namespace><xsl:value-of select="$codeSystem/@name"/></core:namespace>
                                            <core:name>
                                                <xsl:value-of select="@code"/>
                                            </core:name>
                                        </alternateEntityID>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <entityID>
                                <core:namespace>
                                    <xsl:value-of select="$codeSystem/@name"/>
                                </core:namespace>
                                <core:name>
                                    <xsl:value-of select="mif:code[1]/@code"/>
                                </core:name>
                            </entityID>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="mif:conceptProperty[@name='internalId']">
                        <alternateEntityID>
                            <core:namespace>internalId</core:namespace>
                            <core:name>
                                <xsl:value-of select="@value"/>
                            </core:name>
                        </alternateEntityID>
                    </xsl:for-each>
                    <describingCodeSystemVersion>
                        <core:version uri="{$codeSystem/@baseUri}/{$releaseDate}">
                            <xsl:value-of select="concat($codeSystem/@name,'-',$releaseDate)"/>
                        </core:version>
                        <core:codeSystem uri="{$codeSystem/@baseUri}">
                            <xsl:value-of select="$codeSystem/@name"/>
                        </core:codeSystem>
                    </describingCodeSystemVersion>
                    <xsl:choose>
                        <xsl:when test="mif:printName">
                            <xsl:for-each select="mif:printName">
                                <designation>
                                    <xsl:attribute name="designationRole">
                                        <xsl:choose>
                                            <xsl:when test="@preferredForLanguage='true'">PREFERRED</xsl:when>
                                            <xsl:otherwise>ALTERNATIVE</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <core:value>
                                        <xsl:value-of select="@text"/>
                                    </core:value>
                                    <core:language uri="http://www.omg.org/spec/LNG#{@language}">
                                        <xsl:value-of select="@language"/>
                                    </core:language>
                                </designation>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="mif:code[@status='active']">
                                <designation designationRole="ALTERNATIVE">
                                    <core:value>
                                        <xsl:value-of select="@code"/>
                                    </core:value>
                                </designation>
                            </xsl:for-each>
                            <xsl:if test="not(mif:code[@status='active'])">
                                <designation designationRole="HIDDEN">
                                    <core:value>
                                        <xsl:value-of select="mif:code[1]/@code"/>
                                    </core:value>
                                </designation>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="$doc/entity:definition">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                    <xsl:for-each select="$doc/entity:example">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>

                    <xsl:for-each select="$doc/entity:note">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                      

                    <xsl:for-each select="mif:conceptProperty">
                        <xsl:choose>
                            <xsl:when test="@name='internalId'"/>
                            <xsl:when test="@name='status'"/>
                            <xsl:otherwise>
                                <entity:property xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                                    <predicate uri="{$uvVocabIriBase}/pr/{encode-for-uri(@name)}">
                                        <namespace>pr</namespace>
                                        <name>
                                            <xsl:value-of select="@name"/>
                                        </name>
                                    </predicate>
                                    <value>
                                        <literal>
                                            <value>
                                                <xsl:value-of select="@value"/>
                                            </value>
                                        </literal>
                                    </value>
                                </entity:property>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    
                    <xsl:apply-templates select="mif:conceptRelationship" mode="cts2concept">
                        <xsl:with-param name="codeSystem" select="$codeSystem"/>
                    </xsl:apply-templates>
                    
                    <entityType uri="http://www.w3.org/2004/02/skos/core#Concept">
                        <core:namespace>skos</core:namespace>
                        <core:name>Concept</core:name>
                    </entityType>
                </namedEntity>
            </upd:entityDescription>
        </member>
    </xsl:template>
    
    <xsl:template match="mif:conceptRelationship" mode="cts2concept" xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <parent uri="{$codeSystem/@baseUri}/Concept#{mif:targetConcept/@code}">
            <core:namespace><xsl:value-of select="$codeSystem/@name"/></core:namespace>
            <core:name><xsl:value-of select="mif:targetConcept/@code"/></core:name>
            <core:designation>
                <xsl:value-of select="cts2f:prefNameFor($codeSystem/@oid, mif:targetConcept/@code)"/>
            </core:designation>
        </parent>
    </xsl:template>
</xsl:stylesheet>
