# File "normalizer.rb" - defines a class for normalizing MODS XML according to the Stanford guidelines.

require 'nokogiri'

# This class provides methods to normalize MODS XML according to the Stanford guidelines.
# @see https://consul.stanford.edu/display/chimera/MODS+validation+and+normalization Requirements (Stanford Consul page - requires login)
class Normalizer
  # Linefeed character entity reference
  LINEFEED = '&#10;'
  
  # Checks if a node has attributes that we make exeptions for. There are two such exceptions.
  #
  # * A "collection" attribute with the value "yes" <em>on a typeOfResource tag</em>.
  # * A "manuscript" attribute with the value "yes" <em>on a typeOfResource tag</em>.
  #
  # Nodes that fall under any of these exceptions should not be deleted, even if they have no content.
  #
  # @param  [Nokogiri::XML::Element]   node    An XML node.
  # @return [Boolean]                  true if the node contains any of the exceptional attributes, false otherwise.
  def exceptional?(node)
    return false unless node != nil
    
    tag = node.name
    attributes = node.attributes

    if(attributes.empty?)
      return false
    end

    for key, value in attributes do
      if(tag == "typeOfResource")  # Note that according to the MODS schema, any other value than 'yes' for these attributes is invalid
        if((key == "collection" && value.to_s.downcase == "yes") ||
           (key == "manuscript" && value.to_s.downcase == "yes"))
          return true
        end
      end
    end
    return false
  end


  # Recursive helper method for {Normalizer#clean_linefeeds} to do string substitution.
  #
  # @param [Nokogiri::XML::Element]   node   An XML node
  # @return [String]                  A string composed of the entire contents of the given node, with substitutions made as described for {#clean_linefeeds}.
  def substitute_linefeeds(node)
    new_text = String.new

    # If we substitute in '&#10;' by itself, Nokogiri interprets that and then prints '&amp;#10;' when printing the document later. This
    # is an ugly way to add linefeed characters in a way that we at least get well-formatted output in the end.
    if(node.text?)
      new_text = node.content.gsub(/\r\n/, Nokogiri::HTML(LINEFEED).text).gsub(/\n/, Nokogiri::HTML(LINEFEED).text).gsub(/\r/, Nokogiri::HTML(LINEFEED).text) 
    else
      if(node.node_name == "br")
        new_text += Nokogiri::HTML(LINEFEED).text
      elsif(node.node_name == "p")
        new_text += Nokogiri::HTML(LINEFEED).text + Nokogiri::HTML(LINEFEED).text;
      end
      
      node.children.each do |c|
        new_text += substitute_linefeeds(c)
      end
    end
    return new_text
  end
  

  # Given the root of an XML document, replaces linefeed characters inside <tableOfContents>, <abstract> and <note> XML node by &#10;
  # \n, \r, <br> and <br/> are all replaced by a single &#10;
  # <p> is replaced by two &#10;
  # </p> is removed
  # \r\n is replaced by &#10;
  # Any tags not listed above are removed. MODS 3.5 does not allow for anything other than text inside these three nodes.
  #
  # @param   [Nokogiri::XML::Element]    node  The root node of an XML document
  # @return  [Void]                      This method doesn't return anything, but introduces UTF-8 linefeed characters in place, as described above.
  def clean_linefeeds(node)
    node.xpath("//abstract | //tableOfContents | //note").each do |current_node|
      new_text = substitute_linefeeds(current_node)
      current_node.children.remove
      current_node.content = new_text
    end
  end


  # Cleans up the text of a node:
  #
  # * Removes extra whitespace at the beginning and end.
  # * Removes any consecutive whitespace within the string.
  #
  # @param [String]   s   The text of an XML node.
  # @return [String]  The cleaned string, as described. Returns nil if the input is nil, or if the input is an empty string.
  def clean_text(s)
    return nil unless s != nil && s != ""
    return s.gsub!(/\s+/, " ").strip!
  end



  # Removes empty attributes from a given node.
  #
  # @param [Nokogiri::XML::Element]   node An XML node.
  # @return [Void]                    This method doesn't return anything, but modifies the XML tree starting at the given node.
  def remove_empty_attributes(node)
    children = node.children
    attributes = node.attributes
    
    for key, value in attributes do
      if(value.to_s.strip.empty?)
        node.remove_attribute(key)
      end
    end

    children.each do |c|
      remove_empty_attributes(c)
    end
  end



  # Removes empty nodes from an XML tree. See {#exceptional?} for nodes that are kept even if empty.
  #
  # @param  [Nokogiri::XML::Element]   node An XML node.
  # @return [Void]                     This method doesn't return anything, but modifies the XML tree starting at the given node.
  def remove_empty_nodes(node)
    children = node.children

    if(node.text?)
      if(node.to_s.strip.empty?)
        node.remove
      else
        return
      end
    elsif(children.length > 0)
      children.each do |c|
        remove_empty_nodes(c)
      end
    end

    if(!exceptional?(node) && (node.children.length == 0))
      node.remove
    end
  end


  # Removes leading and trailing spaces from a node.
  #
  # @param  [Nokogiri::XML::Element]  node An XML node.
  # @return [Void]                    This method doesn't return anything, but modifies the entire XML tree starting at the
  #                                   the given node, removing leading and trailing spaces from all text. If the input is nil,
  #                                   an exception will be raised.
  def trim_text(node)
    children = node.children

    if(node.text?)
      node.parent.content = node.text.strip
    else
      children.each do |c|
        trim_text(c)
      end
    end
  end


  # Removes the point attribute from single <dateCreated> and <dateIssued> elements.
  #
  # @param [Nokogiri::XML::Element]   root  The root of a MODS XML document.
  # @return [Void]                    The given document is modified in place.
  def clean_date_attributes(root)
    
    # Find all the <dateCreated> and <dateIssued> elements that are NOT immediately followed by another element with the same name
    root.xpath('//mods:originInfo/mods:dateCreated[1][not(following-sibling::*[1][self::mods:dateCreated])] | //mods:originInfo/mods:dateIssued[1][not(following-sibling::*[1][self::mods:dateIssued])]', 'mods' => 'http://www.loc.gov/mods/v3').each do |current_element|
      attributes = current_element.attributes
      if(attributes.has_key?('point'))
        current_element.remove_attribute('point')
      end
    end
  end


  # Sometimes there are spurious decimal digits within the date fields. This method removes any trailing decimal points within
  # <dateCreated> and <dateIssued>.
  #
  # @param [Nokogiri::XML::Element]   root  The root of a MODS XML document.
  # @return [Void]                    The given document is modified in place.
  def clean_date_values(root)
    root.xpath('//mods:dateCreated | //mods:dateIssued', 'mods' => 'http://www.loc.gov/mods/v3').each do |current_node|
      current_node.content = current_node.content.sub(/(.*)\.\d+$/, '\1')
    end
  end


  # Normalizes the given XML document according to the Stanford guidelines.
  #
  # @param  [Nokogiri::XML::Element]  root  The root of a MODS XML document.
  # @return [Void]                    The given document is modified in place.
  def normalize_document(root)
    remove_empty_attributes(root)
    remove_empty_nodes(root)
    trim_text(root)
    clean_linefeeds(root)
    clean_date_attributes(root)
    clean_date_values(root)
  end


  # Normalizes the given XML document string according to the Stanford guidelines.
  #
  # @param  [String]   xml_string    An XML document
  # @return [String]                 The XML string, with normalizations applied.
  def normalize_xml_string(xml_string)
    doc = Nokogiri::XML(xml_string)
    normalize_document(doc.root)
    doc.to_s
  end
end
