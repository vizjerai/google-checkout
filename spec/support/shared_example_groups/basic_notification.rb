shared_examples_for "basic notification" do

  it "should get serial number" do
    @notification.serial_number.should == 'bea6bc1b-e1e2-44fe-80ff-0180e33a2614'
  end

  it "should get google order number" do
    @notification.google_order_number.should == '841171949013218'
  end

  it "should generate acknowledgment XML" do
    @notification.acknowledgment_xml.should match(/notification-acknowledgment/)
  end

end
