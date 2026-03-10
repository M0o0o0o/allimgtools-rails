class AddTaskRefAndIpToUploads < ActiveRecord::Migration[8.1]
  def change
    add_column :uploads, :task_id,    :string, null: false
    add_column :uploads, :ip_address, :string, null: false
    add_index  :uploads, :task_id
    add_index  :uploads, [ :ip_address, :created_at ]
  end
end
