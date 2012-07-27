require "spec_helper"

describe GoogleCheckout, "Merchant Calculation" do

  before(:each) do
    @calculation = GoogleCheckout::MerchantCalculation.parse(read_xml_fixture('merchant_calculations/shipping'))
  end

  it "should find buyer language" do
    @calculation.buyer_language.should == 'en_US'
  end

  it "should find the address id" do
    @calculation.address_id.should == "739030698069958"
  end

end
