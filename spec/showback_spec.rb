RSpec.describe ManageIQ::Showback do
  let(:version) { "0.0.1" }

  it "has a version number" do
    expect(ManageIQ::Showback::VERSION).not_to be nil
  end

  it "Version number is 0.0.1" do
    expect(ManageIQ::Showback::VERSION).to eq(version)
  end

  it "should have a version var" do
    expect(defined?(ManageIQ::Showback::VERSION)).to be == "constant"
  end
end
