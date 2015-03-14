# Normalizing MODS XML.

require 'nokogiri'

class Normalizer
  # Checks if a node has attributes that we make exeptions for. There are three such exceptions.
  #
  # * The presence of a valueURI attribute on any node.
  # * A "collection" attribute with the value "yes" <em>on a typeOfResource tag</em>.
  # * A "manuscript" attribute with the value "yes" <em>on a typeOfResource tag</em>.
  #
  # Nodes that fall under any of these exceptions should not be deleted, even if they have no content.
  #
  # @param  [Nokogiri::XML::Element]   node    An XML node.
  # @return [Boolean]                  true if the node contains any of the exceptional attributes, false otherwise.
  def exceptional?(node)
    tag = node.name
    attributes = node.attributes

    if(attributes.empty?)
      return false
    end

    for key, value in attributes do
      if(key == "valueURI")
        return true
      end

      # Do we care about accounting for spelling mistakes by lowercasing everything???
      if(tag == "typeOfResource")
        if((key == "collection" && value == "yes") ||
           (key == "manuscript" && value == "yes"))
          return true
        end
      end
    end
    return false
  end



  # Removes empty attributes from a given node, except for <em>valueURI</em> attributes (see the exceptional? method).
  #
  # @param [Nokogiri::XML::Element]   node An XML node.
  # @return [Void]                    This method doesn't return anything, but modifies the XML tree starting at the given node.
  def remove_empty_attributes(node)
    attributes = node.attributes

    for key, value in attributes do
      # puts("class of key is #{key.class()} and value class is #{value.class()}")
      # puts("value of key #{key} is #{value}")
      if(value.to_s.strip.empty?)
        if(key != "valueURI")
          node.remove_attribute(key)
        end
      end
    end
  end



  # Removes empty nodes from an XML tree.
  #
  # @param  [Nokogiri::XML::Element]   node An XML node.
  # @return [Void]                     This method doesn't return anything, but modifies the XML tree starting at the given node.
  def remove_empty_nodes(node)
    children = node.children
    #  puts("visiting NODE: #{node.class} with name #{node.name}")
    
    if(node.text?)
      if(node.to_s.strip.empty?)
        #      puts("now removing empty text")
        node.remove
      else
        #      puts("NOT empty text: #{node.to_s}")
        return
      end
    elsif(children.length > 0)
      children.each do |c|
        remove_empty_nodes(c)
      end
    end

    if(!exceptional?(node) && (node.children.length == 0))
      #    puts("now removing no children")
      node.remove
    end
  end


  # Removes leading and trailing spaces.
  #
  # @param  [Nokogiri::XML::Element]  node An XML node.
  # @return [Void]                    This method doesn't return anything, but modifies the entire XML tree starting at the
  #                                   the given node, removing leading and trailing spaces from all text.
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
