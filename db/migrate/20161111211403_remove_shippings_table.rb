class RemoveShippingsTable < ActiveRecord::Migration
  def change
    drop_table :shippings
  end
end
