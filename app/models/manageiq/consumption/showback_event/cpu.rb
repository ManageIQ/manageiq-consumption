module ManageIQ::Consumption::ShowbackEvent::CPU

  def CPU(type,value)
    if is_metric?(type)
      get_metric(type)
    else
      self.send("CPU_#{type}",value)
    end
  end
  #
  #  Return the average acumulated with the new one
  #
  def CPU_sb_usage_rate_average(value)
    if @metrics && @metrics.count>0
      ((value * event_days + @metrics.average(:cpu_usage_rate_average)) / (event_days + 1)).to_f
    else
      value.to_f
    end
  end

  #
  #  Return the max number of cpu for object
  #
  def CPU_sb_max_cpu_total_cores(value)
    if resource.class.name.ends_with?("Container")
      numcpus = resource.vim_performance_states.last.state_data[:numvcpus]
    else
      numcpus = get_metric("cpu_total_cores")
    end
    [value, numcpus].max.to_i
  end
end