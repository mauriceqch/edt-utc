class AddCnMailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cn, :string, null: false, default: ""
    add_column :users, :mail, :string, null: false, default: ""
  end
end
