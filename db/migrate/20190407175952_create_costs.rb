class CreateCosts < ActiveRecord::Migration[5.1]
  def change
    create_table :costs do |t|
      t.string:name
      t.integer:payment
      t.references:user,foreign_key: true
      t.timestamps
    end
  end
end
