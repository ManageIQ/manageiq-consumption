module ManageIQ::Consumption::ShowbackEvent::COMMON

  def get_metric(type)
    if is_container?
      resource.vim_performance_states.last.try(type.to_sym) || 0
    else
      resource.try(type.to_sym) || 0
    end
  end

  def is_metric?(type)
    if is_container?
      resource.vim_performance_states.last.methods.include?(type.to_sym)
    else
      resource.methods.include?(type.to_sym)
    end
  end

  def is_container?
    resource.class.name.ends_with?("Container")
  end
end