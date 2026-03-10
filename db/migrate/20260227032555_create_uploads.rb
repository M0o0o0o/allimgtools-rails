class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.string :upload_id, null: false
      t.string :filename, null: false
      t.integer :total_chunks, null: false
      t.integer :chunks_received, null: false, default: 0
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
    add_index :uploads, :upload_id, unique: true
  end
end
