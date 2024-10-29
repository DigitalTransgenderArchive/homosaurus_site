class LangFix < ActiveRecord::Migration[5.2]
  def up
    EditRequest.where('my_changes LIKE "%spa\n%"').each do |er|; erc = er.my_changes.to_yaml.gsub("- spa", "- es"); er.update(my_changes: YAML.safe_load(erc)); end
  end
  def down
  end
end
