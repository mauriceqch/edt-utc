# == Schema Information
#
# Table name: scripts
#
#  id         :integer          not null, primary key
#  script     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Script < ActiveRecord::Base
end
