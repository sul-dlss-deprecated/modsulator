def load_xml_from_file(identifier)
  Nokogiri::XML(File.open('../fixtures/' + identifier + '.xml'))
end


def load_xml_string(identifier)
  File.read('../fixtures/' + identifier + '.xml')
end
