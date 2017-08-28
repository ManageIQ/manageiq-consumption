module ManageIQ::Consumption::ShowbackEvent::STORAGE

  def STORAGE(type,value)
    if is_metric?(type)
      get_metric(type)
    else
      self.send("STORAGE_#{type}",value)
    end
  end
end