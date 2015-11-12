# == Schema Information
#
# Table name: scripts
#
#  id         :integer          not null, primary key
#  script     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#

class Script < ActiveRecord::Base
  validates :user, presence: true

  belongs_to :user
end
