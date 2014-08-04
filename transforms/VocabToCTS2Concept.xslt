<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" xmlns:entity="http://www.omg.org/spec/CTS2/1.1/Entity"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="mif xs hl7 cts2f xd">
    <xsl:import href="CTS2Functions.xslt"/>

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Converts MIF 2.1.6 files to a CTS2 rendering</xd:b> (c) 2013, Mayo Clinic</xd:p>
            <xd:p><xd:b>Created on:</xd:b> Oct 30, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Harold Solbrig, Mayo Clinic</xd:p>
            <xd:p> This module generates a CTS2 <xd:i>EnitityDescription</xd:i> for each mif <xd:b>concept</xd:b> entry
                in a code system version.</xd:p>
        </xd:desc>
    </xd:doc>

    <xd:doc>
        <xd:desc>
            <xd:p>Entry point for processing concepts. In the MIF, they are contained in code
                    <xd:b>codeSystem/releasedVersion</xd:b> containers. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mif:codeSystem" mode="cts2concept">
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystemId)"/>
        <xsl:for-each select="mif:releasedVersion">
            <xsl:apply-templates mode="cts2concept">
                <xsl:with-param name="codeSystem" select="$codeSystem"/>
                <xsl:with-param name="releaseDate" select="cts2f:getversion(@releaseDate, @publisherVersionId)"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    <!-- Note error in mif "Name: Act:inboundRelationship:ActRelationship" -->
    <xsl:variable name="knownProperties" as="xs:string+"
        select="('Name:Act:inboundRelationship:ActRelationship', 'Name:Act:outboundRelationship:ActRelationship', 
             'Name:Act:participation:Participation', 'Name:ActRelationship:source:Act', 'Name:ActRelationship:target:Act',
             'Name:Class', 'Name:Class', 'Name:Entity:playedRole:Role', 'Name:Entity:scopedRole:Role', 
             'Name:Participation:act:Act', 'Name:Participation:role:Role', 'Name:Role:inboundLink:RoleLink', 
             'Name:Role:outboundLink:RoleLink', 'Name:Role:participation:Participation', 'Name:Role:player:Entity', 
             'Name:Role:scoper:Entity', 'Name:RoleLink:source:Role', 'Name:RoleLink:target:Role', 'OID', 
             'Sort:Act:inboundRelationship:ActRelationship', 'Sort:Act:outboundRelationship:ActRelationship', 
             'Sort:Act:participation:Participation', 'Sort:Entity:playedRole:Role', 'Sort:Entity:scopedRole:Role', 
             'Sort:Role:inboundLink:RoleLink', 'Sort:Role:outboundLink:RoleLink', 'Sort:Role:participation:Participation', 
             'appliesTo', 'conceptStatusQualifier', 'conductible', 'howApplies', 'internalId', 'inverseRelationship', 
             'isDocumentCharacteristic', 'status')"/>
    <!-- supportedRelationships are handled by the association section, although we do pay attention to Specializes and Generalizes 
        to add the parents/ancestors/children/descendants branches -->
    <xsl:template match="mif:supportedConceptRelationship" mode="cts2association"/>
    <xsl:template match="mif:supportedConceptProperty" mode="cts2concept">
        <!-- TODO: Need to gather these into the service description -->
        <xsl:if test="not(@propertyName = $knownProperties)">
            <xsl:message select="concat('Unknown property name: ',@name)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="mif:supportedLanguage" mode="cts2concept">
        <!-- All languages are ok for the time being -->
    </xsl:template>
    <xd:doc>
        <xd:desc>
            <xd:p>Generate an <xd:i>EntityDescription></xd:i> for the supplied concept.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mif:concept" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates" mode="cts2concept">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <xsl:param name="releaseDate"/>
        <xsl:variable name="doc" select="cts2f:parseDocumentation(mif:annotations)"/>
        <xsl:variable name="codeMapEntry"
            select="cts2f:codeMapEntry($codeSystem/@oid,../@releaseDate,mif:code[1]/@code)"/>
        <xsl:variable name="uri" select="cts2f:uri($codeSystem/@oid, $codeMapEntry/@prefcode)"/>
        <member>
            <upd:entityDescription xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
                <namedEntity about="{$uri}">
                    <xsl:for-each select="mif:conceptProperty[@name='status']">
                        <xsl:if test="@value='retired'">
                            <xsl:attribute name="entryState">INACTIVE</xsl:attribute>
                        </xsl:if>
                    </xsl:for-each>
                    <entityID>
                        <core:namespace>
                            <xsl:value-of select="$codeSystem/@name"/>
                        </core:namespace>
                        <core:name>
                            <xsl:value-of select="$codeMapEntry/@prefcode"/>
                        </core:name>
                    </entityID>
                    <xsl:for-each select="$codeMapEntry//mif:code">
                        <xsl:if test="@code != $codeMapEntry/@prefcode">
                            <alternateEntityID>
                                <core:namespace>
                                    <xsl:value-of select="$codeSystem/@name"/>
                                </core:namespace>
                                <core:name>
                                    <xsl:value-of select="@code"/>
                                </core:name>
                            </alternateEntityID>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:for-each select="mif:conceptProperty[@name='internalId']">
                        <alternateEntityID>
                            <core:namespace>internalId</core:namespace>
                            <core:name>
                                <xsl:value-of select="@value"/>
                            </core:name>
                        </alternateEntityID>
                    </xsl:for-each>
                    <describingCodeSystemVersion>
                        <xsl:variable name="vers" select="cts2f:getversion($codeSystem/@date, $codeSystem/@version)"/>
                        <core:version uri="{$codeSystem/@baseUri}/version/{encode-for-uri($vers)}">
                            <xsl:value-of select="concat($codeSystem/@name,'-',$vers)"/>
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
                        <xsl:copy-of select="." xmlns="http://www.omg.org/spec/CTS2/1.1/Entity"/>
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
                        <xsl:with-param name="relDate" select="../@releaseDate"/>
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
        <xsl:param name="relDate"/>
        <xsl:variable name="codeMapEntry"
            select="cts2f:codeMapEntry($codeSystem/@oid, $relDate, mif:targetConcept/@code)"/>
        <xsl:choose>
            <xsl:when test="@relationshipName != 'Specializes'"/>
            <!-- If this IS the preferred code, spit it out -->
            <xsl:when test="mif:targetConcept/@code = $codeMapEntry/@prefcode">
                <xsl:call-template name="outputParent">
                    <xsl:with-param name="codeSystem" select="$codeSystem"/>
                    <xsl:with-param name="targetConcept" select="mif:targetConcept/@code"/>
                </xsl:call-template>
            </xsl:when>
            <!-- If this isn't the preferred code, but one exists, just drop it -->
            <xsl:when test="../mif:conceptRelationship[mif:targetConcept/@code = $codeMapEntry/@prefcode]"/>
            <!-- Otherwise, whine -->
            <xsl:otherwise>
                <xsl:message
                    select="concat('Only alternate parent has been named in relationship: ', mif:targetConcept/@code)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="outputParent" xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <xsl:param name="targetConcept" as="xs:string"/>
        <parent uri="{cts2f:uri($codeSystem/@oid,$targetConcept)}">
            <core:namespace>
                <xsl:value-of select="$codeSystem/@name"/>
            </core:namespace>
            <core:name>
                <xsl:value-of select="$targetConcept"/>
            </core:name>
            <core:designation>
                <xsl:value-of select="cts2f:prefNameFor($codeSystem/@oid, $targetConcept)"/>
            </core:designation>
        </parent>
    </xsl:template>
</xsl:stylesheet>
