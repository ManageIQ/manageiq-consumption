module ManageIQ::Consumption::ShowbackEvent::MEM
  #
  #  Return the average acumulated with the new one
  #
  def MEM_max_mem(value)
    if resource.class.name.ends_with?("Container")
      tmem = resource.vim_performance_states.last.state_data[:total_mem]
    else
      tmem = resource.try(:ram_size) || 0
    end
    return tmem
  end

  # for old chargeback integration
  def memory_derived_memory_used
  end

  def memory_derived_memory_available
  end
end