# File "modsulator.rb" - defines the Modsulator class, providing the main part of the API that lets you work
# with metadata spreadsheets and MODS XML.

require 'active_support/core_ext/hash/indifferent_access'   # Required for indifferent access to hashes
require 'active_support/core_ext/object/blank.rb'           # Required for template calls to blank?()
require 'erb'                                               # Rails templating engine
require 'nokogiri'
require 'roo'
require 'rubygems'
require 'modsulator/normalizer'
require 'modsulator/modsulator_sheet'


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
    elsif
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


  # Generates an XML document with one <mods> entry per input row.
  # Example output:
  #  <xmlDocs datetime="2015-03-23 09:22:11AM" sourceFile="FitchMLK-v1.xlsx">
  #       <xmlDoc id="descMetadata" objectId="druid:aa111aa1111">
  #           <mods ... >
  #               :
  #           </mods>
  #       </xmlDoc>
  #       <xmlDoc id="descMetadata" objectId="druid:aa222aa2222">
  #           <mods ... >
  #               :
  #           </mods>
  #       </xmlDoc>
  #  </xmlDocs>
  # @param  display_filename   The filename to be displayed in the output XML.
  # @return [String]           An XML string containing all the <mods> documents within a nested structure as shown in the example.
  def convert_rows(display_filename = '')
    if(display_filename == '')
      display_filename = @filename
    end
    time_stamp = Time.now.strftime("%Y-%m-%d %I:%M:%S%p")
    header = "<xmlDocs datetime=\"#{time_stamp}\" sourceFile=\"#{@display_filename}\">"
    full_doc = Nokogiri::XML(header)
    root = full_doc.root

    @rows.each do |row|
      mods_xml_doc = row_to_xml(row)

      sub_doc = full_doc.create_element('xmlDoc', :id => 'descMetadata', :objectId => "#{row['druid']}")
      sub_doc.add_child(mods_xml_doc.root)
      root.add_child(sub_doc)
    end

    full_doc.to_s
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
    # Write one XML file per data row in the input spreadsheet
    rows.each do |row|
      sourceid = row['sourceId']
      output_filename = output_directory + "/" + sourceid + ".xml"

      mods_doc = row_to_xml(row)
      File.open(output_filename, 'w') { |fh| fh.puts(mods_doc.root.to_s) }
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


  # Converts a single data row into a normalized MODS XML document.
  #
  # @param row     A single row in a MODS metadata spreadsheet, as provided by the {ModsulatorSheet#rows} method.
  # @return        An instance of Nokogiri::XML::Document that holds a normalized MODS XML instance.
  def row_to_xml(row)

    # Generate an XML string, then remove any text carried over from the template
    mods_xml = generate_xml(row)
    mods_xml.gsub!(/\[\[[^\]]+\]\]/, "")

    # Remove empty tags from when e.g. <[[sn1:p2:type]]> does not get filled in when [[sn1:p2:type]] has no value in the source spreadsheet
    mods_xml.gsub!(/<\s[^>]+><\/>/, "")

    mods_xml_doc = Nokogiri::XML(mods_xml)
    normalizer = Normalizer.new
    normalizer.normalize_document(mods_xml_doc.root)

    return mods_xml_doc
  end
end
