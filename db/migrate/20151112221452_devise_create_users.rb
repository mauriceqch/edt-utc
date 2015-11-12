class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      ## CAS authenticatable
      t.string :username,              null: false, default: ""

      t.timestamps null: false
    end

    add_index :users, :username,                unique: true
  end
end
