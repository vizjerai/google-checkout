require "spec_helper"

describe GoogleCheckout, "New Order Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/new-order-notification'))
  end

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::NewOrderNotification)
  end

  it_should_behave_like "basic notification"

  it "should find fulfillment order state" do
    @notification.fulfillment_order_state.should == 'NEW'
  end

  it "should find financial order state" do
    @notification.financial_order_state.should == 'REVIEWING'
  end

  it "should use financial state shortcut" do
    @notification.state.should == "REVIEWING"
  end

  it "should create Money object from order total" do
    @notification.order_total.should be_kind_of(Money)
    @notification.order_total.cents.should == 19098
    @notification.order_total.currency.iso_code.should == 'USD'
  end

  it "should throw error when accessing non-existent value" do
    lambda { @notification.there_is_no_field_with_this_name }.should raise_error(NoMethodError)
  end

  it "should find sub-keys of merchant-private-data as if they were at the root" do
    @notification.peepcode_order_number.should == '1234-5678-9012'
  end

  it "should find total tax" do
    @notification.total_tax.should be_kind_of(Money)
    @notification.total_tax.cents.should == 0
  end

  it "should find email marketing allowed" do
    @notification.email_allowed.should be_false
  end

  it "should get buyer-billing-address/contact-name" do
    @notification.billing_name.should == 'Bill Hu'
  end

  it "should get buyer-billing-address/email" do
    @notification.billing_email.should == 'billhu@example.com'
  end

  it "should get buyer-billing-address/address1" do
    @notification.billing_address1.should == '99 Credit Lane'
  end

  it "should get buyer-billing-address/city" do
    @notification.billing_city.should == 'Mountain View'
  end

  it "should get buyer-billing-address/region" do
    @notification.billing_region.should == 'CA'
  end

  it "should get buyer-billing-address/postal-code" do
    @notification.billing_postal_code.should == '94043'
  end

  it "should get buyer-billing-address/country-code" do
    @notification.billing_country_code.should == 'US'
  end

  it "should get buyer-billing-address/phone" do
    @notification.billing_phone.should == '5555557890'
  end

  it "should get buyer-billing-address/structured-name/first-name" do
    @notification.billing_first_name.should == 'Bill'
  end

  it "should get buyer-billing-address/structured-name/last-name" do
    @notification.billing_last_name.should == 'Hu'
  end

  it "should get buyer-shipping-address/contact-name" do
    @notification.shipping_name.should == 'John Smith'
  end

  it "should get buyer-shipping-address/email" do
    @notification.shipping_email.should == 'johnsmith@example.com'
  end

  it "should get buyer-shipping-address/address1" do
    @notification.shipping_address1.should == '10 Example Road'
  end

  it "should get buyer-shipping-address/city" do
    @notification.shipping_city.should == 'Sampleville'
  end

  it "should get buyer-shipping-address/region" do
    @notification.shipping_region.should == 'CA'
  end

  it "should get buyer-shipping-address/postal-code" do
    @notification.shipping_postal_code.should == '94141'
  end

  it "should get buyer-shipping-address/country-code" do
    @notification.shipping_country_code.should == 'US'
  end

  it "should get buyer-shipping-address/phone" do
    @notification.shipping_phone.should == '5555551234'
  end

  it "should get buyer-shipping-address/structured-name/first-name" do
    @notification.shipping_first_name.should == 'John'
  end

  it "should get buyer-shipping-address/structured-name/last-name" do
    @notification.shipping_last_name.should == 'Smith'
  end

end


describe GoogleCheckout, "Order State Change Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/order-state-change-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::OrderStateChangeNotification)
  end

  it "should find new financial state" do
    @notification.new_financial_order_state.should == 'CHARGING'
  end

  it "should find new fulfillment state" do
    @notification.new_fulfillment_order_state.should == 'NEW'
  end

  it "should use financial state shortcut" do
    @notification.state.should == 'CHARGING'
  end

end

describe GoogleCheckout, "Risk Information Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/risk-information-notification'))
  end

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::RiskInformationNotification)
  end

  it_should_behave_like "basic notification"

end

describe GoogleCheckout, "Charge Amount Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/charge-amount-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::ChargeAmountNotification)
  end

  it "should get latest charge amount" do
    @notification.latest_charge_amount.should be_kind_of(Money)
  end

  it "should get total charge amount" do
    @notification.total_charge_amount.should be_kind_of(Money)
    @notification.total_charge_amount.cents.should == 22606
  end

end

describe GoogleCheckout, "Authorization Amount Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/authorization-amount-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::AuthorizationAmountNotification)
  end

end

describe GoogleCheckout, "Chargeback Amount Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/chargeback-amount-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::ChargebackAmountNotification)
  end

  it "parses chargeback amounts as money objects" do
    @notification.latest_chargeback_amount.cents.should == 22606
    @notification.total_chargeback_amount.cents.should == 22606
    @notification.latest_chargeback_amount.currency.iso_code.should == 'USD'
  end

end

describe GoogleCheckout, "Refund Amount Notification" do

  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/refund-amount-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::RefundAmountNotification)
  end

end

describe GoogleCheckout, "Cancelled Order Notification" do
  
  before(:each) do
    @notification = GoogleCheckout::Notification.parse(read_xml_fixture('notifications/cancelled-subscription-notification'))
  end

  it_should_behave_like "basic notification"

  it "should identify type of notification" do
    @notification.should be_kind_of(GoogleCheckout::CancelledSubscriptionNotification)
  end  
    
end

describe GoogleCheckout, "Error Notification" do
  let(:notification) { GoogleCheckout::Notification.parse(read_xml_fixture('responses/error')) }

  it "should identify type of notication" do
    notification.should be_kind_of GoogleCheckout::Error
  end

  it "should have error message" do
    notification.error_message.should == 'Bad username and/or password for API Access.'
  end

  it "should have message" do
    notification.message.should == 'Bad username and/or password for API Access.'
  end

end

describe GoogleCheckout, 'Api Error Notification' do
  let(:notification) { GoogleCheckout::ApiError.new 'Unexpected Error' }

  it "should identify type of notication" do
    notification.should be_kind_of GoogleCheckout::ApiError
  end

  it "should have error message" do
    notification.error_message.should == 'Unexpected Error'
  end

  it "should have message" do
    notification.message.should == 'Unexpected Error'
  end

end
