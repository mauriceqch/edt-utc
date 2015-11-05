# == Schema Information
#
# Table name: events
#
#  id         :integer          not null, primary key
#  course     :string
#  type       :string
#  date       :datetime
#  frequency  :integer
#  classroom  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Event < ActiveRecord::Base
end
