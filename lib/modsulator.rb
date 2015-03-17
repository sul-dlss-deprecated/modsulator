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

  # Loads a spreadsheet into an array of hashes. The spreadsheet is expected to have two header rows. The first row
  # is a kind of "super header", and the second row is the header row that names the fields. The data rows are in
  # the third row onwards.
  #
  # @param [String] filename  The full path to a spreadsheet file (.csv or .xls or .xlsx)
  # @return [Array<Hash>]     An array with one entry per data row in the spreadsheet. Each entry is a hash, indexed by
  #                           the spreadsheet headers.
  def load_spreadsheet(filename)
    spreadsheet = open_spreadsheet(filename)

    # The MODS spreadsheet starts with a "super header" in the first row, followed by individual
    # column headers in the second row. The third row is the start of the actual data.
    header = spreadsheet.row(2)

    rows = []
    (3..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      rows.push(row)
    end

    return rows
  end


  # Opens a spreadsheet based on its filename extension.
  #
  # @param [String] filename  The full path to a spreadsheet file (.csv or .xls or .xlsx).
  # @return [Roo::CSV, Roo::Excel, Roo::Excelx] A Roo object, whose type depends on the extension of the given filename.
  def open_spreadsheet(filename)
    case File.extname(filename)
    when ".csv" then Roo::CSV.new(filename)
    when ".xls" then Roo::Excel.new(filename)
    when ".xlsx" then Roo::Excelx.new(filename)
    else raise "Unknown file type: #{filename}"
    end
  end



  # Generates an XML string for a given row in a spreadsheet.
  #
  # @param [Hash]     mf            A single row in a MODS metadata spreadsheet, as provided by the {Modsulator#load_spreadsheet} method.
  # @param [String]   template_xml  The XML template, as a big string.
  # @return [String]  XML template, with data from the row substituted in.
  def generate_xml(mf, template_xml)
    manifest_row = mf
    mods_template_xml = template_xml
    
    # XML escape all of the entries in the manifest row so they won't break the XML
    manifest_row.each {|k,v| manifest_row[k]=Nokogiri::XML::Text.new(v.to_s,Nokogiri::XML('')).to_s if v }

    # Enable access with symbol or string keys 
    manifest_row = manifest_row.with_indifferent_access
    
    # Run the XML template through ERB. This creates a new ERB object from the template XML,
    # NOT creating a separate thread, and omitting newlines for lines ending with '%>'
    template     = ERB.new(mods_template_xml, nil, '>')

    # ERB.result() actually computes the template. This just passes the top level binding.
    descriptive_metadata_xml = template.result(binding)

    # The manifest_row is a hash, with column names as the key.
    # In the template, as a convenience we allow users to put specific column placeholders inside
    # double brackets: "blah [[column_name]] blah".
    # Here we replace those placeholders with the corresponding value
    # from the manifest row.
    manifest_row.each { |k,v| descriptive_metadata_xml.gsub! "[[#{k}]]", v.to_s.strip }
    return descriptive_metadata_xml
  end


  # Generates normalized (Stanford) MODS XML, writing to files.
  #
  # @param [String] template_filename      The full path to the desired template file (a spreadsheet).
  # @param [String] spreadsheet_filename   The full path to the input spreadsheet. One XML file will be generated per data row in this spreadsheet.
  # @param [String] output_directory       The directory where output files should be stored.
  # @return [Void]
  def generate_normalized_mods(template_filename, spreadsheet_filename, output_directory)

    spreadsheet_rows = load_spreadsheet(spreadsheet_filename)
    mods_template_xml = IO.read(template_filename)
    invalid_headers = validate_headers(spreadsheet_rows[0].keys, mods_template_xml)

    # To do: generate a warning if there are invalid headers

    # Write one XML file per data row in the input spreadsheet
    (0..(spreadsheet_rows.length-1)).each do |i|
      sourceid = spreadsheet_rows[i]['sourceId']
      output_filename = output_directory + "/" + sourceid + ".xml"
        
      # Generate an XML string, then remove any text carried over from the template
      generated_xml = generate_xml(spreadsheet_rows[i], mods_template_xml)
      generated_xml.gsub!(/\[\[[^\]]+\]\]/, "")
      
      # Create an XML Document and normalize it
      xml_doc = Nokogiri::XML(generated_xml)
      root_node = xml_doc.root
      normalizer = Normalizer.new
      normalizer.remove_empty_nodes(root_node)

      # To do: notify of errors to the resulting XML
      
      File.open(output_filename, 'w') { |fh| fh.puts(root_node.to_s) }
    end
  end


  # Checks that all the headers in the spreadsheet has a corresponding entry in the XML template.
  #
  # @param [Array<String>] spreadsheet_headers A list of all the headers in the spreadsheet
  # @param [String]        template_xml        The XML template in a single string
  # @return [Array<String>]                    A list of spreadsheet headers that did not appear in the XML template. This list
  #                                            will be empty if all the headers were present.
  def validate_headers(spreadsheet_headers, template_xml)
    missing_headers = Array.new

    spreadsheet_headers.each do |header|
      if((header != nil) &&
         !(header == "sourceId") &&
         !(template_xml.include? header))
        missing_headers.push(header)
      end
    end

    return missing_headers
  end
end
