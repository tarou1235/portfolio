class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.string :name
      t.string :paytype
      t.integer:payment
      t.string:line_id
      t.timestamps
    end
  end
end
