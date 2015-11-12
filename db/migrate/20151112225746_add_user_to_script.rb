class AddUserToScript < ActiveRecord::Migration
  def change
    add_reference :scripts, :user, index: true, foreign_key: true
  end
end
