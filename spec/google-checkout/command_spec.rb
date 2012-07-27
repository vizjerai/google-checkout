require "spec_helper"

describe GoogleCheckout, "Command class" do

  it "should read SSL certs" do
    GoogleCheckout::Command.x509_store.should be_kind_of(OpenSSL::X509::Store)
  end

end

describe GoogleCheckout, "Command instance" do

  before(:each) do
    @command = GoogleCheckout::Command.new("my_id", "my_key")
  end

  it "should generate sandbox url" do
    GoogleCheckout.use_sandbox
    @command.url.should match(/sandbox/)
  end

  it "should generate production url" do
    GoogleCheckout.use_production
    @command.url.should match(/checkout\.google\.com/)
  end

end

describe GoogleCheckout, "Charge Order" do

  before(:each) do
    @order = GoogleCheckout::ChargeOrder.new("my_id", "my_key", "1234567890")
    GoogleCheckout.use_sandbox
    @order.amount = 123.45
  end

  it_should_behave_like "basic command"

  it "should retrieve order number" do
    @order.google_order_number.should == '1234567890'
  end

  it "should get merchant_id" do
    @order.merchant_id.should == 'my_id'
  end

  it "should get merchant_key" do
    @order.merchant_key.should == 'my_key'
  end

  it "should generate XML" do
    @order.to_xml.should match(/amount currency="USD"/)
    @order.to_xml.should match(/123\.45<\/amount>/)
  end

  it "should post request to Google successfully" do
    # :null_object means eat all other methods and return self
    net_http = double("net_http").as_null_object
    Net::HTTP.should_receive(:new).and_return(net_http)

    success_response = Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK")
    success_response.should_receive(:body).and_return(read_xml_fixture('responses/request-received'))
    net_http.should_receive(:request).and_return(success_response)

    response = @order.post
    response.should be_kind_of(GoogleCheckout::RequestReceived)
    response.should_not be_error
    response.serial_number.should == 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614'
  end

  it "should post request to Google and return error" do
    # :null_object means eat all other methods and return self
    net_http = double("net_http").as_null_object
    Net::HTTP.should_receive(:new).and_return(net_http)

    # NOTE HTTP response code is irrelevant here.
    error_response = Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK")
    error_response.should_receive(:body).and_return(read_xml_fixture('responses/error'))
    net_http.should_receive(:request).and_return(error_response)

    response = @order.post
    response.should be_kind_of(GoogleCheckout::Error)
    response.should be_error
    response.serial_number.should == 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614'
    response.error_message.should == 'Bad username and/or password for API Access.'
    response.message.should == 'Bad username and/or password for API Access.'
  end

  it "should post request to Google and return error charged already" do
    net_http = double("net_http").as_null_object
    Net::HTTP.should_receive(:new).and_return(net_http)

    # NOTE HTTP response code is irrelevant here.
    error_response = Net::HTTPSuccess.new(Net::HTTP.version_1_2, 200, "OK")
    error_response.should_receive(:body).and_return(read_xml_fixture('responses/error-charged'))
    net_http.should_receive(:request).and_return(error_response)

    response = @order.post
    response.should be_kind_of(GoogleCheckout::Error)
    response.should be_error
    response.serial_number.should == 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614'
    response.error_message.should == 'You cannot charge an order that is already completely charged'
    response.message.should == 'You cannot charge an order that is already completely charged'
  end

  context 'with Net::HTTPRedirection response' do
    before do
      net_http = double('net_http').as_null_object
      Net::HTTP.should_receive(:new).and_return(net_http)

      response = Net::HTTPRedirection.new(Net::HTTP.version_1_2, 301, "Redirect")
      net_http.should_receive(:request).and_return(response)
    end

    it "return error" do
      response = @order.post
      response.should be_kind_of(GoogleCheckout::ApiError)
      response.should be_error
      response.serial_number.should be_nil
      response.message.should == 'Unexpected response code (Net::HTTPRedirection): 301 - Redirect'
    end
  end

  context 'with HTTPUnknownResponse response' do
    before do
      net_http = double('net_http').as_null_object
      Net::HTTP.should_receive(:new).and_return(net_http)

      response = Net::HTTPUnknownResponse.new(Net::HTTP.version_1_2, 600, "Unknown Response")
      net_http.should_receive(:request).and_return(response)
    end

    it "return error" do
      response = @order.post
      response.should be_kind_of(GoogleCheckout::ApiError)
      response.should be_error
      response.serial_number.should be_nil
      response.message.should == 'Unknown response code: 600 - Unknown Response'
    end
  end

end

describe GoogleCheckout, "Add Tracking Data" do

  before(:each) do
    @order = GoogleCheckout::AddTrackingData.new("my_id", "my_key", "1234567890","UPS","Z5498W45987123684")
    GoogleCheckout.use_sandbox
  end

  it "should generate XML" do
    xml = @order.to_xml
    xml.should match(%r{google-order-number="1234567890"})
    xml.should match(%r{<carrier>UPS</carrier>})
    xml.should match(%r{<tracking-number>Z5498W45987123684</tracking-number>})
  end

end

describe GoogleCheckout, "Refund Order" do

  before(:each) do
    @order = GoogleCheckout::RefundOrder.new("my_id", "my_key", "1234567890")
    GoogleCheckout.use_sandbox
  end

  it "should generate XML" do
    @order.amount = '15.00'
    @order.currency = 'USD'
    @order.reason = 'Damaged Merchandise'
    @order.comment = 'Discount for inconvenience; ship replacement item'

    xml = @order.to_xml
    xml.should match(%r{google-order-number="1234567890"})
    xml.should match(%r{<amount currency="USD">15.00</amount>})
    xml.should match(%r{<reason>Damaged Merchandise</reason>})
    xml.should match(%r{<comment>Discount for inconvenience; ship replacement item</comment>})
  end

  it "should generate XML with no comment" do
    @order.amount = '15.00'
    @order.currency = 'USD'
    @order.reason = 'Damaged Merchandise'

    xml = @order.to_xml
    xml.should match(%r{google-order-number="1234567890"})
    xml.should match(%r{<amount currency="USD">15.00</amount>})
    xml.should match(%r{<reason>Damaged Merchandise</reason>})
  end

  it "should return an error when amount is 0" do
    lambda { @order.post }.should raise_error("Refund amount must be greater than 0!")
  end

  it "should return an error when reason is not longer than 0 characters" do
    @order.amount = '15.00'
    @order.reason = ''
    lambda { @order.post }.should raise_error("Reason must be longer than 0 characters!")
  end

  it "should return an error when reason length is greater than 140 characters" do
    @order.amount = '15.00'
    @order.reason = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam vitae est dui, at aliquam ligula. Ut imperdiet, justo eleifend ultricies nullam.'
    lambda { @order.post }.should raise_error("Reason cannot be greater than 140 characters!")
  end

  it "should return an error when comment length is greater than 140 characters" do
    @order.amount = '15.00'
    @order.reason = 'Refund'
    @order.comment = 'Sed tincidunt auctor feugiat. Nam ut enim ligula, vel scelerisque velit. Nulla eu eros nibh. Nullam sit amet sapien a leo sagittis cras amet.'
    lambda { @order.post }.should raise_error("Comment cannot be greater than 140 characters!")
  end

end

describe GoogleCheckout, "Checkout API Request (with Cart)" do

  it "should use HTTP Basic Auth"

  it "should use proper content type"

  it "should use proper accept type"

  it "should report success of request"

  it "should report error and error message"

  it "should return redirect url"

end


describe GoogleCheckout, "Send Buyer Email" do

  before(:each) do
    @command = GoogleCheckout::SendBuyerMessage.new("my_id", "my_key", "1234567890", "Thanks for the order!")
  end

  # <send-buyer-message xmlns="http://checkout.google.com/schema/2"
  #     google-order-number="841171949013218">
  #     <message>Due to high volume, your order will ship
  #     next week. Thank you for your patience.</message>
  #     <send-email>true</send-email>
  # </send-buyer-message>

  it "should post email to the buyer" do
    xml = @command.to_xml
    xml.should match(%r{google-order-number="1234567890"})
    xml.should match(%r{<message>Thanks for the order!</message>})
    xml.should match(%r{<send-email>true</send-email>})
  end

end
