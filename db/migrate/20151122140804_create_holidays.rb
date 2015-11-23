class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.string :name
      t.date :begin_at
      t.date :end_at

      t.timestamps null: false
    end
  end
end
