class LangFix2 < ActiveRecord::Migration[5.2]
  def up
    EditRequest.where('my_changes LIKE "%ben\n%"').each do |er|; erc = er.my_changes.to_yaml.gsub("- ben", "- bn"); er.update(my_changes: YAML.safe_load(erc)); end
  end
  def down
  end
end
