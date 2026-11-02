class ReleaseController < ApplicationController

  def index
    @releases = VersionRelease.all.order('id DESC')
    unless current_user.present?
      @releases = @releases.where(status: "published")
    end
    @stats = VersionRelease.list_statistics
    @term_totals = VersionRelease.term_totals(@releases.includes(:vocabulary).to_a)
  end

  def show
    @host = request.host || "https://homosaurus.org"
    @release = VersionRelease.find_by(release_identifier: params[:release_id])
    unless @release.status == "Published" or current_user.present?
      redirect_to release_path() and return
    end
    @vocab = @release.vocabulary
    identifier = @release.release_identifier.gsub('.', '_')
    path = Rails.root.join("public", "static_dumps", @vocab.identifier, @release.release_identifier)
    respond_to do |format|
      format.html { load_release_cards }
      format.jsonld   { render file: path.to_s + ".jsonld" }
      format.csv      { render file: path.to_s + ".csv" }
      format.marc     { render file: path.to_s + ".marc" }
      format.xml      { render file: path.to_s + ".xml" }
      format.nt       { render file: path.to_s + ".nt" }
      format.ttl      { render file: path.to_s + ".ttl" }

      # Legacy formats
      has_legacy = @vocab.id >= 4 ? ".legacy" : ""
      format.jsonldV2 { render file: path.to_s + has_legacy + ".jsonld" }
      format.ntV2     { render file: path.to_s + has_legacy + ".nt" }
      format.ttlV2    { render file: path.to_s + has_legacy + ".ttl" }
    end

  end

  # archived static releases
  def release_notes_2_1
    render :template => "release/archive/release_notes_2_1"
  end

  def release_notes_2_2
    render :template => "release/archive/release_notes_2_2"
  end

  def release_notes_2_3
    render :template => "release/archive/release_notes_2_3"
  end

  def release_notes_3_0
    render :template => "release/archive/release_notes_3_0"
  end

  def release_notes_3_1
    render :template => "release/archive/release_notes_3_1"
  end

  def release_notes_3_2
    render :template => "release/archive/release_notes_3_2"
  end


  private

  def load_release_cards
    all_statuses = %w[approved pending suggested]
    @card_types = params.key?(:types) ? (params[:types].to_s.split(",") & VersionRelease::CARD_TYPES) : VersionRelease::CARD_TYPES
    @card_statuses = params.key?(:statuses) ? (params[:statuses].to_s.split(",") & all_statuses) : all_statuses
    @card_sort = params[:sort] == "label" ? "label" : "time"
    @card_order = params[:order] == "desc" ? "desc" : "asc"
    all_rows = @release.card_index(current_user.present?)
    @card_total = all_rows.size
    status_filtered = current_user.present? && @release.status != "Published"
    status_ok = ->(row) { !status_filtered || !%w[approved pending].include?(row["status"]) || @card_statuses.include?(row["status"]) || (row["suggested"] && @card_statuses.include?("suggested")) }
    @type_counts = all_rows.select(&status_ok).group_by { |row| row["type"] }.transform_values(&:size)
    typed = all_rows.select { |row| @card_types.include?(row["type"]) }
    @status_counts = typed.group_by { |row| row["status"] }.transform_values(&:size).merge("suggested" => typed.count { |row| row["suggested"] })
    rows = typed.select(&status_ok)
    rows = if @card_sort == "label"
             rows.sort_by { |row| [I18n.transliterate(row["label"]).downcase, row["label"], row["id"]] }
           else
             rows.sort_by { |row| [row["time"], row["id"]] }
           end
    rows.reverse! if @card_order == "desc"
    @cards = Kaminari.paginate_array(rows).page(params[:page]).per(100)
    ids = @cards.map { |row| row["id"].to_i }
    @page_edit_requests = ids.empty? ? EditRequest.none : EditRequest.where(id: ids).order(Arel.sql("FIELD(edit_requests.id, #{ids.join(',')})"))
  end
end
