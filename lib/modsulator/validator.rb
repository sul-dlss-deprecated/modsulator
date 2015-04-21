require 'nokogiri'


# Validates XML against the MODSulator schema.
class Validator
  # The Nokogiri::XML::Schema instance used for validation.
  attr_reader :schema

  # @param schema_file  Full path to the desired .xsd file. If none is given, the built-in file will be used.
  def initialize(schema_file = '')
    if(schema_file == '')
      @schema = Nokogiri::XML::Schema(File.read("modsulator.xsd"))
    else
      @schema = Nokogiri::XML::Schema(File.read(schema_file))
    end
  end

  # Validates an XML string.
  #
  # @param xml   An XML document as a string.
  # @return      An array containing holds Nokogiri::XML::SyntaxError elements. If this array has length zero, the document is valid.
  def validate_xml_string(xml)
    xml_doc = Nokogiri::XML(xml)
    return validate_xml_doc(xml_doc)
  end


  # Validates an XML document.
  #
  # @param doc   An instance of Nokogiri::XML::Document
  # @return      An array containing holds Nokogiri::XML::SyntaxError elements. If this array has length zero, the document is valid.
  def validate_xml_doc(doc)
    return doc.errors if(doc.errors.length > 0)
    return @schema.validate(doc)
  end
end
