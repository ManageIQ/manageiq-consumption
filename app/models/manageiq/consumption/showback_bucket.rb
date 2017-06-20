class ManageIQ::Consumption::ShowbackBucket < ApplicationRecord
  belongs_to :resource, :polymorphic => true
  before_save :check_bucket_state, if: :state_changed?

  has_many :showback_charges, :dependent => :destroy, :inverse_of => :showback_bucket
  has_many :showback_events, :through => :showback_charges, :inverse_of => :showback_buckets

  validates :name,                  :presence => true
  validates :description,           :presence => true
  validates :resource,              :presence => true
  validates :start_time, :end_time, :presence => true
  validates :state,                 :presence => true, :inclusion => { :in => %w(OPEN PROCESSING CLOSE) }

  #End_time should be after start_time.
  validate  :start_time_before_end_time

  self.table_name = "showback_buckets"

  def start_time_before_end_time
    errors.add(:start_time, _("Start time should be before end time")) unless end_time.to_i > start_time.to_i
  end

  def check_bucket_state
    case state_was
      when "OPEN"  then raise _("Bucket can't change its state to CLOSE from OPEN")      unless state != "CLOSE"
      when "PROCESSING"
        raise _("Bucket can't change its state to OPEN from PROCESSING") unless state != "OPEN"
        s_time = (self.start_time + 1.months).beginning_of_month
        if self.end_time != self.start_time.end_of_month
          s_time = self.end_time
        else
          s_time = (self.start_time + 1.month).beginning_of_month
        end
        e_time = s_time.end_of_month
        ShowbackBucket.create(:name        => self.name,
                              :description => self.description,
                              :resource    => self.resource,
                              :start_time  => s_time,
                              :end_time    => e_time,
                              :state       => "OPEN"
        ) unless ShowbackBucket.exists?(:resource => self.resource, :start_time  => s_time)
      when "CLOSE"      then  raise _("Bucket can't change its state when it's CLOSE")
    end
  end
end