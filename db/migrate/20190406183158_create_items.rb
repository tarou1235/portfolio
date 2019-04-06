class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.string :name
      t.integer:payment
      t.integer:line_id
      t.timestamps
    end
  end
end
