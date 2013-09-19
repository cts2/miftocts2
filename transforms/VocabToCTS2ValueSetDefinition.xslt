<?xml version="1.0" encoding="UTF-8"?>
<!--
  - Converts MIF 2.1.6  files to a CTS2 Value Set Definition 
  - (c) 2013, Mayo Clinic
  -->
<xsl:stylesheet version="2.0" xmlns:mif="urn:hl7-org:v3/mif2" xmlns:hl7="urn:hl7-org:xslt:functions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates" xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition" xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="mif xs hl7 cts2f">

    <xsl:import href="CTS2Functions.xslt"/>    
    
    <!--========================================================================
    -  Value Set Definition - CTS2
    - ======================================================================-->
    <!-- valueSet:
            attributes:
                id
                isImmutable
                isPostCoordinationProhibited
                name
                use
            elements:
                businessName
                annotations
                statusInfo
                version - the actual version we deal with
     -->  
    <xsl:template match="mif:valueSet" mode="cts2valuesetdefinition" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">

        <xsl:variable name="maxVersion" as="xs:string" select="$uriSubstitutions[@type='vs' and @oid=current()/@id]/@date"> 
            <!-- Grab the date of the most recent version -->
        </xsl:variable>

        <xsl:variable name="deprecated" select="boolean(mif:annotations/mif:appInfo/mif:deprecationInfo)"/>
        <xsl:variable name="vs" select="encode-for-uri(@name)"/>
        

        <!-- version:
                attributes:
                    versionDate - version identifier part 1
                    versionTime - version identifier part 2 (can be empty)
                elements:
                    usesCodeSystemSupplement - UNUSED
                    usesCodeSystem - (derived) - called "supportedCodeSystem" in XML *UNUSED)
                    supportedCodeSystem - OID of a code system, not really sure what to do with this, however
                    nonSelectableContent - UNUSED
                    enumeratedContent - UNUSED
                    exampleContent - UNUSED
                    supportedLanguage - language code.  Only "en" at the moment, so we ignore...
                    associatedConceptProperty - 
                    content - The meat of the version
          -->
        <xsl:for-each select="mif:version">
            <xsl:if test="mif:usesCodeSystemSupplement|mif:usesCodeSystem|mif:nonSelectableContent|mif:enumeratedContent|mif:exampleContent">
                <xsl:message terminate="yes">Unexpected elements in value set definition <xsl:value-of select="$vs"/></xsl:message>
            </xsl:if>
            <xsl:variable name="definitionId" select="cts2f:definitionId(@versionDate, @versionTime)"/>
            <xsl:if test="$comments">
                 <xsl:text>&#x0a;  </xsl:text>
                 <xsl:comment select="concat('Value Set Version: ', $vs,'-',$definitionId)"/>
                 <xsl:text>&#x0a;  </xsl:text>
            </xsl:if>
            <xsl:apply-templates mode="cts2valuesetdefinition">
                <xsl:with-param name="vs" select="$vs"/>
                <xsl:with-param name="definitionId" select="$definitionId"/>
                <xsl:with-param name="maxVersion" select="$maxVersion"/>
                <xsl:with-param name="deprecated" select="$deprecated"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="mif:content"  mode="cts2valuesetdefinition">
        <xsl:param name="vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        
        <!-- The outermost content is equivalent to combinedContent/unionWithContent if it doesn't have a nested combined -->
        <xsl:variable name="content" as="element(mif:combinedContent)">
            <xsl:choose>
                <xsl:when test="mif:combinedContent">
                    <xsl:copy-of select="*"/>
                </xsl:when>
                <xsl:otherwise>
                    <mif:combinedContent>
                        <mif:unionWithContent codeSystem="{@codeSystem}">
                            <xsl:copy-of select="*"/>
                        </mif:unionWithContent>
                    </mif:combinedContent>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="$content" mode="cts2valuesetdefinition">
                <xsl:with-param name="vs" select="$vs"/>
                <xsl:with-param name="hier_vs" select="$vs"/>
                <xsl:with-param name="definitionId" select="$definitionId"/>
                <xsl:with-param name="maxVersion" select="$maxVersion"/>
                <xsl:with-param name="deprecated" select="$deprecated"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="mif:combinedContent" mode="cts2valuesetdefinition" xmlns="http://www.omg.org/spec/CTS2/1.1/Updates">
        <xsl:param name="vs"/>
        <xsl:param name="hier_vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        <xsl:param name="depth" as="xs:integer" select="0"/>
        
        <member>
            <upd:valueSetDefinition about="{concat($vocabIri,'/vs/',$hier_vs,'/',$definitionId)}" formalName="{$hier_vs}-{$definitionId}" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
                <xsl:if test="$deprecated and substring-before($definitionId,'T') = $maxVersion">
                    <xsl:attribute name="entryState">INACTIVE</xsl:attribute>
                </xsl:if>
                <definedValueSet uri="{concat($vocabIri,'/vs/',$hier_vs)}">
                    <xsl:value-of select="$hier_vs"/>
                </definedValueSet>
                <xsl:apply-templates mode="cts2valuesetdefinitioncontent">
                    <xsl:with-param name="vs" select="$vs"/>
                    <xsl:with-param name="definitionId" select="$definitionId"/>
                    <xsl:with-param name="maxVersion" select="$maxVersion"/>
                    <xsl:with-param name="deprecated" select="$deprecated"/>
                    <xsl:with-param name="depth" select="$depth"/>
                </xsl:apply-templates>
            </upd:valueSetDefinition>
        </member>
        <xsl:for-each select="*/mif:combinedContent">
            <xsl:apply-templates select="." mode="cts2valuesetdefinition">
                <xsl:with-param name="vs" select="$vs"/>
                <xsl:with-param name="hier_vs" select="concat('_',$vs,'_',$depth+1,'_',position())"/>
                <xsl:with-param name="definitionId" select="$definitionId"/>
                <xsl:with-param name="maxVersion" select="$maxVersion"/>
                <xsl:with-param name="deprecated" select="$deprecated"/>
                <xsl:with-param name="depth" select="$depth+1"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="mif:unionWithContent" mode="cts2valuesetdefinitioncontent">
        <xsl:param name="vs"/>
        <xsl:param name="hier_vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        <xsl:param name="depth" as="xs:integer"/>
        
        <xsl:call-template name="doContent">
            <xsl:with-param name="vs" select="$vs"/>
            <xsl:with-param name="hier_vs" select="$vs"/>
            <xsl:with-param name="definitionId" select="$definitionId"/>
            <xsl:with-param name="maxVersion" select="$maxVersion"/>
            <xsl:with-param name="deprecated" select="$deprecated"/>
            <xsl:with-param name="op">UNION</xsl:with-param>
            <xsl:with-param name="depth" select="$depth"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- intersectionWithContent:
            (same as content)
     -->
    <xsl:template match="mif:intersectionWithContent" mode="cts2valuesetdefinitioncontent">
        <xsl:param name="vs"/>
        <xsl:param name="hier_vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        <xsl:param name="depth" as="xs:integer"/>
        
        <xsl:call-template name="doContent">
            <xsl:with-param name="vs" select="$vs"/>
            <xsl:with-param name="hier_vs" select="$vs"/>
            <xsl:with-param name="definitionId" select="$definitionId"/>
            <xsl:with-param name="maxVersion" select="$maxVersion"/>
            <xsl:with-param name="deprecated" select="$deprecated"/>
            <xsl:with-param name="op">INTERSECT</xsl:with-param>
            <xsl:with-param name="depth" select="$depth"/>
        </xsl:call-template>
    </xsl:template>
    
    <!-- intersectionWithContent:
            (same as content)
     -->
    <xsl:template match="mif:excludeContent" mode="cts2valuesetdefinitioncontent">
        <xsl:param name="vs"/>
        <xsl:param name="hier_vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        <xsl:param name="depth" as="xs:integer"/>
        
        <xsl:call-template name="doContent"> 
            <xsl:with-param name="vs" select="$vs"/>
            <xsl:with-param name="hier_vs" select="$vs"/>
            <xsl:with-param name="definitionId" select="$definitionId"/>
            <xsl:with-param name="maxVersion" select="$maxVersion"/>
            <xsl:with-param name="deprecated" select="$deprecated"/>
            <xsl:with-param name="op">SUBTRACT</xsl:with-param>
            <xsl:with-param name="depth" select="$depth"/>
        </xsl:call-template>
    </xsl:template>
    
    
    <!-- unionWithContent/intersectionWithContent/excludeContent - type ContentDefinition.  
        attributes:
            areBaseQualifiersUnlimited - UNUSED
            postCoordinationPreference - UNUSED
            codeSystem - (not in schema) OID of code system
        elements:
            annotations - 
            drawnFromCodeSystem - UNUSED
            usesCodeSystemSupplement - UNUSED
            allowedRepresentation - UNUSED
            allowedQualifiers - UNUSED
            choice:
                (nothing)  - use the entire code system
                combinedContent
                codeBasedContent(1..*)
                propertyBasedContent
                relationshipBasedContent
                codeFilterContent
                nonComputableContent
                valueSetRef
      -->
    <xsl:template name="doContent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:param name="vs"/>
        <xsl:param name="hier_vs"/>
        <xsl:param name="definitionId"/>
        <xsl:param name="maxVersion"/>
        <xsl:param name="deprecated"/>
        <xsl:param name="depth" as="xs:integer"/>
        <xsl:param name="op"/>
        
        <xsl:variable name="codeSystem" select="cts2f:oidToCodeSystem(@codeSystem)"/>
        
        <xsl:choose>
            <!-- No other information supplied, use the entire code system -->
            <xsl:when test="count(*[name() != 'annotations'])=0">
                <entry operator="{$op}" entryOrder="0">
                    <completeCodeSystem>
                        <codeSystem>
                            <xsl:copy-of select="cts2f:cts2CodeSystem($codeSystem/@oid)/@*"/>
                            <xsl:copy-of select="cts2f:cts2CodeSystem($codeSystem/@oid)/node()"/>
                        </codeSystem>
                    </completeCodeSystem>
                </entry>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="cts2valuesetdefinitioncontent">
                    <xsl:with-param name="vs" select="$vs"/>
                    <xsl:with-param name="codeSystem" select="$codeSystem"/>
                    <xsl:with-param name="op" select="$op"/>
                    <xsl:with-param name="depth" as="xs:integer" select="$depth"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>        
    
    <xsl:template match="mif:exampleContent|mif:enumeratedContent|mif:nonSelectableContent|mif:usesCodeSystemSupplement|mif:usesCodeSystem" mode="cts2valuesetdefinition">
        <xsl:message>Unsupported value set version element:<xsl:value-of select="name()"/></xsl:message>
    </xsl:template>
    
    <xsl:template match="mif:supportedCodeSystem" mode="cts2valuesetdefinition"/>
    <xsl:template match="mif:supportedLanguage"  mode="cts2valuesetdefinition"/>
    <xsl:template match="mif:associatedConceptProperty" mode="cts2valuesetdefinition">
        <!-- TODO decide what to do with this... -->
    </xsl:template>

    
    
    <xsl:template match="mif:drawnFromCodeSystem|mif:usesCodeSystemSupplement|mif:allowedRepresentation|mif:allowedQualifiers" mode="cts2valuesetdefinitioncontent">
        <xsl:message>Unsupported value set version  content element:<xsl:value-of select="name()"/></xsl:message>
    </xsl:template>
    
    <xsl:template match="mif:annotations" mode="cts2valuesetdefinitioncontent">
        <!-- TODO decide what to do with this if anything -->
    </xsl:template>

    <xsl:template match="mif:combinedContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:param name="op"/>
        <xsl:param name="depth" as="xs:integer"/>
        <xsl:param name="vs"/>
        
        <xsl:variable name="count" as="xs:integer" select="count(../preceding-sibling::*[mif:combinedContent])+1"/>
        <xsl:variable name="name" select="concat('_',$vs,'_',$depth+1,'_', $count)"/>
        <entry operator="{$op}" entryOrder="0">
            <completeValueSet>
                <valueSet uri="{$vocabIri}/vs/{encode-for-uri($name)}">
                    <xsl:value-of select="$name"/>
                </valueSet>
            </completeValueSet>
        </entry>
        
    </xsl:template>

    <!-- codeBasedContent:
    Attributes:
      includeHeadCode - default: true
      code            - the reference code (schema says optional, but always present
      codeLabel       - UNUSED
      sortKeyOptional - UNUSED
    Elements:
      headCodes       - UNUSED
      includeRelatedCodes:
        Attributes:
          relationshipName
          relationshipTraversal - one of "TransitiveClosure", "TransitiveClosureLeaves" or "DirectRelationsOnly"
    -->
    <xsl:template match="mif:codeBasedContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:param name="codeSystem" as="node()"/>
        <xsl:param name="op"/>

        <xsl:choose>
            <xsl:when test="mif:includeRelatedCodes">
                <xsl:if test="mif:includeRelatedCodes/@relationshipName != 'Generalizes'">
                    <xsl:message>Unsupported relationship name: <xsl:value-of select="mif:includeRelatedCodes/@relationshipName"/></xsl:message>
                </xsl:if>
                <entry operator="{$op}" entryOrder="0">
                    <associatedEntities direction="TARGET_TO_SOURCE">
                        <xsl:attribute name="transitivity">
                            <xsl:choose>
                                <xsl:when test="mif:includeRelatedCodes/@relationshipTraversal = 'DirectRelationsOnly'">
                                    <xsl:text>DIRECTLY_ASSOCIATED</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>TRANSITIVE_CLOSURE</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:if test="mif:includeRelatedCodes/@relationshipTraversal != 'DirectRelationsOnly'">
                             <xsl:attribute name="leafOnly">
                                 <xsl:choose>
                                     <xsl:when test="mif:includeRelatedCodes/@relationshipTraversal = 'TransitiveClosureLeaves'">
                                         <xsl:text>LEAF_ONLY</xsl:text>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:text>ALL_INTERMEDIATE_NODES</xsl:text>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:attribute>
                        </xsl:if>
                        <referencedEntity uri="{cts2f:uri($codeSystem/@oid,@code)}">
                            <core:namespace>
                                <xsl:value-of select="$codeSystem/@name"/>
                            </core:namespace>
                            <core:name>
                                <xsl:value-of select="@code"/>
                            </core:name>
                        </referencedEntity>
                        <codeSystem>
                            <xsl:copy-of select="cts2f:cts2CodeSystem($codeSystem/@oid)/@*"/>
                            <xsl:copy-of select="cts2f:cts2CodeSystem($codeSystem/@oid)/node()"/>
                        </codeSystem>

                        <!-- TODO: Talk to Lloyd about the localization of Generalizes - what the dickens goes on here -->
                        <!--<predicate uri="{concat($uvVocabIri,'/pr/Specializes')}">
                            <core:namespace>pr</core:namespace>
                            <core:name>Specializes</core:name>
                        </predicate>-->
                        <predicate uri="http://www.w3.org/2004/02/skos/core#broaderTransitive">
                            <core:namespace>skos</core:namespace>
                            <core:name>broaderTransitive</core:name>
                        </predicate>
                    </associatedEntities>
                </entry>
                <xsl:if test="not(exists(@includeHeadCode)) or ../@includeHeadCode">
                    <entry operator="{$op}" entryOrder="0">
                        <entityList>
                            <referencedEntity uri="{cts2f:uri($codeSystem/@oid,@code)}">
                                <core:namespace>
                                    <xsl:value-of select="$codeSystem/@name"/>
                                </core:namespace>
                                <core:name>
                                    <xsl:value-of select="@code"/>
                                </core:name>
                            </referencedEntity>
                        </entityList>
                    </entry>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(preceding-sibling::mif:codeBasedContent)">
                    <entry operator="{$op}" entryOrder="0">
                        <entityList>
                            <xsl:for-each select="../mif:codeBasedContent">
                                <referencedEntity uri="{cts2f:uri($codeSystem/@oid,@code)}">
                                    <core:namespace>
                                        <xsl:value-of select="$codeSystem/@name"/>
                                    </core:namespace>
                                    <core:name>
                                        <xsl:value-of select="@code"/>
                                    </core:name>
                                </referencedEntity>
                            </xsl:for-each>
                        </entityList>
                    </entry>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="mif:propertyBasedContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:message>Unsupported value set definition filter:<xsl:value-of select="name()"/></xsl:message>
    </xsl:template>

    <xsl:template match="mif:relationshipBasedContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:message>Unsupported value set definition filter:<xsl:value-of select="name()"/></xsl:message>
    </xsl:template>

    <xsl:template match="mif:codeFilterContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:message>Unsupported value set definition filter:<xsl:value-of select="name()"/></xsl:message>
    </xsl:template>

    <!-- nonComputableContent - text and external definitions of content
         The attributes and elements are a HL7 modification of the W3C XHTML 1.0 schema.
         The namespace is "urn:hl7-org:v3/mif2"
    -->
    <xsl:template match="mif:nonComputableContent" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:param name="codeSystem" as="element(hl7:uriSubstitution)"/>
        <xsl:param name="op" as="xs:string">UNION</xsl:param>

        <entry operator="{$op}" entryOrder="0">
            <externalValueSetDefinition>
                <core:value xmlns="urn:hl7-org:v3/mif2">
                    <xsl:copy-of select="*"/>
                </core:value>
            </externalValueSetDefinition>
        </entry>
    </xsl:template>

    <!-- include a copy of another value set
         Attributes:
            id - oid of the referenced value set
            versionDate - date for specific value set - static reference (UNUSED)
            versionTime   date(?) for value set (UNUSED)
            name - name of value set
            rootCode - (UNUSED)
            rootCodeIncluded - whether root is included. Default: true (UNUSED)
        Elements:
            (none)
    -->
    <xsl:template match="mif:valueSetRef" mode="cts2valuesetdefinitioncontent" xmlns="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition">
        <xsl:param name="op">UNION</xsl:param>

        <!-- TODO: do we count on name or should we dereference the id? -->
        <entry operator="{$op}" entryOrder="0">
            <completeValueSet>
                <valueSet uri="{$vocabIri}/vs/{encode-for-uri(@name)}">
                    <xsl:value-of select="@name"/>
                </valueSet>
            </completeValueSet>
        </entry>
    </xsl:template>
</xsl:stylesheet>
