module ManageIQ::Consumption::ShowbackEvent::CPU
  #
  #  Return the average acumulated with the new one
  #
  def CPU_average(value)
    if @metrics.count>0
      ((value * event_days + @metrics.average(:cpu_usage_rate_average)) / (event_days + 1))
    else
      value
    end
  end

  #
  # Return Number Ocurrences
  #
  def CPU_number(value)
    return value
  end

  #
  #  Return the max number of cpu for object
  #
  def CPU_max_number_of_cpu(value)
    if resource.class.name.ends_with?("Container")
      numcpus = resource.vim_performance_states.last.state_data[:numvcpus]
    else
      numcpus = if resource.methods.include?(:cpu_total_cores) then resource.cpu_total_cores else 0 end
    end
    [value, numcpus].max.to_i
  end

  # for old chargeback integration
  def cpu_cpu_usagemhz_rate_average
  end

  def cpu_cores_v_derived_cpu_total_cores_used
  end

  def cpu_cores_derived_vm_numvcpus
  end
end