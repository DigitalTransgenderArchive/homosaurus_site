class AddUriToVersionRelease < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.column_exists?(:version_release_terms, :changed_uris)
      change_table :version_release_terms do |t|
        # Serialized data
        t.text :changed_uris
        t.text :changed_uri_labels
      end
    end
  end
end
