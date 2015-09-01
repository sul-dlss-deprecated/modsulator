[![Build Status](https://travis-ci.org/sul-dlss/modsulator.svg?branch=master)](https://travis-ci.org/sul-dlss/modsulator) [![Coverage Status](https://coveralls.io/repos/sul-dlss/modsulator/badge.png)](https://coveralls.io/r/sul-dlss/modsulator) [![Dependency Status](https://gemnasium.com/sul-dlss/modsulator.svg)](https://gemnasium.com/sul-dlss/modsulator) [![Gem Version](https://badge.fury.io/rb/modsulator.svg)](http://badge.fury.io/rb/modsulator) [![Code Climate](https://codeclimate.com/github/sul-dlss/modsulator/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/modsulator)

# modsulator
Produce Stanford MODS from spreadsheets.

Note that only .xlsx and .csv formats work with the latest template, which has more columns than
.xls allows (> 256).

# Running on the console

  bin/console

# Normalizing an xml document

  input_file='/Users/lyberadmin/bb936cg6081.xml' # starting mods document
  output_file='/Users/lyberadmin/bb936cg6081-cleaned.xml' # cleaned up mods document
  mods_xml=File.open(input_file) # read it in
  mods_xml_doc = Nokogiri::XML(mods_xml) # create a nokogiri doc
  normalizer = Normalizer.new 
  normalizer.normalize_document(mods_xml_doc.root) # normalize it
  File.write(output_file,mods_xml_doc.to_xml) # write it out
