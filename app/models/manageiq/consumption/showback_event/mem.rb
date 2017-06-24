module ManageIQ::Consumption::ShowbackEvent::MEM
  #
  #  Return the average acumulated with the new one
  #
  def MEM_total_mem(value)
    if resource.class.name.ends_with?("Container")
      tmem = resource.vim_performance_states.last.state_data[:total_mem]
    else
      tmem = resource.memory_reserve
    end
    [value, tmem].max.to_i
  end
end