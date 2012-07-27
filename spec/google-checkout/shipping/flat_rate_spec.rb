require "spec_helper"

describe GoogleCheckout::Shipping::FlatRate do
  before(:each) do
    @shipping = GoogleCheckout::Shipping::FlatRate.new('UPS Ground', '10.00')
  end

  it 'should include the name in the generated xml' do
    @shipping.to_xml.should match(%r{<flat-rate-shipping name="UPS Ground">})
  end

  it 'should include the price in the generated xml' do
    @shipping.price = '1.00'
    @shipping.to_xml.should match(%r{<price .*>1.00</price>})
  end

  it 'should include the currency in the generated xml' do
    @shipping.currency = 'CAD'
    @shipping.to_xml.should match(%r{<price currency="CAD">})
  end

  it 'should generate the shipping-restrictions tag if they are set' do
    @shipping.shipping_restrictions[:allowed] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<shipping-restrictions>.*</shipping-restrictions>})
  end

  it 'should not generate the shipping-restrictions tag if they are not set' do
    @shipping.to_xml.should_not match(%r{<shipping-restrictions>.*</shipping-restrictions>})
  end

  it 'should include the allowed areas in the generated xml' do
    @shipping.shipping_restrictions[:allowed] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<allowed-areas>.*</allowed-areas>})
  end

  it 'should include the excluded areas in the generated xml' do
    @shipping.shipping_restrictions[:excluded] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<excluded-areas>.*</excluded-areas>})
  end

  it 'should include the all us po box in the generated xml' do
    @shipping.shipping_restrictions[:allow_us_po_box] = false
    @shipping.to_xml.should match(%r{<allow-us-po-box>false</allow-us-po-box>})
  end

end
