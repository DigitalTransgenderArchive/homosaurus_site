class AddInternalNote < ActiveRecord::Migration[5.1]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:terms, :internal_note)
      change_table :terms do |t|
        t.text  :internal_note
      end
    end
  end
end
