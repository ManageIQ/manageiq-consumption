RSpec.describe ManageIQ::Consumption do
  it 'has a version number' do
    expect(ManageIQ::Consumption::VERSION).not_to be nil
  end

  it 'should have a version var that is constant' do
    expect(defined?(ManageIQ::Consumption::VERSION)).to be == 'constant'
  end
end
