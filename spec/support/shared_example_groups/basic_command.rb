shared_examples_for "basic command" do
  it "should include XML header" do
    @order.to_xml.should match(/^<\?xml version=\"1\.0\" encoding=\"UTF-8\"\?>/)
  end
end
