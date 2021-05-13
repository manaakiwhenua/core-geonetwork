<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href="common.xsl"/>

  <xsl:template match="*" mode="site">
    <capabilitiesUrl>
      <xsl:value-of select="capabUrl/value"/>
    </capabilitiesUrl>
    <icon>
      <xsl:value-of select="icon/value"/>
    </icon>
    <rejectDuplicateResource>
      <xsl:value-of select="rejectDuplicateResource/value"/>
    </rejectDuplicateResource>
    <hopCount>
      <xsl:value-of select="hopCount/value"/>
    </hopCount>
    <xpathFilter>
      <xsl:value-of select="xpathFilter/value"/>
    </xpathFilter>
    <xslfilter>
      <xsl:value-of select="xslfilter/value"/>
    </xslfilter>
    <queryScope>
      <xsl:value-of select="queryScope/value"/>
    </queryScope>
    <outputSchema>
      <xsl:value-of select="outputSchema/value"/>
    </outputSchema>
  </xsl:template>


  <xsl:template match="*" mode="options"/>


  <xsl:template match="*" mode="searches">
    <searches>
      <search>
        <xsl:apply-templates select="children"/>
      </search>
    </searches>
  </xsl:template>

  <xsl:template match="*" mode="filters">
    <filters>
      <xsl:for-each select="filter/children">
        <xsl:sort select="position/value" data-type="number" />
        <filter>
          <field>
            <xsl:value-of select="field/value"/>
          </field>
          <operator>
            <xsl:value-of select="operator/value"/>
          </operator>
          <value>
            <xsl:value-of select="value/value"/>
          </value>
          <condition>
            <xsl:value-of select="condition/value"/>
          </condition>
        </filter>
      </xsl:for-each>
    </filters>
  </xsl:template>

  <xsl:template match="*" mode="bboxFilter">
    <bboxFilter>
      <bbox-xmin>
        <xsl:value-of select="bbox-xmin/value"/>
      </bbox-xmin>
      <bbox-ymin>
        <xsl:value-of select="bbox-ymin/value"/>
      </bbox-ymin>
      <bbox-xmax>
        <xsl:value-of select="bbox-xmax/value"/>
      </bbox-xmax>
      <bbox-ymax>
        <xsl:value-of select="bbox-ymax/value"/>
      </bbox-ymax>
    </bboxFilter>
  </xsl:template>

  <xsl:template match="children">
    <xsl:copy-of select="search/children/child::*"/>
  </xsl:template>
</xsl:stylesheet>
