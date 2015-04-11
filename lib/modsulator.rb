# File "modsulator.rb" - defines the Modsulator class, providing the main part of the API that lets you work
# with metadata spreadsheets and MODS XML.

require 'active_support/core_ext/hash/indifferent_access'   # Required for indifferent access to hashes
require 'active_support/core_ext/object/blank.rb'           # Required for template calls to blank?()
require 'erb'                                               # Rails templating engine
require 'nokogiri'
require 'roo'
require 'modsulator/normalizer'


# The main class for the MODSulator API, which lets you work with metadata spreadsheets and MODS XML.
# @see https://consul.stanford.edu/display/chimera/MODS+bulk+loading Requirements (Stanford Consul page)
class Modsulator
  attr_reader :filename, :template_xml, :rows

  # There are two ways to provide input data - either with a spreadsheet file or with an array of data rows.
  # Note that if neither :template_file nor :template_string are specified, the gem's built-in XML template is used.
  # @param [String] filename               The full path to the input spreadsheet.
  # @param [Array]  data_rows              An array of input rows, as produced by {ModsulatorSheet#rows}.
  # @param [Hash]   options
  # @option options [String] :template_file    The full path to the desired template file (a spreadsheet).
  # @option options [String] :template_string  The template contents as a string
  def initialize filename = '', data_rows = [], options = {}
    @filename = filename

    if @filename == ''
      @rows = data_rows
    else
      @rows = ModsulatorSheet.new(filename).rows
    end

    if options[:template_string]
      @template_xml = options[:template_string]
    elsif options[:template_file]
      @template_xml = File.read(options[:template_file])
    else
      @template_xml = File.read(File.join(File.expand_path("../../spec/fixtures", __FILE__), "modsulator_template.xml"))
    end
  end


  # Generates a container XML document with one <mods> entry per input row.
  #
  # @return [String] An XML string containing all the <mods> elements within a <metadata> element.
  def convert_rows()
    xml_result = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    xml_result = xml_result + "<metadata>\n"
    @rows.each do |row|
      mods_xml = generate_xml(row)

      mods_xml.gsub!(/\[\[[^\]]+\]\]/, "")
      mods_xml.gsub!(/<\s[^>]+><\/>/, "")

      xml_doc = Nokogiri::XML(mods_xml)
      normalizer = Normalizer.new
      normalizer.normalize_document(xml_doc.root)
      
      xml_result = xml_result + xml_doc.to_s + "\n"
    end
    xml_result + "</metadata>" + "\n"
  end
  

  # Generates an XML string for a given row in a spreadsheet.
  #
  # @param [Hash]     metadata_row  A single row in a MODS metadata spreadsheet, as provided by the {ModsulatorSheet#rows} method.
  # @return [String]                XML template, with data from the row substituted in.
  def generate_xml(metadata_row)
    manifest_row = metadata_row

    # XML escape all of the entries in the manifest row so they won't break the XML
    manifest_row.each {|k,v| manifest_row[k]=Nokogiri::XML::Text.new(v.to_s,Nokogiri::XML('')).to_s if v }

    # Enable access with symbol or string keys 
    manifest_row = manifest_row.with_indifferent_access
    
    # Run the XML template through ERB. This creates a new ERB object from the template XML,
    # NOT creating a separate thread, and omitting newlines for lines ending with '%>'
    template     = ERB.new(template_xml, nil, '>')

    # ERB.result() actually computes the template. This just passes the top level binding.
    descriptive_metadata_xml = template.result(binding)

    # The manifest_row is a hash, with column names as the key.
    # In the template, as a convenience we allow users to put specific column placeholders inside
    # double brackets: "blah [[column_name]] blah".
    # Here we replace those placeholders with the corresponding value
    # from the manifest row.
    manifest_row.each { |k,v| descriptive_metadata_xml.gsub! "[[#{k}]]", v.to_s.strip }

    descriptive_metadata_xml
  end

  
  # Generates normalized (Stanford) MODS XML, writing output to files.
  #
  # @param [String] output_directory       The directory where output files should be stored.
  # @return [Void]
  def generate_normalized_mods(output_directory)

#    invalid_headers = validate_headers(rows.first.keys)

    # To do: generate a warning if there are invalid headers

    # Write one XML file per data row in the input spreadsheet
    rows.each do |row|
      sourceid = row['sourceId']
      output_filename = output_directory + "/" + sourceid + ".xml"
        
      # Generate an XML string, then remove any text carried over from the template
      generated_xml = generate_xml(row)
      generated_xml.gsub!(/\[\[[^\]]+\]\]/, "")

      # Remove empty tags from when e.g. <[[sn1:p2:type]]> does not get filled in when [[sn1:p2:type]] has no value in the source spreadsheet
      generated_xml.gsub!(/<\s[^>]+><\/>/, "")

      # Create an XML Document and normalize it
      xml_doc = Nokogiri::XML(generated_xml)
      root_node = xml_doc.root
      normalizer = Normalizer.new
      normalizer.remove_empty_attributes(root_node)
      normalizer.remove_empty_nodes(root_node)

      # To do: notify of errors in the resulting XML
      
      File.open(output_filename, 'w') { |fh| fh.puts(root_node.to_s) }
    end
  end


  # Checks that all the headers in the spreadsheet has a corresponding entry in the XML template.
  #
  # @param [Array<String>] spreadsheet_headers A list of all the headers in the spreadsheet
  # @return [Array<String>]                    A list of spreadsheet headers that did not appear in the XML template. This list
  #                                            will be empty if all the headers were present.
  def validate_headers(spreadsheet_headers)
    spreadsheet_headers.reject do |header|
      header.nil? || header == "sourceId" || template_xml.include?(header)
    end
  end
end
