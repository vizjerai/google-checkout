##
# Ref:
#
#  https://sandbox.google.com/checkout/cws/v2/Merchant/MERCHANT_ID/merchantCheckout
#  https://checkout.google.com/cws/v2/Merchant/MERCHANT_ID/merchantCheckout

require 'active_support'

require 'openssl'
require 'base64'
require 'builder/xmlmarkup'
require 'nokogiri'
require 'money'
require 'net/https'

require 'duck_punches/nokogiri'
require 'duck_punches/inflector'
require 'google-checkout/notification'
require 'google-checkout/merchant_calculation'
require 'google-checkout/command'
require 'google-checkout/cart'

require 'google-checkout/shipping'
require 'google-checkout/geography'

##
# TODO
# 
#   * Analytics integration
#     http://code.google.com/apis/checkout/developer/checkout_analytics_integration.html

module GoogleCheckout

  @@live_system = true
  
  ##
  # Submit commands to the Google Checkout test servers.
  
  def self.use_sandbox
    @@live_system = false
  end
  
  ##
  # The default.
  
  def self.use_production
    @@live_system = true
  end

  def self.sandbox?
    !@@live_system
  end

  def self.production?
    @@live_system
  end

end
