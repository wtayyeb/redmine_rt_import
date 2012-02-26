class AddIssueFields < ActiveRecord::Migration
  def self.up 
    add_column :issues, :rt_identifier, :string, {:default => nil, :null => true}
  end

  def self.down
    remove_column :issues, :rt_identifier
  end
end
