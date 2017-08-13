module ManageIQ::Consumption::ShowbackEvent::FLAVOR
  #
  # Return Number Ocurrences
  #
  def FLAVOR_cpu_reserved
    resource.class.name.ends_with?("Container") ? numcpus = resource.vim_performance_states.last.state_data[:numvcpus] : numcpus = resource.try(:cpu_total_cores) || 0
    update_value_flavor("cores",[numcpus,"cores"])
  end
  #
  # Return Memory
  #
  def FLAVOR_memory_reserve
    resource.class.name.ends_with?("Container") ? tmem = resource.vim_performance_states.last.state_data[:total_mem] : tmem = resource.try(:ram_size) || 0
    update_value_flavor("memory",[tmem,"Mb"])
  end

  private

  def update_value_flavor(k,v)
    if self.data["FLAVOR"].empty?
      add_flavor({k => v})
    else
      t_last = self.data["FLAVOR"].keys.last
      if self.data["FLAVOR"][t_last].key?(k)
        add_flavor({k => v}) unless self.data["FLAVOR"][t_last][k] == v
      else
        self.data["FLAVOR"][t_last][k] = v
      end
    end
  end

  def add_flavor(new_data)
    t    = Time.now
    self.data["FLAVOR"][t] = new_data
  end
end