
module GoogleCheckout

  # These are the only sizes allowed by Google.  These shouldn't be needed
  # by most people; just specify the :size and :buy_or_checkout options to
  # Cart#checkout_button and the sizes are filled in automatically.
  ButtonSizes = {
    :checkout => {
      :small => { :w => 160, :h => 43 },
      :medium => { :w => 168, :h => 44 },
      :large => { :w => 180, :h => 46 },
    },

    :buy_now => {
      :small => { :w => 117, :h => 48 },
      :medium => { :w => 121, :h => 44 },
      :large => { :w => 121, :h => 44 },
    },
  }

  ##
  # This class represents a cart for Google Checkout.  After initializing it
  # with a +merchant_id+ and +merchant_key+, you add items via add_item,
  # and can then get xml via to_xml, or html code for a form that
  # provides a checkout button via checkout_button.
  #
  # Example:
  #
  #   item = {
  #            :name => 'A Quarter',
  #            :description => 'One shiny quarter.',
  #            :price => 0.25
  #          }
  #   @cart = GoogleCheckout::Cart.new(merchant_id, merchant_key, item)
  #   @cart.add_item(:name => "Pancakes",
  #                  :description => "Flapjacks by mail."
  #                  :price => 0.50,
  #                  :quantity => 10,
  #                  "merchant-item-id" => '2938292839')
  #
  # Then in your view:
  #
  #   Checkout here! <%= @cart.checkout_button %>
  #
  # This object is also useful for getting back a url to the image for a Google
  # Checkout button. You can use this image in forms that submit back to your own
  # server for further processing via Google Checkout's level 2 XML API.

  class Cart < Command

    include GoogleCheckout

    SANDBOX_CHECKOUT_URL    = "https://sandbox.google.com/checkout/cws/v2/Merchant/%s/checkout"
    PRODUCTION_CHECKOUT_URL = "https://checkout.google.com/cws/v2/Merchant/%s/checkout"

    ##
    # You can provide extra data that will be sent to Google and returned with
    # the NewOrderNotification.
    #
    # This should be a Hash and will be turned into XML with proper escapes.
    #
    # Beware using symbols as values. They may be set as sub-keys instead of values,
    # so use a String or other datatype.
    attr_reader :contents

    attr_accessor :merchant_private_data

    attr_accessor :edit_cart_url
    attr_accessor :continue_shopping_url

    attr_accessor :merchant_calculations_url
    attr_accessor :parameterized_urls

    attr_accessor :shipping_methods

    # The default options for drawing in the button that are filled in when
    # checkout_button or button_url is called.
    DefaultButtonOpts = {
      :size => :medium,
      :style => 'white',
      :variant => 'text',
      :loc => 'en_US',
      :buy_or_checkout => nil,
    }

    # You need to supply, as strings, the +merchant_id+ and +merchant_key+
    # used to identify your store to Google.  You may optionally supply one
    # or more items to put inside the cart.
    def initialize(merchant_id, merchant_key, *items)
      super(merchant_id, merchant_key)
      @contents = []
      @merchant_private_data = ''
      @shipping_methods = []
      items.each { |i| add_item i }
    end

    def empty?
      @contents.empty?
    end

    def merchant_private_data=(value)
      if value.is_a?(Hash)
        xml = Builder::XmlMarkup.new
        value.each do |key, value|
          xml.tag!(key, value)
        end
        @merchant_private_data = xml.target!
      elsif value.is_a?(String)
        @merchant_private_data = value
      end
    end

    # Number of items in the cart.
    def size
      @contents.size
    end

    def submit_domain
      (GoogleCheckout.production? ? 'checkout' : 'sandbox') + ".google.com"
    end

    ##
    # The Google Checkout form submission url.

    def submit_url
      GoogleCheckout.sandbox? ? (SANDBOX_CHECKOUT_URL % @merchant_id) : (PRODUCTION_CHECKOUT_URL % @merchant_id)
    end

    # This method puts items in the cart.
    # +item+ may be a hash, or have a method named +to_google_product+ that
    # returns a hash with the required values.
    # * name
    # * description (a brief description as it will appear on the bill)
    # * price
    # You may fill in some optional values as well:
    # * quantity (defaults to 1)
    # * currency (defaults to 'USD')
    # 
    # * subscription
    # ** type (defaults to 'google')
    # ** period (defaults to 'MONTHLY')
    # ** start_date
    # ** no_charge_after
    # ** payment_times
    # ** max_charge
    # ** name
    # ** description
    # ** price
    # ** quantity
    # 
    # * digital_content
    # ** disposition
    # ** description
    
    def add_item(item)
      @xml = nil
      if item.respond_to? :to_google_product
        item = item.to_google_product
      end

      # We need to check that the necessary keys are in the hash,
      # Otherwise the error will happen in the middle of to_xml,
      # and the bug will be harder to track.
      missing_keys = [ :name, :description, :price ].select { |key|
        !item.include? key
      }

      unless missing_keys.empty?
        raise ArgumentError,
        "Required keys missing: #{missing_keys.inspect}"
      end

      @contents << { :quantity => 1, :currency => 'USD' }.merge(item)
      item
    end

    # This is the important method; it generatest the XML call.
    # It's fairly lengthy, but trivial.  It follows the docs at
    # http://code.google.com/apis/checkout/developer/index.html#checkout_api
    #
    # It returns the raw XML string, not encoded.
    def to_xml
      raise RuntimeError, "Empty cart" if self.empty?

      xml = Builder::XmlMarkup.new
      xml.instruct!
      @xml = xml.tag!('checkout-shopping-cart', :xmlns => "http://checkout.google.com/schema/2") {
        xml.tag!("shopping-cart") {
          xml.items {
            @contents.each { |item|
              xml.item {
                if item.key?(:item_id)
                  xml.tag!('merchant-item-id', item[:item_id])
                end
                xml.tag!('item-name') {
                  xml.text! item[:name].to_s
                }
                xml.tag!('item-description') {
                  xml.text! item[:description].to_s
                }
                xml.tag!('unit-price', :currency => (item[:currency] || 'USD')) {
                  xml.text! item[:price].to_s
                }
                xml.quantity {
                  xml.text! item[:quantity].to_s
                }
                
                # subscription item
                if item.key?(:subscription)
                  sub = item[:subscription]
                  
                  sub_opts = {}
                  sub_opts.merge!(:type => sub[:type].to_s) if sub[:type]
                  sub_opts.merge!(:period => sub[:period].to_s) if sub[:period]
                  sub_opts.merge!(:"start-date" => sub[:start_date].to_s) if sub[:start_date] 
                  sub_opts.merge!(:"no-charge-after" => sub[:no_charge_after].to_s) if sub[:no_charge_after]
                  
                  xml.subscription(sub_opts) {
                    xml.payments {
                      if sub.key?(:payment_times)
                        xml.tag!('subscription-payment', :times => sub[:payment_times].to_s) {
                          xml.tag!('maximum-charge', :currency => (item[:currency] || 'USD')) {
                            xml.text! sub[:max_charge].to_s
                          }
                        }
                      else
                        xml.tag!('subscription-payment') {
                          xml.tag!('maximum-charge', :currency => (item[:currency] || 'USD')) {
                            xml.text! sub[:max_charge].to_s
                          }
                        }
                      end
                    }
                    
                    xml.tag!('recurrent-item') {
                      xml.tag!('item-name') {
                        xml.text! sub[:name].to_s
                      }
                      xml.tag!('item-description') {
                        xml.text! sub[:description].to_s
                      }
                      xml.tag!('unit-price', :currency => (item[:currency] || 'USD')) {
                        xml.text! sub[:price].to_s
                      }
                      xml.quantity {
                        xml.text! sub[:quantity].to_s
                      }
                    }
                  }
                end
                
                # digital delivery
                if item.key?(:digital_content)
                  content = item[:digital_content]
                  
                  xml.tag!('digital-content') {
                    xml.tag!('display-disposition') {
                      xml.text! content[:disposition]
                    }
                    xml.description {
                      xml.text! content[:description].to_s
                    } if content[:description]
                  }
                end
                
                xml.tag!('merchant-private-item-data') {
                  xml << item[:merchant_private_item_data]
                } if item.key?(:merchant_private_item_data)
              }
            }
          }
          unless @merchant_private_data.nil? || @merchant_private_data.empty?
            xml.tag!("merchant-private-data") {
              xml << @merchant_private_data
            }
          end
        }
        xml.tag!('checkout-flow-support') {
          xml.tag!('merchant-checkout-flow-support') {
            xml.tag!('edit-cart-url', @edit_cart_url) if @edit_cart_url
            xml.tag!('continue-shopping-url', @continue_shopping_url) if @continue_shopping_url
            xml.tag!("request-buyer-phone-number", false)
            xml.tag!('merchant-calculations') {
              xml.tag!('merchant-calculations-url') {
                xml.text! @merchant_calculations_url
              }
            } if @merchant_calculations_url

            # TODO tax-tables

            xml.tag!('parameterized-urls') {
              @parameterized_urls.each do |param_url|
                xml.tag!('parameterized-url', :url => param_url[:url]) {
                  next if param_url[:parameters].nil?
                  next if param_url[:parameters].empty?
                  xml.tag!('parameters') {
                    param_url[:parameters].each do |parameter|
                      xml.tag!('url-parameter', :name => parameter[:name], :type => parameter[:type]) {}
                    end
                  }
                }
              end
            } unless @parameterized_urls.nil? || @parameterized_urls.empty?

            xml.tag!('shipping-methods') {
              @shipping_methods.each do |shipping_method|
                xml << shipping_method.to_xml
              end
            }
          }
        }
      }
      @xml.dup
    end

    # Returns the signature for the cart XML.
    def signature
      @xml or to_xml
      digest = OpenSSL::Digest::Digest.new('sha1')
      OpenSSL::HMAC.digest(digest, @merchant_key, @xml)
    end

    # Returns HTML for a checkout form for buying all the items in the
    # cart.
    def checkout_button(button_opts = {})
      @xml or to_xml
      burl = button_url(button_opts)
      html = Builder::XmlMarkup.new(:indent => 2)
      html.form({
        :action => submit_url,
        :style => 'border: 0;',
        :id => 'BB_BuyButtonForm',
        :method => 'post',
        :name => 'BB_BuyButtonForm'
      }) do
        html.input({
          :name => 'cart',
          :type => 'hidden',
          :value => Base64.encode64(@xml).gsub("\n", '')
        })
        html.input({
          :name => 'signature',
          :type => 'hidden',
          :value => Base64.encode64(signature).gsub("\n", '')
        })
        html.input({
          :alt => 'Google Checkout',
          :style => "width: auto;",
          :src => button_url(button_opts),
          :type => 'image'
        })
      end
    end

    # Given a set of options for the button, button_url returns the URL
    # for the button image.
    # The options are the same as those specified on
    # http://checkout.google.com/seller/checkout_buttons.html , with a
    # couple of extra options for convenience.  Rather than specifying the
    # width and height manually, you may specify :size to be one of :small,
    # :medium, or :large, and that you may set :buy_or_checkout to :buy_now
    # or :checkout to get a 'Buy Now' button versus a 'Checkout' button. If
    # you don't specify :buy_or_checkout, the Cart will try to guess based
    # on if the cart has more than one item in it.  Whatever you don't pass
    # will be filled in with the defaults from DefaultButtonOpts.
    #
    #   http://checkout.google.com/buttons/checkout.gif
    #   http://sandbox.google.com/checkout/buttons/checkout.gif

    def button_url(opts = {})
      opts = DefaultButtonOpts.merge opts
      opts[:buy_or_checkout] ||= @contents.size > 1 ? :checkout : :buy_now
      opts.merge! ButtonSizes[opts[:buy_or_checkout]][opts[:size]]
      bname = opts[:buy_or_checkout] == :buy_now ? 'buy.gif' : 'checkout.gif'
      opts.delete :size
      opts.delete :buy_or_checkout
      opts[:merchant_id] = @merchant_id

      path = opts.map { |k,v| "#{k}=#{v}" }.join('&')

      # HACK Sandbox graphics are in the checkout subdirectory
      subdir = ""
      if GoogleCheckout.sandbox? && (bname == "checkout.gif" || bname == "buy.gif")
        subdir = "checkout/"
      end

      protocol = opts[:https] ? 'https' : 'http'

      # TODO Use /checkout/buttons/checkout.gif if in sandbox.
      "#{protocol}://#{submit_domain}/#{ subdir }buttons/#{bname}?#{path}"
    end
  end

end
