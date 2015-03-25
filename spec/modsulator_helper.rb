class ModsulatorHelper

  def load_xml_from_file(identifier)
    Nokogiri::XML(File.open('../fixtures/' + identifier + '.xml'))
  end


  def load_xml_string(identifier)
    File.read('../fixtures/' + identifier + '.xml')
  end
# Don't need this??
  def empty_attributes_doc()
    xml_doc = Nokogiri::XML("<root_node>");
    root = xml_doc.root
    root.add_child("level_1_1");
    level_1_2 = root.add_child("level_1_2");

    return xml_doc
  end

end
