class AddUserFields < ActiveRecord::Migration
  def self.up 
    add_column :users, :rt_uid, :string, {:default => nil, :null => true}
  end

  def self.down
    remove_column :users, :rt_uid
  end
end
