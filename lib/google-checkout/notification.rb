
module GoogleCheckout

  ##
  # Base notification class. Parses incoming XML and returns a class
  # matching the kind of notification being received.
  #
  # This makes it easy to handle events in your code.
  #
  #   notification = GoogleCheckout::Notification.parse(request.raw_post)
  #   case notification
  #   when GoogleCheckout::NewOrderNotification
  #     do_something_with_new_order
  #   end
  #
  # TODO Document field access and Nokogiri object access.
  #
  # For the details, see http://code.google.com/apis/checkout/developer/index.html

  class Notification

    # The Nokogiri XML document received from Google.
    def doc
      @doc ||= Nokogiri::XML::Builder.new
    end

    ##
    # The entry point for notifications.
    #
    # Returns a corresponding notification object based on
    # the XML received.

    def self.parse(raw_xml)
      doc = Nokogiri::XML(raw_xml)

      # Convert +request-received+ to +request_received+,
      # then to a +RequestReceived+ object of the proper class 
      # which will be created and returned.
      const_name = ActiveSupport::Inflector.camelize(doc.root.name.gsub('-', '_'))
      if GoogleCheckout.const_get(const_name)
        return GoogleCheckout.const_get(const_name).new(doc)
      end
    end

    def initialize(doc) # :nodoc:
      @doc = doc
    end

    ##
    # Returns the financial-order-state (or new-financial-order-state).
    #
    # This is a shortcut since this state will be accessed frequently.
    #
    # The fulfillment-order-state (and variations) can be accessed
    # with the more explicit syntax:
    #
    #   notification.fulfillment_order_state
    #
    # The following is from http://code.google.com/apis/checkout/developer/index.html
    #
    # The <financial-order-state> tag identifies the financial status of an order. Valid values for this tag are:
    #
    #   REVIEWING - Google Checkout is reviewing the order.
    #   CHARGEABLE - The order is ready to be charged.
    #   CHARGING -  The order is being charged; you may not refund or cancel an
    #               order until is the charge is completed.
    #   CHARGED -   The order has been successfully charged; if the order was
    #               only partially charged, the buyer's account page will
    #               reflect the partial charge.
    #   PAYMENT_DECLINED - The charge attempt failed.
    #   CANCELLED - The seller canceled the order; an order's financial state
    #               cannot be changed after the order is canceled.
    #   CANCELLED_BY_GOOGLE - Google canceled the order. Google may cancel
    #               orders due to a failed charge without a replacement credit
    #               card being provided within a set period of time or due to a
    #               failed risk check. If Google cancels an order, you will be
    #               notified of the reason the order was canceled in the <reason>
    #               tag of an <order-state-change-notification>.
    #
    # Please see the Order States section for more information about these states.

    def state
      if (doc.at 'financial-order-state')
        return (doc/'financial-order-state').inner_html
      elsif (doc.at 'new-financial-order-state')
        return (doc/'new-financial-order-state').inner_html
      end
    end

    ##
    # Returns the serial number from the root element.
    
    def serial_number
      doc.root['serial-number']
    end

    ##
    # Returns an XML string that can be sent back to Google to
    # communicate successful receipt of the notification.

    def acknowledgment_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      @xml = xml.tag!('notification-acknowledgment', {
        :xmlns => "http://checkout.google.com/schema/2",
        'serial-number' => serial_number
      })
      @xml
    end

    ##
    # Returns true if this is a GoogleCheckout::Error object.
    
    def error?
      self.class == GoogleCheckout::Error
    end

    ##
    # Take requests for an XML element and returns its value.
    #
    #   notification.google_order_number
    #   => Returns value of '<google-order-number>'
    #
    # Because of how Nokogiri#at works, it will even dig into subtags
    # and return the value of the first matching tag. For example,
    # there is an +email+ field in +buyer-shipping-address+ and also
    # in +buyer-billing-address+, but only the first will be returned.
    #
    # If you want to get at a value explicitly, use +notification.doc+
    # and search the Nokogiri document manually.

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

  class AuthorizationAmountNotification < Notification; end

  class ChargeAmountNotification < Notification

    def latest_charge_amount
      (doc/"latest-charge-amount").to_money
    end

    def total_charge_amount
      (doc/"total-charge-amount").to_money
    end

  end

  class ChargebackAmountNotification < Notification

    def latest_chargeback_amount
      (doc/"latest-chargeback-amount").to_money
    end

    def total_chargeback_amount
      (doc/"total-chargeback-amount").to_money
    end

  end

  class NewOrderNotification < Notification

    ##
    # Returns a Money object representing the total price of the order.
    
    def order_total
      (doc/"order-total").to_money
    end

    ##
    # Returns a Money object representing the total tax added.
    
    def total_tax
      (doc/"total-tax").to_money
    end

    ##
    # Returns true if the buyer wants to received marketing emails.
    
    def email_allowed
      (doc/"buyer-marketing-preferences"/"email-allowed").to_boolean
    end

    ##
    # Returns billing name.

    def billing_name
      (doc/"buyer-billing-address"/"contact-name").inner_html
    end

    ##
    # Returns billing email

    def billing_email
      (doc/"buyer-billing-address"/"email").inner_html
    end

    ##
    # Returns billing address1

    def billing_address1
      (doc/"buyer-billing-address"/"address1").inner_html
    end

    ##
    # Returns billing city

    def billing_city
      (doc/"buyer-billing-address"/"city").inner_html
    end

    ##
    # Returns billing region

    def billing_region
      (doc/"buyer-billing-address"/"region").inner_html
    end

    ##
    # Returns billing postal code

    def billing_postal_code
      (doc/"buyer-billing-address"/"postal-code").inner_html
    end

    ##
    # Returns billing country code

    def billing_country_code
      (doc/"buyer-billing-address"/"country-code").inner_html
    end

    ##
    # Returns billing phone

    def billing_phone
      (doc/"buyer-billing-address"/"phone").inner_html
    end

    ##
    # Returns billing first name

    def billing_first_name
      (doc/"buyer-billing-address"/"structured-name"/"first-name").inner_html
    end

    ##
    # Returns billing last name

    def billing_last_name
      (doc/"buyer-billing-address"/"structured-name"/"last-name").inner_html
    end

    ##
    # Returns shipping contact name

    def shipping_name
      (doc/"buyer-shipping-address"/"contact-name").inner_html
    end

    ##
    # Returns shipping email

    def shipping_email
      (doc/"buyer-shipping-address"/"email").inner_html
    end

    ##
    # Returns shipping address1

    def shipping_address1
      (doc/"buyer-shipping-address"/"address1").inner_html
    end

    ##
    # Returns shipping city

    def shipping_city
      (doc/"buyer-shipping-address"/"city").inner_html
    end

    ##
    # Returns shipping region

    def shipping_region
      (doc/"buyer-shipping-address"/"region").inner_html
    end

    ##
    # Returns shipping postal code

    def shipping_postal_code
      (doc/"buyer-shipping-address"/"postal-code").inner_html
    end

    ##
    # Returns shipping country code

    def shipping_country_code
      (doc/"buyer-shipping-address"/"country-code").inner_html
    end

    ##
    # Returns shipping phone

    def shipping_phone
      (doc/"buyer-shipping-address"/"phone").inner_html
    end

    ##
    # Returns shipping first name

    def shipping_first_name
      (doc/"buyer-shipping-address"/"structured-name"/"first-name").inner_html
    end

    ##
    # Returns shipping last name

    def shipping_last_name
      (doc/"buyer-shipping-address"/"structured-name"/"last-name").inner_html
    end

  end

  class OrderStateChangeNotification < Notification; end

  class RefundAmountNotification < Notification; end

  class RiskInformationNotification < Notification; end

  class CancelledSubscriptionNotification < Notification; end

  class CheckoutRedirect < Notification

    ##
    # Returns redirect-url with ampersands escaped, as specified by Google API docs.

    def redirect_url
      (doc/"redirect-url").inner_html.gsub(/&amp;/, '&')
    end

  end    

  class Error < Notification

    ##
    # Alias for +_error_message+

    def message
      (doc/'error-message').inner_html
    end

  end

  class RequestReceived < Notification; end

  class ApiError < Notification
    attr_reader :error_message

    def initialize(message='')
      @error_message = message
    end

    def error?
      true
    end

    alias :message :error_message

  end

end
