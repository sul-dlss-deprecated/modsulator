# File "normalizer.rb" - defines a class for normalizing MODS XML according to the Stanford guidelines.

require 'nokogiri'

# This class provides methods to normalize MODS XML according to the Stanford guidelines.
# @see https://consul.stanford.edu/display/chimera/MODS+validation+and+normalization Requirements (Stanford Consul page)
class Normalizer
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



  # Removes empty attributes from a given node, except for <em>valueURI</em> attributes (see the exceptional? method).
  #
  # @param [Nokogiri::XML::Element]   node An XML node.
  # @return [Void]                    This method doesn't return anything, but modifies the XML tree starting at the given node.
  def remove_empty_attributes(node)
    children = node.children
    attributes = node.attributes
    
    for key, value in attributes do
      if(value.to_s.strip.empty?)
        if(key != "valueURI")
          node.remove_attribute(key)
        end
      end
    end

    children.each do |c|
      remove_empty_attributes(c)
    end
  end



  # Removes empty nodes from an XML tree.
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


  # Removes leading and trailing spaces from a text node.
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
end
