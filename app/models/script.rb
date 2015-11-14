# == Schema Information
#
# Table name: scripts
#
#  id         :integer          not null, primary key
#  script     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#  slug       :string
#

class Script < ActiveRecord::Base
  extend FriendlyId
  friendly_id :user_username, use: [:slugged, :finders]

  validates :user, presence: true, uniqueness: true
  validates :script, presence: true

  belongs_to :user

  def user_username
    self.user.username
  end
end
