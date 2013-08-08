<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:cts2f="http://informatics.mayo.edu/cts2/xslt/functions"
    xmlns:urimap="http://informatics.mayo.edu/cts2/urimap"
    xmlns:hl7="urn:hl7-org:xslt:functions"
    xmlns:mif="urn:hl7-org:v3/mif2" 
    xpath-default-namespace="http://informatics.mayo.edu/cts2/xslt/functions"
    exclude-result-prefixes="urimap cts2f xsl mif xs hl7">
    
    <xsl:import href="../../hl7owl/transforms/VocabToOWL.xslt"/>
    <xsl:param name="comments" as="xs:boolean" />
    
    <!-- Return the closest approximation for a preferred name.
         Order is:
          1) preferred english printName
          2) preferred printName
          3) alternate english printName
          4) alternate printName
          5) first active code
          6) first code       
    -->
    <xsl:function name="cts2f:getPrefName">
        <xsl:param name="concept" as="element(mif:concept)"/>
        <xsl:choose>
            <xsl:when test="$concept/mif:printName[@language='en' and @preferredForLanguage='true']">
                <xsl:value-of select="$concept/mif:printName[@language='en' and @preferredForLanguage='true']/@text"></xsl:value-of>
            </xsl:when>
            <xsl:when test="$concept/mif:printName[@preferredForLanguage='true']">
                <xsl:value-of select="$concept/mif:printName[@preferredForLanguage='true'][1]/@text"></xsl:value-of>
            </xsl:when>
            <xsl:when test="$concept/mif:printName[@language='en']">
                <xsl:value-of select="$concept/mif:printName[@language='en']/@text"></xsl:value-of>
            </xsl:when>
            <xsl:when test="$concept/mif:printName">
                <xsl:value-of select="$concept/mif:printName[1]/@text"></xsl:value-of>
            </xsl:when>
            <xsl:when test="$concept/mif:code[@status='active']">
                <xsl:value-of select="$concept/mif:code[@status='active'][1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$concept/mif:code[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Return the preferred name for a given concept code in a given code system version -->
    <xsl:function name="cts2f:prefNameForInVersion">
        <xsl:param name="csv" as="element(mif:releasedVersion)"/>
        <xsl:param name="code" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$csv/mif:concept/mif:code[@code=$code and @status='active']">
                <xsl:value-of select="cts2f:getPrefName($csv/mif:concept[mif:code[@code=$code and @status='active']])"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <!-- Return the latest mif:releasedVersion for the supplied code system oid -->
    <xsl:function name="cts2f:releasedVersionFor" as="element(mif:releasedVersion)?">
        <xsl:param name="csoid" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="document($baseDoc)/mif:vocabularyModel/mif:codeSystem[@codeSystemId=$csoid]">
                <xsl:variable name="maxVersion" as="xs:string" select="$uriSubstitutions[@type='cs' and @oid=$csoid]/@date"/>
                <xsl:copy-of select="document($baseDoc)/mif:vocabularyModel/mif:codeSystem[@codeSystemId=$csoid]/mif:releasedVersion[@releaseDate=$maxVersion]"/>
            </xsl:when>
            <xsl:otherwise><xsl:message terminate="yes">Can't locate code system <xsl:value-of select="$csoid"/></xsl:message></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Return the preferred name for the given contept code in the given code system oid -->
    <xsl:function name="cts2f:prefNameFor">
        <xsl:param name="csoid" as="xs:string"/>
        <xsl:param name="code" as="xs:string"/>
        <xsl:variable name="csv" select="cts2f:releasedVersionFor($csoid)"/>
        <xsl:choose>
            <xsl:when test="$csv">
                <xsl:value-of select="cts2f:prefNameForInVersion($csv,$code)"/>
            </xsl:when>
            <xsl:otherwise>UNOWN_CODE(<xsl:value-of select="$code"/>)</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Construct a value set definition identifier 
         Format:  date[Ttime] 
    -->
    <xsl:function name="cts2f:definitionId">
        <xsl:param name="date"/>
        <xsl:param name="time"/>
        <xsl:value-of select="$date"/>
        <xsl:if test="$time and $time != '00:00:00'">
            <xsl:value-of select="concat('T', $time)"/>
        </xsl:if>
    </xsl:function>
    <xsl:function name="cts2f:definitionId">
        <xsl:param name="date"/>
        <xsl:value-of select="cts2f:definitionId($date,'00:00:00')"></xsl:value-of>
    </xsl:function>
    
    <!-- Look up an entry in the uriSubstitution table -->
    <xsl:function name="cts2f:oidToSubstitution" as="element(hl7:uriSubstitution)">
        <xsl:param name="uriSubstitutions"/>
        <xsl:param name="oid"/>
        <xsl:param name="type"/>
        <xsl:choose>
            <xsl:when test="$uriSubstitutions[@type=$type and @oid=$oid]">
                <xsl:copy-of select="$uriSubstitutions[@type=$type and @oid=$oid]"/>
            </xsl:when>
            <xsl:otherwise>
                <hl7:uriSubstitution type="{$type}" oid="{$oid}" name="UNKNOWN" baseUri="http://unknown.org/UNKNOWN"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Look up a code system in the uriSubstitution table -->
    <xsl:function name="cts2f:oidToCodeSystem" as="element(hl7:uriSubstitution)">
        <xsl:param name="oid"/>
        <xsl:copy-of select="cts2f:oidToSubstitution($uriSubstitutions,$oid,'cs')"/>
    </xsl:function>
    
    <!-- Look up a value set in the uriSubstitution table -->
    <xsl:function name="cts2f:oidToValueSet" as="element(hl7:uriSubstitution)">
        <xsl:param name="oid"/>
        <xsl:copy-of select="cts2f:oidToSubstitution($uriSubstitutions,$oid,'vs')"/>
    </xsl:function>
    
    <!-- Look up a concept domain in the uriSubstitution table -->
    <xsl:function name="cts2f:oidToConceptDomain" as="element(hl7:uriSubstitution)">
        <xsl:param name="oid"/>
        <xsl:copy-of select="cts2f:oidToSubstitution($uriSubstitutions,$oid,'cd')"/>
    </xsl:function>
        
    
    <!-- Convert a urimap:entry into a CodeSystemReference -->
<!--    <xsl:function name="cts2f:entryToCSR" as="core:CodeSystemReference">
        <xsl:param name="entry" as="urimap:mapEntry"/>-->
    <xsl:function name="cts2f:entryToCSR" as="node()" xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
        <xsl:param name="entry" as="node()"/>
        <CodeSystemReference xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
            <xsl:copy-of select="$entry/@*[name()!='id']"/>
            <xsl:value-of select="$entry"/>
        </CodeSystemReference>
    </xsl:function>
    
    <!-- Return the core:CodeSystemReference that corresponds to the supplied codesystem oid -->
    <xsl:function name="cts2f:cts2CodeSystem" as="node()">
        <xsl:param name="oid" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="document('CodeSystemMap.xml')/urimap:mapList/urimap:entry[@id=$oid]">
                <xsl:copy-of select="cts2f:entryToCSR(document('CodeSystemMap.xml')/urimap:mapList/urimap:entry[@id=$oid])"/>
            </xsl:when>
            <xsl:otherwise>
                <core:CodeSystemReference uri="urn:oid:{$oid}"  xmlns="http://www.omg.org/spec/CTS2/1.1/Core">UNKNOWN</core:CodeSystemReference>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Return the URI for a code system oid and entity code -->
    <xsl:function name="cts2f:uri" as="xs:string">
        <xsl:param name="csoid" as="xs:string"/>
        <xsl:param name="code" as="xs:string"/>
        <!-- TODO: This doesn't work correctly at the moment... -->
        <xsl:variable name="csURI" select="cts2f:cts2CodeSystem($csoid)/@uri"/>
        <xsl:choose>
            <xsl:when test="document('CTS2Prefixes.xml')/urimap:prefixList/urimap:entry[@uri=$csURI]">
                <xsl:value-of select="concat(document('CTS2Prefixes.xml')/urimap:prefixList/urimap:entry[@uri=$csURI]/@prefix,encode-for-uri($code))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($csURI,':',encode-for-uri($code))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Return the designation for a concept code -->
    <xsl:function name="cts2f:designation" as="xs:string">
        <xsl:param name="csoid" as="xs:string"/>
        <xsl:param name="code" as="xs:string"/>
        <!-- TODO get the actual designation -->
        <xsl:value-of select="$code"/>
    </xsl:function>

    <!-- Parse the various forms of concept definition -->
    <xsl:function name="cts2f:parseDocumentation">
        <xsl:param as="element(mif:annotations)*" name="annotations"/>
        <xsl:variable name="defs">
          <xsl:apply-templates select="$annotations/mif:documentation/mif:definition/mif:text/mif:p[1]" mode="definition">
              <xsl:with-param name="gathering">definition</xsl:with-param>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="examples">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:definition/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">example</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="notes">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:definition/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">scopenote</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="editorialnotes">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:description/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">editorialnote</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <cts2f:doc>
            <xsl:if test="$defs/*">
                <definition xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
                    <core:value>
                        <xsl:copy-of select="$defs"/>
                    </core:value>
                </definition>
            </xsl:if>
            <xsl:if test="$notes/*">
                <note type="ScopeNote" xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
                    <core:value>
                        <xsl:copy-of select="$notes"/>
                    </core:value>
                </note>
            </xsl:if>
            <xsl:if test="$editorialnotes/*">
                <note type="EditorialNote" xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
                    <core:value>
                        <xsl:copy-of select="$editorialnotes"/>
                    </core:value>
                </note>
            </xsl:if>
            <xsl:if test="$examples/*">
                <example xmlns="http://www.omg.org/spec/CTS2/1.1/Entity">
                    <core:value>
                        <xsl:copy-of select="$examples"/>
                    </core:value>
                </example>
            </xsl:if>
        </cts2f:doc>
    </xsl:function>
    
    <!-- Parse the various forms of code system description -->
    <xsl:function name="cts2f:parseCodeSystemDocumentation">
        <xsl:param as="element(mif:annotations)*" name="annotations"/>
        <xsl:variable name="defs">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:description/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">definition</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="examples">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:description/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">example</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="scopenotes">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:description/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">scopenote</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="editorialnotes">
            <xsl:apply-templates select="$annotations/mif:documentation/mif:description/mif:text/mif:p[1]" mode="definition">
                <xsl:with-param name="gathering">editorialnote</xsl:with-param>
            </xsl:apply-templates>
        </xsl:variable>
        <doc>
            <xsl:if test="$defs/*">
                <resourceSynopsis xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                    <value>
                        <xsl:copy-of select="$defs"/>
                    </value>
                </resourceSynopsis>
            </xsl:if>
            <xsl:if test="$editorialnotes/*">
                <note type="EditorialNote" xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                    <value>
                        <xsl:copy-of select="$editorialnotes"/>
                    </value>
                </note>
            </xsl:if>
            <xsl:if test="$scopenotes/*">
                <note type="ScopeNote" xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                    <value>
                        <xsl:copy-of select="$scopenotes"/>
                    </value>
                </note>
            </xsl:if>
            <xsl:if test="$examples/*">
                <note type="ScopeNote" xmlns="http://www.omg.org/spec/CTS2/1.1/Core">
                    <value>
                        <xsl:copy-of select="$examples"/>
                    </value>
                </note>
            </xsl:if>
        </doc>
    </xsl:function>
    
    <xsl:template match="mif:p" mode="definition">
        <xsl:param name="gathering"/>
        <xsl:choose>
            <xsl:when test="mif:b[1]='Discussion:' or mif:i[1]='Discussion' or
                mif:b[1]='Discussion and Rationale:' or mif:i[1]='Discussion and Rationale:'">
                <xsl:apply-templates mode='scopenote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>        
            <xsl:when test="starts-with(mif:b[1],'OpenIssue:') or starts-with(mif:i[1],'OpenIssue:')">
                <xsl:apply-templates mode='editorialnote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Example:' or mif:i[1]='Example:' or
                mif:b[1]='Examples:' or mif:i[1]='Examples:'">
                <xsl:apply-templates mode="example" select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$gathering='definition'">
                    <xsl:copy-of select="."/>
                </xsl:if>
                <xsl:apply-templates mode="definition" select="following-sibling::node()[name()='p'][1]">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mif:p" mode="scopenote">
        <xsl:param name="gathering"/>
        <xsl:choose>
            <xsl:when test="starts-with(mif:b[1],'OpenIssue:') or starts-with(mif:i[1],'OpenIssue:')">
                <xsl:apply-templates mode='editorialnote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Example:' or mif:i[1]='Example:' or
                mif:b[1]='Examples:' or mif:i[1]='Examples:'">
                <xsl:apply-templates mode="example" select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Definition:' or mif:i[1]='Definition:'">
                <xsl:apply-templates mode='definition' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$gathering='scopenote'">
                    <xsl:copy-of select="."/>
                </xsl:if>
                <xsl:apply-templates mode="scopenote" select="following-sibling::node()[name()='p'][1]">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mif:p" mode="editorialnote">
        <xsl:param name="gathering"/>
        <xsl:choose>
            <xsl:when test="mif:b[1]='Discussion:' or mif:i[1]='Discussion' or
                mif:b[1]='Discussion and Rationale:' or mif:i[1]='Discussion and Rationale:'">
                <xsl:apply-templates mode='scopenote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Example:' or mif:i[1]='Example:' or
                mif:b[1]='Examples:' or mif:i[1]='Examples:'">
                <xsl:apply-templates mode="example" select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Definition:' or mif:i[1]='Definition:'">
                <xsl:apply-templates mode='definition' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$gathering='editorialnote'">
                    <xsl:copy-of select="."/>
                </xsl:if>
                <xsl:apply-templates mode="editorialnote" select="following-sibling::node()[name()='p'][1]">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mif:p" mode="example">
        <xsl:param name="gathering"/>
        <xsl:choose>
            <xsl:when test="mif:b[1]='Discussion:' or mif:i[1]='Discussion' or
                mif:b[1]='Discussion and Rationale:' or mif:i[1]='Discussion and Rationale:'">
                <xsl:apply-templates mode='scopenote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="mif:b[1]='Definition:' or mif:i[1]='Definition:'">
                <xsl:apply-templates mode='definition' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:when test="starts-with(mif:b[1],'OpenIssue:') or starts-with(mif:i[1],'OpenIssue:')">
                <xsl:apply-templates mode='editorialnote' select=".">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$gathering='example'">
                    <xsl:copy-of select="."/>
                </xsl:if>
                <xsl:apply-templates mode="example" select="following-sibling::node()[name()='p'][1]">
                    <xsl:with-param name="gathering" select="$gathering"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

            
</xsl:stylesheet>