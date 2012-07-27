require "spec_helper"

describe GoogleCheckout::Shipping::FlatRate do
  before(:each) do
    @shipping = GoogleCheckout::Shipping::MerchantCalculated.new('UPS Ground', '10.00')
  end

  it 'should include the name in the generated xml' do
    @shipping.to_xml.should match(%r{<merchant-calculated-shipping name="UPS Ground">})
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

  it 'should include the shipping-restrictions allowed areas in the generated xml' do
    @shipping.shipping_restrictions[:allowed] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<shipping-restrictions>.*<allowed-areas>.*</allowed-areas>.*</shipping-restrictions>})
  end

  it 'should include the shipping-restrictions excluded areas in the generated xml' do
    @shipping.shipping_restrictions[:excluded] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<shipping-restrictions>.*<excluded-areas>.*</excluded-areas>.*</shipping-restrictions>})
  end

  it 'should include the shipping-restrictions allow us po box in the generated xml' do
    @shipping.shipping_restrictions[:allow_us_po_box] = false
    @shipping.to_xml.should match(%r{<shipping-restrictions>.*<allow-us-po-box>false</allow-us-po-box>.*</shipping-restrictions>})
  end

  it 'should generate the address filters tag if they are set' do
    @shipping.address_filters[:allowed] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<address-filters>.*</address-filters>})
  end

  it 'should not generate the address filters tag if they are not set' do
    @shipping.to_xml.should_not match(%r{<address-filters>.*</address-filters>})
  end

  it 'should include the address filters allowed areas in the generated xml' do
    @shipping.address_filters[:allowed] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<address-filters>.*<allowed-areas>.*</allowed-areas>.*</address-filters>})
  end

  it 'should include the address filters excluded areas in the generated xml' do
    @shipping.address_filters[:excluded] << GoogleCheckout::Geography::UsState.new('WI')
    @shipping.to_xml.should match(%r{<address-filters>.*<excluded-areas>.*</excluded-areas>.*</address-filters>})
  end

  it 'should include the address filters allow us po box in the generated xml' do
    @shipping.address_filters[:allow_us_po_box] = false
    @shipping.to_xml.should match(%r{<address-filters>.*<allow-us-po-box>false</allow-us-po-box>.*</address-filters>})
  end

end
