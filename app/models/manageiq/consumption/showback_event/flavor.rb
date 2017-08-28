module ManageIQ::Consumption::ShowbackEvent::FLAVOR

  MEASURE_CONTAINER = {
      # DB            Displayed
      "cpu_reserved"     => "numvcpus",
      "memory_reserve"   => "total_mem"
  }

  MEASURE_VM = {
      # DB            Displayed
      "cpu_reserved"     => "cpu_total_cores",
      "memory_reserve"   => "ram_size"
  }
  #
  # Return Number Ocurrences
  #
  def FLAVOR(type)
    resource.class.name.ends_with?("Container") ? result = resource.vim_performance_states.last.state_data[MEASURE_CONTAINER[type].to_sym] : result = resource.try(MEASURE_VM[type].to_sym) || 0
    update_value_flavor(type,result)
  end

  private

  def update_value_flavor(k,v)
    if self.data["FLAVOR"].empty?
      add_flavor(k, v)
    else
      t_last = self.data["FLAVOR"].keys.last
      if self.data["FLAVOR"][t_last].key?(k)
        add_flavor(k , v) unless self.data["FLAVOR"][t_last][k] == v
      else
        self.data["FLAVOR"][t_last][k] = v
      end
    end
  end

  def add_flavor(k,v)
    t    = Time.now
    self.data["FLAVOR"][t] = {}
    self.data["FLAVOR"][t][k] = [v,self.data["FLAVOR"].first[k][1]]
  end
end