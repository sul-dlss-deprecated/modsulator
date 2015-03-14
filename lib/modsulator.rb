# File "modsulator.rb" - a pre-beta prototype script that takes a spreadsheet of MODS metadata and
# an XML template as input, and produces MODS XML. For an example, run like this (on the command line):
#
#      ruby modsulator.rb SuperMODS-01-sample.xlsx SuperMods-01-template.xml
#
#      *** Warning: There were headers in the spreadsheet that did not appear in the XML template (is there a spreadsheet typo?):
#      druid
#      sourceId
#      processed
#       ...more warnings you can ignore for now...
#
# For each row in the input spreadsheet, this script produces an XML file, named after the value
# of 'sourceId'.
#
# Note that this script was written by Darth Vader at 2am, so don't get your hopes up now :)
#
# Email bugs, questions, comments etc. to 'tommyi@stanford.edu'


require 'active_support/core_ext/hash/indifferent_access'   # Required for indifferent access to hashes
require 'active_support/core_ext/object/blank.rb'           # Required for template calls to blank?()
require 'erb'                                               # Rails templating engine
require 'nokogiri'
require 'roo'
require 'modsulator/normalizer'


class Modsulator

  def load_spreadsheet(filename)
    spreadsheet = open_spreadsheet(filename)

    # The MODS spreadsheet starts with a "super header" in the first row, followed by individual
    # column headers in the second row. The third row is the start of the actual data.
    header = spreadsheet.row(2)

    # need to build up an array here and return it
    rows = []
    
    (3..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      rows.push(row)
    end

    return rows
  end


  # Open spreadsheet based on filename extension
  def open_spreadsheet(filename)
    case File.extname(filename)
    when ".csv" then Roo::CSV.new(filename)
    when ".xls" then Roo::Excel.new(filename)
    when ".xlsx" then Roo::Excelx.new(filename)
    else raise "Unknown file type: #{filename}"
    end
  end



  # Write XML to file
  def generate_xml(mf, template_xml, row_number)
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
    # manifest_row.each do |k,v|
    #   replaced_xml = descriptive_metadata_xml.gsub!("[[#{k}]]", v.to_s.strip)
    #   puts("rx = #{replaced_xml}")
    #   if(replaced_xml == nil)
    #     puts("*** Warning: On line #{row_number}, there were no matches for the header #{k} within the master template. Do you have an error in your spreadsheet?")
    #   end
    # end
    return descriptive_metadata_xml
  end


  # Generates normalized (Stanford) MODS XML, writing to files.
  #
  # @param [String] template_filename      The full path to the desired template file (a spreadsheet).
  # @param [String] spreadsheet_filename   The full path to the input spreadsheet. One XML file will be generated per data row in this spreadsheet.
  # @param [String] output_directory       The directory where output files should be stored.
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
      generated_xml = generate_xml(spreadsheet_rows[i], mods_template_xml, i+1)
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



  ### Main code ###
  # mods_processor = Modsulator.new
  # unless ARGV.length == 2
  #   abort("Usage: ruby modsulator.rb <spreadsheet filename> <XML template filename>")
  # end

  # if(File.exists?(ARGV[0]) && File.readable?(ARGV[0]))
  #   spreadsheet_rows = mods_processor.load_spreadsheet(ARGV[0])
  # else abort "*** The file #{ARGV[0]} does not exist or is not readable to the current user?! - terminating"
  # end

  # if(File.exists?(ARGV[1]) && File.readable?(ARGV[1]))
  #   mods_template_xml = IO.read(ARGV[1])
  # else abort "*** The file #{ARGV[1]} does not exist or is not readable to the current user?! - terminating"
  # end

  # invalid_headers = mods_processor.validate_headers(spreadsheet_rows[0].keys, mods_template_xml)
  # if(invalid_headers.length > 0)
  #   puts("*** Warning: There were headers in the spreadsheet that did not appear in the XML template (is there a spreadsheet typo?):")
  #   invalid_headers.each do |h|
  #     puts(h)
  #   end
  # end

  # # Write one XML file per data row in the input spreadsheet
  # (0..(spreadsheet_rows.length-1)).each do |i|
  #   sourceid=spreadsheet_rows[i]['sourceId']
  #   output_filename = sourceid + ".xml"

  #   # Generate an XML string, then remove any text carried over from the template
  #   generated_xml = mods_processor.generate_xml(spreadsheet_rows[i], mods_template_xml, i+1)
  #   generated_xml.gsub!(/\[\[[^\]]+\]\]/, "")

  #   # Create an XML Document and normalize it
  #   xml_doc = Nokogiri::XML(generated_xml)
  #   root_node = xml_doc.root
  #   normalizer = Normalizer.new
  #   normalizer.remove_empty_nodes(root_node)

  #   # Check that the resulting XML is well formed -- Does this still work after we've modified the tree??!!!!!!???!!
  #   if(xml_doc.errors.length > 0)
  #     puts("***There were errors on row #{i}:")
  #     xml_doc.errors.each do |e|
  #       puts("  #{e.to_s}")
  #     end
  #   end

  #   File.open(output_filename, 'w') { |fh| fh.puts(root_node.to_s) }
  #   puts("Just saved #{output_filename}")
  # end
end
