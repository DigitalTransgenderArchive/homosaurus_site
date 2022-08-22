Hist.config do |conf|
  conf.default_diff_exclude = []
  conf.default_diff_exclude  << 'created_at'
  conf.default_diff_exclude  << 'hist_extra'
  conf.default_diff_exclude  << 'whodunnit'
  conf.default_diff_exclude  << 'pending_id'
  conf.default_diff_exclude  << 'ver_id'
  conf.default_diff_exclude  << 'discarded_at'
end
