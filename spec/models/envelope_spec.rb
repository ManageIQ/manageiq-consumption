require 'spec_helper'
require 'money-rails/test_helpers'

RSpec.describe ManageIQ::Showback::Envelope, :type => :model do
  before(:each) do
    ManageIQ::Showback::InputMeasure.seed
  end
  let(:resource)        { FactoryBot.create(:vm) }
  let(:envelope)        { FactoryBot.build(:envelope) }
  let(:data_rollup)     { FactoryBot.build(:data_rollup, :with_vm_data, :full_month, :resource => resource) }
  let(:data_rollup2)    { FactoryBot.build(:data_rollup, :with_vm_data, :full_month, :resource => resource) }
  let(:enterprise_plan) { FactoryBot.create(:price_plan) }

  context '#basic lifecycle' do
    it 'has a valid factory' do
      envelope.valid?
      expect(envelope).to be_valid
    end

    it 'is not valid without an association to a parent element' do
      envelope.resource = nil
      envelope.valid?
      expect(envelope.errors.details[:resource]). to include(:error => :blank)
    end

    it 'is not valid without a name' do
      envelope.name = nil
      envelope.valid?
      expect(envelope.errors.details[:name]). to include(:error => :blank)
    end

    it 'is not valid without a description' do
      envelope.description = nil
      envelope.valid?
      expect(envelope.errors.details[:description]). to include(:error => :blank)
    end

    it 'monetizes accumulated cost' do
      expect(ManageIQ::Showback::Envelope).to monetize(:accumulated_cost)
    end

    it 'deletes costs associated when deleting the envelope' do
      2.times do
        FactoryBot.create(:data_view, :envelope => envelope)
      end
      expect(envelope.data_views.count).to be(2)
      expect { envelope.destroy }.to change(ManageIQ::Showback::DataView, :count).from(2).to(0)
      expect(envelope.data_views.count).to be(0)
    end

    it 'deletes costs associated when deleting the data_rollup' do
      2.times do
        FactoryBot.create(:data_view, :envelope => envelope)
      end
      expect(envelope.data_views.count).to be(2)
      d_rollup = envelope.data_views.first.data_rollup
      expect { d_rollup.destroy }.to change(ManageIQ::Showback::DataView, :count).from(2).to(1)
      expect(envelope.data_rollups).not_to include(data_rollup)
    end

    it 'it only can be in approved states' do
      envelope.state = 'ERROR'
      expect(envelope).not_to be_valid
      expect(envelope.errors.details[:state]).to include(:error => :inclusion, :value => 'ERROR')
    end

    it 'it can not be different of states open, processing, closed' do
      states = %w(CLOSED PROCESSING OPEN)
      states.each do |x|
        envelope.state = x
        expect(envelope).to be_valid
      end
    end

    it 'start time should happen earlier than end time' do
      envelope.start_time = envelope.end_time
      envelope.valid?
      expect(envelope.errors.details[:end_time]).to include(:error => 'should happen after start_time')
    end
  end

  context '.control lifecycle state' do
    let(:envelope_lifecycle) { FactoryBot.create(:envelope) }

    it 'it can transition from open to processing' do
      envelope_lifecycle.state = 'PROCESSING'
      envelope_lifecycle.valid?
      expect(envelope).to be_valid
    end

    it 'a new envelope is created automatically when transitioning from open to processing if not exists' do
      envelope_lifecycle.state = 'PROCESSING'
      envelope_lifecycle.save
      # There should be two envelopes when I save, the one in processing state + the one in OPEN state
      expect(described_class.count).to eq(2)
      # ERROR ERROR ERROR
    end

    it 'it can not transition from open to closed' do
      envelope_lifecycle.state = 'CLOSED'
      expect { envelope_lifecycle.save }.to raise_error(RuntimeError, _("Envelope can't change state to CLOSED from OPEN"))
    end

    it 'it can not transition from processing to open' do
      envelope_lifecycle = FactoryBot.create(:envelope, :processing)
      envelope_lifecycle.state = 'OPEN'
      expect { envelope_lifecycle.save }.to raise_error(RuntimeError, _("Envelope can't change state to OPEN from PROCESSING"))
    end

    it 'it can transition from processing to closed' do
      envelope_lifecycle = FactoryBot.create(:envelope, :processing)
      envelope_lifecycle.state = 'CLOSED'
      expect { envelope_lifecycle.save }.not_to raise_error
    end

    it 'it can not transition from closed to open or processing' do
      envelope_lifecycle = FactoryBot.create(:envelope, :closed)
      envelope_lifecycle.state = 'OPEN'
      expect { envelope_lifecycle.save }.to raise_error(RuntimeError, _("Envelope can't change state when it's CLOSED"))
      envelope_lifecycle = FactoryBot.create(:envelope, :closed)
      envelope_lifecycle.state = 'PROCESSING'
      expect { envelope_lifecycle.save }.to raise_error(RuntimeError, _("Envelope can't change state when it's CLOSED"))
    end

    pending 'it can not exists 2 envelopes opened from one resource'
  end

  describe 'methods for data_rollups' do
    it 'can add an data_rollup to a envelope' do
      expect { envelope.add_data_rollup(data_rollup) }.to change(envelope.data_rollups, :count).by(1)
      expect(envelope.data_rollups).to include(data_rollup)
    end

    it 'throws an error for duplicate data_rollups when using Add data_rollup to a Envelope' do
      envelope.add_data_rollup(data_rollup)
      envelope.add_data_rollup(data_rollup)
      expect(envelope.errors.details[:data_rollups]). to include(:error => "duplicate")
    end

    it 'Throw error in add data_rollup if it is not of a proper type' do
      obj = FactoryBot.create(:vm)
      envelope.add_data_rollup(obj)
      expect(envelope.errors.details[:data_rollups]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Showback::DataRollup")
    end

    it 'Remove data_rollup from a Envelope' do
      envelope.add_data_rollup(data_rollup)
      expect { envelope.remove_data_rollup(data_rollup) }.to change(envelope.data_rollups, :count).by(-1)
      expect(envelope.data_rollups).not_to include(data_rollup)
    end

    it 'Throw error in Remove data_rollup from a Envelope if the data_rollup can not be found' do
      envelope.add_data_rollup(data_rollup)
      envelope.remove_data_rollup(data_rollup)
      envelope.remove_data_rollup(data_rollup)
      expect(envelope.errors.details[:data_rollups]). to include(:error => "not found")
    end

    it 'Throw error in Remove data_rollup if the type is not correct' do
      obj = FactoryBot.create(:vm)
      envelope.remove_data_rollup(obj)
      expect(envelope.errors.details[:data_rollups]). to include(:error => "Error Type #{obj.type} is not ManageIQ::Showback::DataRollup")
    end
  end

  describe 'methods with #data_view' do
    it 'add data_view directly' do
      data_view = FactoryBot.create(:data_view, :envelope => envelope)
      envelope.add_data_view(data_view, 2)
      expect(data_view.cost). to eq(Money.new(2))
    end

    it 'add data_view directly' do
      data_view = FactoryBot.create(:data_view, :cost => Money.new(7)) # different envelope
      envelope.add_data_view(data_view, 2)
      # data_view won't be updated as it does not belongs to the envelope
      expect(data_view.cost).not_to eq(Money.new(2))
      expect(data_view.envelope).not_to eq(envelope)
    end

    it 'add data_view from an data_rollup' do
      data_rollup = FactoryBot.create(:data_rollup)
      data_view = FactoryBot.create(:data_view, :data_rollup => data_rollup, :envelope => envelope)
      expect(data_rollup.data_views).to include(data_view)
      expect(envelope.data_views).to include(data_view)
    end

    it 'get_data_view from a data_view' do
      data_view = FactoryBot.create(:data_view, :envelope => envelope, :cost => Money.new(10))
      expect(envelope.get_data_view(data_view)).to eq(Money.new(10))
    end

    it 'get_data_view from an data_rollup' do
      data_view = FactoryBot.create(:data_view, :envelope => envelope, :cost => Money.new(10))
      data_rollup = data_view.data_rollup
      expect(envelope.get_data_view(data_rollup)).to eq(Money.new(10))
    end

    it 'get_data_view from nil get 0' do
      expect(envelope.get_data_view(nil)).to eq(0)
    end

    it 'calculate_data_view with an error' do
      data_view = FactoryBot.create(:data_view, :cost => Money.new(10))
      envelope.calculate_data_view(data_view)
      expect(data_view.errors.details[:data_view]). to include(:error => 'not found')
      expect(envelope.calculate_data_view(data_view)). to eq(Money.new(0))
    end

    it 'calculate_data_view fails with no data_view' do
      enterprise_plan
      expect(envelope.find_price_plan).to eq(ManageIQ::Showback::PricePlan.first)
      envelope.calculate_data_view(nil)
      expect(envelope.errors.details[:data_view]). to include(:error => "not found")
      expect(envelope.calculate_data_view(nil)). to eq(0)
    end

    it 'find a price plan' do
      ManageIQ::Showback::PricePlan.seed
      expect(envelope.find_price_plan).to eq(ManageIQ::Showback::PricePlan.first)
    end

    pending 'find a price plan associated to the resource'
    pending 'find a price plan associated to a parent resource'
    pending 'find a price plan finds the default price plan if not found'

    it '#calculate data_view' do
      enterprise_plan
      sh = FactoryBot.create(:rate,
                              :CPU_average,
                              :price_plan => ManageIQ::Showback::PricePlan.first)
      st = sh.tiers.first
      st.fixed_rate = Money.new(67)
      st.variable_rate = Money.new(12)
      st.variable_rate_per_unit = 'percent'
      st.save
      envelope.add_data_rollup(data_rollup2)
      data_rollup2.reload
      envelope.data_views.reload
      data_view = envelope.data_views.find_by(:data_rollup => data_rollup2)
      data_view.cost = Money.new(0)
      data_view.save
      expect { envelope.calculate_data_view(data_view) }.to change(data_view, :cost)
        .from(Money.new(0)).to(Money.new((data_rollup2.reload.get_group_value('CPU', 'average') * 12) + 67))
    end

    it '#Add an data_rollup' do
      data_rollup = FactoryBot.create(:data_rollup)
      expect { envelope.add_data_view(data_rollup, 5) }.to change(envelope.data_views, :count).by(1)
    end

    it 'update a data_view in the envelope with add_data_view' do
      data_view = FactoryBot.create(:data_view, :envelope => envelope)
      expect { envelope.add_data_view(data_view, 5) }.to change(data_view, :cost).to(Money.new(5))
    end

    it 'update a data_view in the envelope with update_data_view' do
      data_view = FactoryBot.create(:data_view, :envelope => envelope)
      expect { envelope.update_data_view(data_view, 5) }.to change(data_view, :cost).to(Money.new(5))
    end

    it 'update a data_view in the envelope gets nil if the data_view is not there' do
      data_view = FactoryBot.create(:data_view) # not in the envelope
      expect(envelope.update_data_view(data_view, 5)).to be_nil
    end

    it '#clear_data_view' do
      envelope.add_data_rollup(data_rollup)
      envelope.data_views.reload
      data_view = envelope.data_views.find_by(:data_rollup => data_rollup)
      data_view.cost = Money.new(5)
      expect { envelope.clear_data_view(data_view) }.to change(data_view, :cost).from(Money.new(5)).to(Money.new(0))
    end

    it '#clear all data_views' do
      envelope.add_data_view(data_rollup, Money.new(57))
      envelope.add_data_view(data_rollup2, Money.new(123))
      envelope.clean_all_data_views
      envelope.data_views.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
    end

    it '#sum_of_data_views' do
      envelope.add_data_view(data_rollup, Money.new(57))
      envelope.add_data_view(data_rollup2, Money.new(123))
      expect(envelope.sum_of_data_views).to eq(Money.new(180))
    end

    it 'calculate_all_data_views' do
      enterprise_plan
      vm = FactoryBot.create(:vm)
      sh = FactoryBot.create(:rate,
                              :CPU_average,
                              :price_plan => ManageIQ::Showback::PricePlan.first)
      tier = sh.tiers.first
      tier.fixed_rate    = Money.new(67)
      tier.variable_rate = Money.new(12)
      tier.save
      ev  = FactoryBot.create(:data_rollup, :with_vm_data, :full_month, :resource => vm)
      ev2 = FactoryBot.create(:data_rollup, :with_vm_data, :full_month, :resource => vm)
      envelope.add_data_rollup(ev)
      envelope.add_data_rollup(ev2)
      envelope.data_views.reload
      envelope.data_views.each do |x|
        expect(x.cost).to eq(Money.new(0))
      end
      envelope.data_views.reload
      envelope.calculate_all_data_views
      envelope.data_views.each do |x|
        expect(x.cost).not_to eq(Money.new(0))
      end
    end
  end

  describe '#state:open' do
    it 'new data_rollups can be associated to the envelope' do
      envelope.save
      # data_rollup.save
      data_rollup
      expect { envelope.data_rollups << data_rollup }.to change(envelope.data_rollups, :count).by(1)
      expect(envelope.data_rollups.last).to eq(data_rollup)
    end
    it 'data_rollups can be associated to costs' do
      envelope.save
      # data_rollup.save
      data_rollup
      expect { envelope.data_rollups << data_rollup }.to change(envelope.data_views, :count).by(1)
      data_view = envelope.data_views.last
      expect(data_view.data_rollup).to eq(data_rollup)
      expect { data_view.cost = Money.new(3) }.to change(data_view, :cost).from(0).to(Money.new(3))
    end

    it 'monetized cost' do
      expect(ManageIQ::Showback::DataView).to monetize(:cost)
    end

    pending 'data_views can be updated for an data_rollup'
    pending 'data_views can be updated for all data_rollups in the envelope'
    pending 'data_views can be deleted for an data_rollup'
    pending 'data_views can be deleted for all data_rollups in the envelope'
    pending 'is possible to return data_views for an data_rollup'
    pending 'is possible to return data_views for all data_rollups'
    pending 'sum of data_views can be calculated for the envelope'
    pending 'sum of data_views can be calculated for an data_rollup type'
  end

  describe '#state:processing' do
    pending 'new data_rollups are associated to a new or open envelope'
    pending 'new data_rollups can not be associated to the envelope'
    pending 'data_views can be deleted for an data_rollup'
    pending 'data_views can be deleted for all data_rollups in the envelope'
    pending 'data_views can be updated for an data_rollup'
    pending 'data_views can be updated for all data_rollups in the envelope'
    pending 'is possible to return data_views for an data_rollup'
    pending 'is possible to return data_views for all data_rollups'
    pending 'sum of data_views can be calculated for the envelope'
    pending 'sum of data_views can be calculated for an data_rollup type'
  end

  describe '#state:closed' do
    pending 'new data_rollups can not be associated to the envelope'
    pending 'new data_rollups are associated to a new or existing open envelope'
    pending 'data_views can not be deleted for an data_rollup'
    pending 'data_views can not be deleted for all data_rollups in the envelope'
    pending 'data_views can not be updated for an data_rollup'
    pending 'data_views can not be updated for all data_rollups in the envelope'
    pending 'is possible to return data_views for an data_rollup'
    pending 'is possible to return data_views for all data_rollups'
    pending 'sum of data_views can be calculated for the envelope'
    pending 'sum of data_views can be calculated for an data_rollup type'
  end
end
