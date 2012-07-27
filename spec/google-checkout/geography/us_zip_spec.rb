require "spec_helper"

describe GoogleCheckout::Geography::UsZip do
  before(:each) do
    @area = GoogleCheckout::Geography::UsZip.new('53*')
  end

  it 'should generate the us zip area tag' do
    @area.to_xml.should match(%r{<us-zip-area>.*</us-zip-area>})
  end
end
