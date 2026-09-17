class AddMagicLinkAuthenticationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :magic_link_digest, :string
    add_column :users, :magic_link_expires_at, :datetime
    add_column :users, :magic_link_used_at, :datetime
    add_index :users, :magic_link_digest, unique: true
  end
end
