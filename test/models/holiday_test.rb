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

require 'test_helper'

class HolidayTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
