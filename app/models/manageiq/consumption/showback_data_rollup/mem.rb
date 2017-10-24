module ManageIQ::Consumption::ShowbackDataRollup::MEM
  #
  #  Return the average acumulated with the new one
  #
  def MEM_max_mem(*)
    resource.class.name.ends_with?("Container") ? resource.vim_performance_states.last.state_data[:total_mem] : resource.try(:ram_size) || 0
  end

  # for old chargeback integration
  def memory_derived_memory_used
  end

  def memory_derived_memory_available
  end
end
