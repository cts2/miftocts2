<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6 files to a CTS2 rendering
  -     Association conversion package
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core" xmlns:entity="http://www.omg.org/spec/CTS2/1.1/Entity"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="mif xs hl7 cts2f">

    <xsl:import href="CTS2Functions.xslt"/>

    <!-- Associations are embedded in the releasedVersion/concept nodes under mif:codeSystem -->
    <xsl:template match="mif:codeSystem" mode="cts2association">
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystemId)"/>
        <xsl:for-each select="mif:releasedVersion">
            <!-- TODO determine behavior when more than one version exists -->
            <xsl:apply-templates mode="cts2association">
                <xsl:with-param name="codeSystem" select="$codeSystem"/>
                <xsl:with-param name="releaseDate" select="@releaseDate"/>
                <xsl:with-param name="publisherVersionId" select="@publisherVersionId"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>


    <xsl:variable name="knownRelations" as="xs:string+" 
        select="('Specializes', 'Generalizes', 'ClassifiesClassCode', 'ComponentOf', 'MayBeQualifiedBy', 'OwningSubSection', 
        'OwningSection', 'OwningAffiliate', 'SmallerThan')"/>
    
    <!-- Properties are handled in the concept (EntityDescription) section -->
    <xsl:template match="mif:supportedLanguage|mif:supportedConceptProperty" mode="cts2association"/>
    <xsl:template match="mif:supportedConceptRelationship" mode="cts2association">
         <xsl:if test="not(@name = $knownRelations)">
             <xsl:message select="concat('Unknown relationship name: ',@name)"/>
         </xsl:if>
    </xsl:template>

    <xsl:template match="mif:concept" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates" mode="cts2association">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <xsl:param name="releaseDate"/>
        <xsl:param name="publisherVersionId"/>

        <xsl:if test="mif:conceptRelationship">
            <xsl:variable name="codeMapEntry" select="cts2f:codeMapEntry($codeSystem/@oid,../@releaseDate,mif:code[1]/@code)"/>
            <xsl:variable name="uri" select="cts2f:uri($codeSystem/@oid, $codeMapEntry/@prefcode)"/>

            <xsl:for-each select="mif:conceptRelationship">
                <xsl:variable name="targetMapEntry">
                    <xsl:choose>
                        <xsl:when test="mif:targetConcept/@codeSystem">
                            <xsl:copy-of select="cts2f:codeMapEntryRef(mif:targetConcept/@codeSystem,mif:targetConcept/@code)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="cts2f:codeMapEntry($codeSystem/@oid,../../@releaseDate,mif:targetConcept/@code)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="mif:targetConcept/@code=$targetMapEntry/cts2f:concept/@prefcode">
                        <!-- TMP -->
                        <xsl:if test="@relationshipName != 'Specializes'">
                            <member>
                                <upd:association associationID="{$uri}/A{count(preceding-sibling::node())}" xmlns="http://www.omg.org/spec/CTS2/1.1/Association">
                                    <subject uri="{$uri}">
                                        <core:namespace>
                                            <xsl:value-of select="$codeSystem/@name"/>
                                        </core:namespace>
                                        <core:name>
                                            <xsl:value-of select="$codeMapEntry/@prefcode"/>
                                        </core:name>
                                    </subject>
                                    <xsl:choose>
                                        <xsl:when test="@relationshipName='Specializes'">
                                            <predicate uri="http://www.w3.org/2004/02/skos/core#broaderTransitive">
                                                <core:namespace>skos</core:namespace>
                                                <core:name>broaderTransitive</core:name>
                                            </predicate>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <predicate uri="http://hl7.org/owl/vocab/uv/cs/CR#{@relationshipName}">
                                                <core:namespace>CR</core:namespace>
                                                <core:name><xsl:value-of select="@relationshipName"/></core:name>
                                            </predicate>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <target>
                                        <xsl:choose>
                                            <xsl:when test="mif:targetConcept/@codeSystem">
                                                <entity xmlns="http://www.omg.org/spec/CTS2/1.1/Core" uri="{cts2f:uri(mif:targetConcept/@codeSystem, mif:targetConcept/@code)}">
                                                    <core:namespace>
                                                        <xsl:value-of select="cts2f:oidToCodeSystem(mif:targetConcept/@codeSystem)/@name"/>
                                                    </core:namespace>
                                                    <core:name>
                                                        <xsl:value-of select="mif:targetConcept/@code"/>
                                                    </core:name>
                                                </entity>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <entity xmlns="http://www.omg.org/spec/CTS2/1.1/Core" uri="{cts2f:uri($codeSystem/@oid, mif:targetConcept/@code)}">
                                                    <core:namespace>
                                                        <xsl:value-of select="$codeSystem/@name"/>
                                                    </core:namespace>
                                                    <core:name>
                                                        <xsl:value-of select="mif:targetConcept/@code"/>
                                                    </core:name>
                                                </entity>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </target>
                                    <xsl:variable name="vers" select="cts2f:getversion($releaseDate, $publisherVersionId)"/>
                                    <assertedBy xmlns="http://www.omg.org/spec/CTS2/1.1/Association">
                                        <core:version uri="{$codeSystem/@baseUri}/version/{$vers}">
                                            <xsl:value-of select="concat($codeSystem/@name,'-',$vers)"/>
                                        </core:version>
                                        <core:codeSystem uri="{$codeSystem/@baseUri}">
                                            <xsl:value-of select="$codeSystem/@name"/>
                                        </core:codeSystem>
                                    </assertedBy>
                                </upd:association>
                            </member>
                        </xsl:if>
                    </xsl:when>
                    <!-- If this isn't the preferred code, but one exists, just drop it -->
                    <xsl:when test="../mif:conceptRelationship[mif:targetConcept/@code = $targetMapEntry/cts2f:concept/@prefcode]"/>
                    <!-- Otherwise, whine -->
                    <xsl:otherwise>
                        <xsl:message select="concat('Only alternate parent has been named in relationship: ', mif:targetConcept/@code)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
