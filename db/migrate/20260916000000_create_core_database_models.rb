class CreateCoreDatabaseModels < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false

      t.timestamps
    end
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"

    create_table :calendars do |t|
      t.string :name, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :calendar_memberships do |t|
      t.references :calendar, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end
    add_index :calendar_memberships, %i[calendar_id user_id], unique: true

    create_table :daily_notes do |t|
      t.references :calendar, null: false, foreign_key: true
      t.date :date, null: false
      t.text :body, null: false

      t.timestamps
    end
    add_index :daily_notes, %i[calendar_id date], unique: true
  end
end
