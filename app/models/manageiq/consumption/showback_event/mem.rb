module ManageIQ::Consumption::ShowbackEvent::MEM

  def MEM(type,value)
    if is_metric?(type)
      get_metric(type)
    else
      self.send("MEM_#{type}",value)
    end
  end
  #
  #  Return the average acumulated with the new one
  #
  def MEM_sb_max_mem(value)
    if resource.class.name.ends_with?("Container")
      tmem = resource.vim_performance_states.last.state_data[:total_mem]
    else
      tmem = resource.try(:ram_size) || 0
    end
    return tmem
  end

  def MEM_sb_average_memory_percent(value)

  end
end