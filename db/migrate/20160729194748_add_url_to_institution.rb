class AddUrlToInstitution < ActiveRecord::Migration
  def change
    add_column :institutions, :url, :string
  end
end
