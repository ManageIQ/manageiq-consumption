module ManageIQ::Consumption::ShowbackDataRollup::CPU
  #
  #  Return the average acumulated with the new one
  #
  def CPU_average(value)
    if @metrics.count.positive?
      ((value * event_days + @metrics.average(:cpu_usage_rate_average)) / (event_days + 1))
    else
      value
    end
  end

  #
  # Return Number Ocurrences
  #
  def CPU_number(value)
    value
  end

  #
  #  Return the max number of cpu for object
  #
  def CPU_max_number_of_cpu(value)
    numcpus = case resource.class.name.ends_with?("Container")
              when true then resource.vim_performance_states.last.state_data[:numvcpus]
              else resource.methods.include?(:cpu_total_cores) ? resource.cpu_total_cores : 0
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

  def cpu_cores_cpu_usage_rate_average
  end

  def cpu_derived_vm_numvcpus
  end
end
