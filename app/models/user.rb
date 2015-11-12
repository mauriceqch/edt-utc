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
#

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :cas_authenticatable

  has_many :scripts

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
        when :cn
          self.cn = value
        when :mail
          self.mail = value
      end
    end
  end
end
