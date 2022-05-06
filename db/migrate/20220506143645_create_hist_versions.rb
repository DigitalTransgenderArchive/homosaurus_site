class CreateHistVersions < ActiveRecord::Migration[5.2]
  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    unless ActiveRecord::Base.connection.table_exists?(:hist_versions)
      create_table :hist_versions do |t|
        t.string   :model, {:null=>false}
        t.integer  :obj_id,   null: false
        t.string   :whodunnit
        t.string   :extra
        t.text     :data, limit: TEXT_BYTES
        t.datetime :discarded_at

        # Known issue in MySQL: fractional second precision
        # -------------------------------------------------
        #
        # MySQL timestamp columns do not support fractional seconds unless
        # defined with "fractional seconds precision". MySQL users should manually
        # add fractional seconds precision to this migration, specifically, to
        # the `created_at` column.
        # (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
        #
        # MySQL users should also upgrade to rails 4.2, which is the first
        # version of ActiveRecord with support for fractional seconds in MySQL.
        # (https://github.com/rails/rails/pull/14359)
        #
        t.datetime :created_at, limit: 6
      end
      add_index :hist_versions, %i(model obj_id)

      unless index_exists? :hist_versions, [:discarded_at], name: 'hist_version_discarded_idy'
        add_index :hist_versions, [:discarded_at], name: 'hist_version_discarded_idy'
      end
    end
  end
end
