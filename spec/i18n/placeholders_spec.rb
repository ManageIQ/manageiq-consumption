describe :placeholders do
  include_examples :placeholders, ManageIQ::Consumption::Engine.root.join('locale').to_s
end
