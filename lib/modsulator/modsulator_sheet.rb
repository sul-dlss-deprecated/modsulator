# File "modsulator_sheet.rb" - a class to load and validate metadata spreadsheets (.xlsx or .csv) for input
# to Modsulator.

require 'json'
require 'roo'

# This class provides methods to parse Stanford's MODS spreadsheets into either an array of hashes, or a JSON string.
class ModsulatorSheet
  attr_reader :file, :filename

  # Creates a new ModsulatorSheet. When called with temporary files, the filename must be specified separately, hence the
  # second argument.
  # @param [File]    file        The input spreadsheet
  # @param [String]  filename    The filename of the input spreadsheet.
  def initialize(file, filename)
    @file = file
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
    # header row itself out of the resulting array. Everything preceding the header row is discarded.
    @rows ||= spreadsheet.parse(header_search: ['druid', 'sourceId'], clean: true)
  end


  # Opens a spreadsheet based on its filename extension.
  #
  # @return [Roo::CSV, Roo::Excel, Roo::Excelx]   A Roo object, whose type depends on the extension of the given filename.
  def spreadsheet
    @spreadsheet ||= case File.extname(@filename)
                     when '.csv' then Roo::Spreadsheet.open(@file, extension: :csv)
                     when '.xls' then Roo::Spreadsheet.open(@file, extension: :xls)
                     when '.xlsx' then Roo::Spreadsheet.open(@file, extension: :xlsx)
                     else fail "Unknown file type: #{@filename}"
    end
  end


  # Get the headers used in the spreadsheet
  def headers
    rows.first.keys
  end


  # Convert the loaded spreadsheet to a JSON string.
  # @return [String]  A JSON string.
  def to_json
    json_hash = {}
    json_hash['filename'] = File.basename(filename)
    json_hash['rows'] = rows
    json_hash.to_json
  end
end
