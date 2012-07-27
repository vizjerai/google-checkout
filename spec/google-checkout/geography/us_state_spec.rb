require "spec_helper"

describe GoogleCheckout::Geography::UsState do
  before(:each) do
    @area = GoogleCheckout::Geography::UsState.new('WI')
  end

  it 'should include the state' do
    @area.to_xml.should match(%r{<us-state-area><state>WI</state></us-state-area>})
  end
end
