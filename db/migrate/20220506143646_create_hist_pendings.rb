class CreateHistPendings < ActiveRecord::Migration[5.2]
  # Edited from normal migration to be medium text in size.
  TEXT_BYTES = 16_770_000

  def change
    unless ActiveRecord::Base.connection.table_exists?(:hist_pendings)
      create_table :hist_pendings do |t|
        t.string   :model, {:null=>false}
        t.integer  :obj_id
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
      add_index :hist_pendings, %i(model obj_id)

      unless index_exists? :hist_pendings, [:discarded_at], name: 'hist_pending_discarded_idy'
        add_index :hist_pendings, [:discarded_at], name: 'hist_pending_discarded_idy'
      end
    end
  end
end
