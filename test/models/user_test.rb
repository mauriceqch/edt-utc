# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  username   :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  cn         :string           default(""), not null
#  mail       :string           default(""), not null
#  is_admin   :boolean          default(FALSE)
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
