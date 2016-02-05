# == Schema Information
#
# Table name: holidays
#
#  id         :integer          not null, primary key
#  name       :string
#  begin_at   :date
#  end_at     :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Holiday < ActiveRecord::Base
  validates :name, presence: true
  validates :begin_at, presence: true
  validates :end_at, presence: true

  def get_range
    begin_at.to_datetime..(end_at.to_datetime+1)
  end

  rails_admin do
    configure :begin_at, :date do
      date_format :default
    end

    configure :end_at, :date do
      date_format :default
    end
  end



end
