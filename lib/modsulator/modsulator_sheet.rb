# File "modsulator_sheet.rb" - a class to load and validate metadata spreadsheets (.xlsx or .csv) for input
# to Modsulator.

require 'json'
require 'roo'

# This class provides methods to parse Stanford's MODS spreadsheets into either an array of hashes, or a JSON string.
class ModsulatorSheet
  attr_reader :filename

  # @param [String]  filename   The full path to the input spreadsheet.
  def initialize filename
    @filename = filename
  end
  

  # Loads the input spreadsheet into an array of hashes. This spreadsheet should conform to the Stanford MODS template format,
  # which has three header rows. The first row is a kind of "super header", the second row is an intermediate header and the
  # third row is the header row that names the fields. The data rows are in the fourth row onwards.
  #
  # @return [Array<Hash>]      An array with one entry per data row in the spreadsheet. Each entry is a hash, indexed by
  #                            the spreadsheet headers.
  def rows
    # Parse the spreadsheet, automatically finding the header row by looking for "druid" and "sourceId" and leave the
    # header row itself out of the resulting array. Everything preceding the header row is discarded. Would like to use
    # clean: true here, but the latest release of Roo 1.13.2 crashes. 2.0.0beta1 seems to work though.
    @rows ||= spreadsheet.parse(header_search: ["druid", "sourceId"]).drop(1)
  end

  
  # Opens a spreadsheet based on its filename extension.
  #
  # @return [Roo::CSV, Roo::Excel, Roo::Excelx]   A Roo object, whose type depends on the extension of the given filename.
  def spreadsheet
    @spreadsheet ||= case File.extname(filename)
    when ".csv" then Roo::CSV.new(filename)
    when ".xls" then Roo::Excel.new(filename)
    when ".xlsx" then Roo::Excelx.new(filename)
    else raise "Unknown file type: #{filename}"
    end
  end


   # Get the headers used in the spreadsheet
  def headers
    rows.first.keys
  end


  # Convert the loaded spreadsheet to a JSON string.
  # @return [String]  A JSON string.
  def to_json
    json_hash = Hash.new
    json_hash["filename"] = filename
    json_hash["rows"] = rows
    json_hash.to_json
  end
end
