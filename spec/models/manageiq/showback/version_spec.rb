RSpec.describe ManageIQ::Showback do
  it 'has a version number' do
    expect(ManageIQ::Showback::VERSION).not_to be nil
  end

  it 'should have a version var that is constant' do
    expect(defined?(ManageIQ::Showback::VERSION)).to be == 'constant'
  end
end
