class CreateScripts < ActiveRecord::Migration
  def change
    create_table :scripts do |t|
      t.text :script

      t.timestamps null: false
    end
  end
end
