RSpec.describe ManageIQ::Consumption do
  let(:version) { "0.0.1"}

  it "has a version number" do
    expect(ManageIQ::Consumption::VERSION).not_to be nil
  end

  it "Version number is 0.0.1" do
    expect(ManageIQ::Consumption::VERSION).to eq(version)
  end

  it "should have a version var" do
    expect(defined?(ManageIQ::Consumption::VERSION)).to be == "constant"
  end
end
