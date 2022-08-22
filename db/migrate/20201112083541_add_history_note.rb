class AddHistoryNote < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:terms, :history_note)
      change_table :terms do |t|
        t.text  :history_note
      end
    end
  end
end
