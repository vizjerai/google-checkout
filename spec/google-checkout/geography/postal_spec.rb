require "spec_helper"

describe GoogleCheckout::Geography::Postal do
  before(:each) do
    @area = GoogleCheckout::Geography::Postal.new('US')
  end

  it 'should generate the postal area tag' do
    @area.to_xml.should match(%r{<postal-area>.*</postal-area>})
  end

  it 'should include the country in the generated xml' do
    @area.country = 'CA'
    @area.to_xml.should match(%r{<country-code>CA</country-code>})
  end

  it 'should not include the postal pattern by default' do
    @area.to_xml.should_not match(%r{<postal-code-pattern>})
  end

  it 'should include the postal pattern when set' do
    @area.postal_pattern = '53*'
    @area.to_xml.should match(%r{<postal-code-pattern>53\*</postal-code-pattern>})
  end

end
