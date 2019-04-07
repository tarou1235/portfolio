class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.integer:payment
      t.references :user, foreign_key: true
      t.references :cost, foreign_key: true
      t.timestamps
    end
  end
end
