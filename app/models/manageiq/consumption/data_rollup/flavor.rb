module ManageIQ::Consumption::DataRollup::FLAVOR
  #
  # Return Number Ocurrences
  #
  def FLAVOR_cpu_reserved
    numcpus = resource.class.name.ends_with?("Container") ? resource.vim_performance_states.last.state_data[:numvcpus] : resource.try(:cpu_total_cores) || 0
    update_value_flavor("cores", [numcpus, "cores"])
  end

  #
  # Return Memory
  #
  def FLAVOR_memory_reserved
    tmem = resource.class.name.ends_with?("Container") ? resource.vim_performance_states.last.state_data[:total_mem] : resource.try(:ram_size) || 0
    update_value_flavor("memory", [tmem, "Mb"])
  end

  private

  def update_value_flavor(k, v)
    self.data["FLAVOR"] = {} unless self.data.key?("FLAVOR")
    if self.data["FLAVOR"].empty?
      add_flavor(k => v)
    else
      t_last = self.data["FLAVOR"].keys.last
      if self.data["FLAVOR"][t_last].key?(k)
        add_flavor(k => v) unless self.data["FLAVOR"][t_last][k] == v
      else
        self.data["FLAVOR"][t_last][k] = v
      end
    end
  end

  def add_flavor(new_data)
    self.data["FLAVOR"][Time.current] = new_data
  end
end
