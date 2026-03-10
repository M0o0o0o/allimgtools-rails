class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :task_id,    null: false
      t.string :tool,       null: false
      t.string :ip_address, null: false
      t.string :status,     null: false, default: "pending"

      t.timestamps
    end
    add_index :tasks, :task_id, unique: true
  end
end
