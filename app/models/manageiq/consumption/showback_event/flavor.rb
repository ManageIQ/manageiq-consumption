module ManageIQ::Consumption::ShowbackEvent::FLAVOR

  MEASURE = {
      # DB            Displayed
      "cpu_reserved"     => "numvcpus",
      "memory_reserved"   => "total_mem"
  }
  #
  # Return Number Ocurrences
  #
  def FLAVOR(type)
    puts resource.vim_performance_states.last.state_data
    puts type
    result = resource.vim_performance_states.last.state_data[ManageIQ::Consumption::ShowbackEvent::FLAVOR::MEASURE[type.to_sym]] || 0
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
    self.data["FLAVOR"][t][k] = [v,self.data["FLAVOR"].first[1][k][1]]
  end
end