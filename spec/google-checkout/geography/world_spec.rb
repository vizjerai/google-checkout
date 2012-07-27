require "spec_helper"

describe GoogleCheckout::Geography::World do
  before(:each) do
    @area = GoogleCheckout::Geography::World.new
  end

  it 'should generate a self closing world tag' do
    @area.to_xml.should eql("<world-area/>")
  end

end
