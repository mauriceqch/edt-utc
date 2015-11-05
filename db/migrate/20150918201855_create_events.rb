class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :course
      t.string :type
      t.datetime :date
      t.integer :frequency
      t.string :classroom

      t.timestamps null: false
    end
  end
end
