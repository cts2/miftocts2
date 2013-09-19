<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates"
    xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:mif="urn:hl7-org:v3/mif2"
    xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition"
    exclude-result-prefixes="xs xd"
    version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="csuri" select="concat('urn:uuid:',document('http://informatics.mayo.edu/cts2/services/bioportal-rdf/uuid'))"/>

    <xsl:template match="/upd:ChangeSet">
        <ChangeSet xmlns="http://www.omg.org/spec/CTS2/1.1/Updates"
            xmlns:upd="http://www.omg.org/spec/CTS2/1.1/Updates"
            xmlns:core="http://www.omg.org/spec/CTS2/1.1/Core"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:mif="urn:hl7-org:v3/mif2"
            xmlns:vsd="http://www.omg.org/spec/CTS2/1.1/ValueSetDefinition"
            xsi:schemaLocation="http://www.omg.org/spec/CTS2/1.1/Updates http://informatics.mayo.edu/cts2/spec/CTS2/1.1/updates/Updates.xsd"
            changeSetURI="{$csuri}"
            creationDate="{current-dateTime()}">
            <xsl:apply-templates select="upd:member"/>
        </ChangeSet>       
    </xsl:template>
    
    <xsl:template match="upd:member">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()" mode="member"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*" mode="member">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <core:changeDescription changeType="DELETE" containingChangeSet="{$csuri}" changeDate="{current-dateTime()}"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>