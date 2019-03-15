# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_19_185135) do

  create_table "abouts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "url_label"
    t.string "title"
    t.integer "link_order"
    t.text "content"
    t.string "styletype"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_order"], name: "index_abouts_on_link_order"
    t.index ["published"], name: "index_abouts_on_published"
    t.index ["url_label"], name: "index_abouts_on_url_label", unique: true
  end

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "ahoy_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "param1"
    t.string "param1_type"
    t.string "param2"
    t.string "param2_type"
    t.string "pid", limit: 64
    t.string "collection_pid", limit: 64
    t.string "institution_pid", limit: 64
    t.string "model", limit: 128
    t.string "search_term"
    t.string "name"
    t.text "properties"
    t.timestamp "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id", "name"], name: "index_ahoy_events_on_user_id_and_name"
    t.index ["visit_id", "name"], name: "index_ahoy_events_on_visit_id_and_name"
  end

  create_table "base_derivatives", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "base_file_id"
    t.string "type"
    t.string "filename"
    t.string "directory"
    t.string "path"
    t.string "mime_type", default: "image/jpeg", null: false
    t.string "sha256"
    t.string "parent_sha256"
    t.string "parent_pid", limit: 64
    t.text "ocr", limit: 16777215
    t.integer "views", default: 0, null: false
    t.integer "downloads", default: 0, null: false
    t.integer "order", default: 0, null: false
    t.bigint "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_file_id"], name: "index_base_derivatives_on_base_file_id"
  end

  create_table "base_files", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.string "type"
    t.string "parent_pid", limit: 64
    t.string "path"
    t.string "directory"
    t.string "sha256"
    t.string "mime_type"
    t.string "original_filename"
    t.string "original_extension", limit: 10
    t.text "original_ocr", limit: 16777215
    t.text "ocr", limit: 16777215
    t.text "fits"
    t.boolean "low_res", default: false, null: false
    t.boolean "fedora_imported", default: false, null: false
    t.integer "views", default: 0, null: false
    t.integer "downloads", default: 0, null: false
    t.integer "order", default: 0, null: false
    t.bigint "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["generic_object_id"], name: "index_base_files_on_generic_object_id"
  end

  create_table "blazer_audits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.timestamp "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.string "check_type"
    t.text "message"
    t.timestamp "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "creator_id"
    t.text "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_list_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "list_id"
    t.text "name"
    t.string "item"
    t.timestamp "created_at"
    t.index ["list_id"], name: "index_blazer_list_items_on_list_id"
  end

  create_table "blazer_lists", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "identifier"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_lists_on_creator_id"
  end

  create_table "blazer_queries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "classification", default: "default", null: false
    t.boolean "striped_style", default: true, null: false
    t.string "border_style", default: "Full", null: false
    t.boolean "buttons_active", default: true, null: false
    t.boolean "search_active", default: true, null: false
    t.string "paging_style", default: "Default", null: false
    t.boolean "compact_style", default: false, null: false
    t.integer "page_size_default", default: 10, null: false
    t.integer "scroll_size_default", default: 400, null: false
    t.text "technical_notes"
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "bookmarks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "carousel", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "collection_pid", limit: 64
    t.string "image_pid", limit: 64
    t.string "title"
    t.string "iiif"
    t.text "description"
  end

  create_table "carousels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "collection_pid", limit: 64
    t.string "image_pid", limit: 64
    t.string "title"
    t.string "iiif"
    t.text "description"
  end

  create_table "ckeditor_assets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.integer "assetable_id"
    t.string "assetable_type", limit: 30
    t.string "type", limit: 30
    t.integer "width"
    t.integer "height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable"
    t.index ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type"
  end

  create_table "colls", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pid", limit: 64
    t.string "title"
    t.text "description"
    t.string "depositor"
    t.string "visibility", limit: 50
    t.bigint "generic_object_id"
    t.bigint "inst_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "views", default: 0, null: false
    t.index ["generic_object_id"], name: "index_colls_on_generic_object_id"
    t.index ["inst_id"], name: "index_colls_on_inst_id"
    t.index ["pid"], name: "index_colls_on_pid", unique: true
    t.index ["title"], name: "index_colls_on_title", unique: true
  end

  create_table "contributors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.string "label"
    t.index ["generic_object_id"], name: "index_contributors_on_generic_object_id"
  end

  create_table "creators", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.string "label"
    t.index ["generic_object_id"], name: "index_creators_on_generic_object_id"
  end

  create_table "file_download_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date"
    t.integer "downloads"
    t.string "file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["file_id"], name: "index_file_download_stats_on_file_id"
  end

  create_table "file_view_stats", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "date"
    t.integer "views"
    t.string "file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["file_id"], name: "index_file_view_stats_on_file_id"
  end

  create_table "friendly_id_slugs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "generic_objects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pid", limit: 64
    t.string "title", limit: 355
    t.text "toc"
    t.string "analog_format"
    t.string "digital_format"
    t.string "flagged"
    t.string "is_shown_at"
    t.string "preview"
    t.string "hosted_elsewhere", limit: 10
    t.string "identifier"
    t.string "depositor"
    t.string "visibility", limit: 50
    t.text "descriptions"
    t.text "temporal_coverage"
    t.text "date_issued"
    t.text "date_created"
    t.text "alt_titles"
    t.text "publishers"
    t.text "related_urls"
    t.text "rights_free_text"
    t.text "languages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "views", default: 0, null: false
    t.integer "downloads", default: 0, null: false
    t.bigint "inst_id"
    t.bigint "coll_id"
    t.index ["coll_id"], name: "index_generic_objects_on_coll_id"
    t.index ["inst_id"], name: "index_generic_objects_on_inst_id"
    t.index ["pid"], name: "index_generic_objects_on_pid", unique: true
  end

  create_table "genres", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "label"
    t.index ["label"], name: "index_genres_on_label", unique: true
  end

  create_table "geonames", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uri"
    t.string "label"
    t.string "lat"
    t.string "lng"
    t.text "alt_labels"
    t.text "hierarchy_full"
    t.text "hierarchy_display"
    t.text "geo_json_hash"
    t.index ["uri"], name: "index_geonames_on_uri", unique: true
  end

  create_table "hist_pendings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "model", null: false
    t.integer "obj_id"
    t.string "whodunnit"
    t.string "extra"
    t.text "data", limit: 4294967295
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6
    t.index ["discarded_at"], name: "hist_pending_discarded_idy"
    t.index ["model", "obj_id"], name: "index_hist_pendings_on_model_and_obj_id"
  end

  create_table "hist_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "model", null: false
    t.integer "obj_id", null: false
    t.string "whodunnit"
    t.string "extra"
    t.text "data", limit: 4294967295
    t.datetime "discarded_at"
    t.datetime "created_at", precision: 6
    t.index ["discarded_at"], name: "hist_version_discarded_idy"
    t.index ["model", "obj_id"], name: "index_hist_versions_on_model_and_obj_id"
  end

  create_table "homosaurus_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pid", limit: 128
    t.string "uri"
    t.string "identifier"
    t.string "label"
    t.string "version"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "alt_labels"
    t.text "broader"
    t.text "narrower"
    t.text "related"
    t.text "closeMatch"
    t.text "exactMatch"
    t.index ["identifier"], name: "index_homosaurus_subjects_on_identifier", unique: true
    t.index ["pid"], name: "index_homosaurus_subjects_on_pid", unique: true
    t.index ["uri"], name: "index_homosaurus_subjects_on_uri", unique: true
  end

  create_table "inst_colls", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "inst_id"
    t.bigint "coll_id"
    t.index ["coll_id"], name: "index_inst_colls_on_coll_id"
    t.index ["inst_id", "coll_id"], name: "index_inst_colls_on_inst_id_and_coll_id", unique: true
    t.index ["inst_id"], name: "index_inst_colls_on_inst_id"
  end

  create_table "inst_image_files", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "inst_id"
    t.string "parent_pid", limit: 64
    t.string "path"
    t.string "directory"
    t.string "sha256"
    t.string "mime_type"
    t.string "original_filename"
    t.string "original_extension", limit: 10
    t.text "fits"
    t.boolean "low_res", default: false, null: false
    t.boolean "fedora_imported", default: false, null: false
    t.integer "views", default: 0, null: false
    t.integer "order", default: 0, null: false
    t.bigint "size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inst_id"], name: "index_inst_image_files_on_inst_id"
  end

  create_table "insts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pid", limit: 64
    t.string "name"
    t.text "description"
    t.string "contact_person"
    t.string "address"
    t.string "email"
    t.string "phone"
    t.string "institution_url"
    t.string "visibility", limit: 50
    t.bigint "geonames_id"
    t.integer "views", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.index ["geonames_id"], name: "index_insts_on_geonames_id"
    t.index ["lat", "lng"], name: "index_insts_on_lat_and_lng"
    t.index ["name"], name: "index_insts_on_name", unique: true
    t.index ["pid"], name: "index_insts_on_pid", unique: true
  end

  create_table "lcsh_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uri"
    t.string "label"
    t.text "alt_labels"
    t.text "broader"
    t.text "narrower"
    t.text "related"
    t.index ["uri"], name: "index_lcsh_subjects_on_uri", unique: true
  end

  create_table "learns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "url_label"
    t.string "title"
    t.integer "link_order"
    t.text "content"
    t.string "styletype"
    t.boolean "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["link_order"], name: "index_learns_on_link_order"
    t.index ["published"], name: "index_learns_on_published"
    t.index ["url_label"], name: "index_learns_on_url_label", unique: true
  end

  create_table "news_tweets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "tweet_url", limit: 191
    t.binary "raw_content", limit: 1000
    t.binary "content", limit: 1500
    t.string "quoted_url", limit: 191
    t.binary "raw_quoted", limit: 1000
    t.binary "quoted", limit: 1500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "object_genres", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "genre_id"
    t.index ["generic_object_id", "genre_id"], name: "index_object_genre_to_genre", unique: true
    t.index ["generic_object_id"], name: "index_object_genres_on_generic_object_id"
    t.index ["genre_id"], name: "index_object_genres_on_genre_id"
  end

  create_table "object_geonames", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "geoname_id"
    t.index ["generic_object_id", "geoname_id"], name: "index_object_geonames_on_generic_object_id_and_geoname_id", unique: true
    t.index ["generic_object_id"], name: "index_object_geonames_on_generic_object_id"
    t.index ["geoname_id"], name: "index_object_geonames_on_geoname_id"
  end

  create_table "object_homosaurus_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "homosaurus_subject_id"
    t.index ["generic_object_id", "homosaurus_subject_id"], name: "index_object_homosaurus_subjects_go_homosaurus_subjects", unique: true
    t.index ["generic_object_id"], name: "index_object_homosaurus_subjects_on_generic_object_id"
    t.index ["homosaurus_subject_id"], name: "index_object_homosaurus_subjects_on_homosaurus_subject_id"
  end

  create_table "object_lcsh_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "lcsh_subject_id"
    t.index ["generic_object_id", "lcsh_subject_id"], name: "index_object_lcsh_subjects_go_lcsh_subjects", unique: true
    t.index ["generic_object_id"], name: "index_object_lcsh_subjects_on_generic_object_id"
    t.index ["lcsh_subject_id"], name: "index_object_lcsh_subjects_on_lcsh_subject_id"
  end

  create_table "object_resource_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "resource_type_id"
    t.index ["generic_object_id", "resource_type_id"], name: "index_object_resource_types_to_resource_types", unique: true
    t.index ["generic_object_id"], name: "index_object_resource_types_on_generic_object_id"
    t.index ["resource_type_id"], name: "index_object_resource_types_on_resource_type_id"
  end

  create_table "object_rights", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.bigint "rights_id"
    t.index ["generic_object_id", "rights_id"], name: "index_object_rights_to_rights", unique: true
    t.index ["generic_object_id"], name: "index_object_rights_on_generic_object_id"
    t.index ["rights_id"], name: "index_object_rights_on_rights_id"
  end

  create_table "other_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "generic_object_id"
    t.string "label"
    t.index ["generic_object_id"], name: "index_other_subjects_on_generic_object_id"
  end

  create_table "posts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "content"
    t.text "abstract"
    t.boolean "published"
    t.string "created_ym"
    t.string "created_ymd"
    t.string "thumbnail"
    t.datetime "created"
    t.datetime "updated"
    t.string "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created"], name: "index_posts_on_created"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "resource_types", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "label"
    t.string "uri"
    t.index ["label"], name: "index_resource_types_on_label", unique: true
    t.index ["uri"], name: "index_resource_types_on_uri", unique: true
  end

  create_table "rights", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "label"
    t.string "uri"
    t.index ["label"], name: "index_rights_on_label", unique: true
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.index ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"
  end

  create_table "searches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "taggings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", collation: "utf8_bin"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "version_associations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "version_committers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "obj_id"
    t.string "datastream_id"
    t.string "version_id"
    t.string "committer_login"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at", precision: 6
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

  create_table "visits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.text "landing_page"
    t.integer "user_id"
    t.string "referring_domain"
    t.string "search_keyword"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.integer "screen_height"
    t.integer "screen_width"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "postal_code"
    t.decimal "latitude", precision: 10
    t.decimal "longitude", precision: 10
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.timestamp "started_at"
    t.index ["user_id"], name: "index_visits_on_user_id"
    t.index ["visit_token"], name: "index_visits_on_visit_token", unique: true
  end

end
