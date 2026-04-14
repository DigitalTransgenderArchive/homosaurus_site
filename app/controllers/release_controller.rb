class ReleaseController < ApplicationController

  def index
    @releases = VersionRelease.all.order('id DESC')
    unless current_user.present?
      @releases = @releases.where(status: "published")
    end
  end
  def show
    @host = request.host || "https://homosaurus.org"
    @release = VersionRelease.find_by(release_identifier: params[:release_id])
    unless @release.status == "Published" or current_user.present?
      redirect_to release_path() and return
    end
    @vocab = @release.vocabulary
    @release_terms = @release.version_release_terms
    @release_terms = @release_terms.sort_by { |release_term| ActiveSupport::Inflector.transliterate(release_term.term.pref_label.downcase) }
    @terms = @release_terms.map { |rt| rt.term }
    @terms.sort_by! { |term| term.pref_label.downcase }
    # Replaces can duplicate?
    @terms.uniq!
    identifier = @release.release_identifier.gsub('.', '_')
    path = Rails.root.join("public", "static_dumps", @vocab.identifier, @release.release_identifier)
    respond_to do |format|
      format.html
      format.jsonld   { render file: path.to_s + ".jsonld" }
      format.csv      { render file: path.to_s + ".csv" }
      format.marc     { render file: path.to_s + ".marc" }
      format.xml      { render file: path.to_s + ".xml" }
      format.nt       { render file: path.to_s + ".nt" }
      format.ttl      { render file: path.to_s + ".ttl" }

      # Legacy formats
      format.jsonldV2 { render file: path.to_s + ".legacy.jsonld" }
      format.ntV2     { render file: path.to_s + ".legacy.nt" }
      format.ttlV2    { render file: path.to_s + ".legacy.ttl" }
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

end
