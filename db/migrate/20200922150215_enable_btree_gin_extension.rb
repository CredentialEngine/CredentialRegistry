
class EnableBtreeGinExtension < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'btree_gin'
  end
end
