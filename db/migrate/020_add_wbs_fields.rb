class AddWbsFields < ActiveRecord::Migration
  def self.up 
    add_column :issues, :rt_wbs, :string, {:default => nil, :null => true}
    add_column :projects, :rt_wbs, :string, {:default => nil, :null => true}
  end

  def self.down
    remove_column :issues, :rt_wbs
    remove_column :projects, :rt_wbs
  end
end
