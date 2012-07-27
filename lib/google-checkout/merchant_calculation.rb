module GoogleCheckout
  class MerchantCalculation

    def doc
      @doc ||= Nokogiri::XML::Builder.new
    end

    def self.parse(raw_xml)
      doc = Nokogiri::XML(raw_xml)
      return new(doc)
    end

    def initialize(doc) # :nodoc:
      @doc = doc
    end

    def address_id
      (doc/"anonymous-address").attr('id').value
    end

    def method_missing(method_name, *args)
      element_name = method_name.to_s.gsub(/_/, '-')
      if element = (doc.at element_name)
        if element.respond_to?(:inner_html)
          return element.inner_html
        end
      end
      super
    end

  end
end
