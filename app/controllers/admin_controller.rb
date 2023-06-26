class AdminController < ApplicationController
  before_action :verify_permission

  def version_new
    @version_release = VersionRelease.new
  end

  def version_create
    updated_term_identifiers = []
    ActiveRecord::Base.transaction do
      @version_release = VersionRelease.new
      @version_release.release_type = "Major"
      @version_release.vocabulary_identifier = "v3"
      @version_release.vocabulary = Vocabulary.find_by(identifier: "v3")
      @version_release.update(version_release_params)
      @version_release.save!

      @new_terms = Term.where(vocabulary_identifier: "v3", visibility: "pending")
      @new_terms.each do |term|
        version_release_term = VersionReleaseTerm.new
        version_release_term.change_type = "new"
        version_release_term.term_uri = term.uri
        version_release_term.term_identifier = term.identifier
        version_release_term.version_release = @version_release
        version_release_term.term = term
        version_release_term.save!

        term.visibility = "visible"
        term.save!
        updated_term_identifiers << term.identifier
      end

      @edited_terms = Hist::Pending.all
      @edited_terms.each do |term_needs_reify|
        term = term_needs_reify.reify
        previous_term_state = Term.find_by(identifier: term.identifier)

        if term.pref_label != previous_term_state.pref_label
          version_release_term = VersionReleaseTerm.new
          version_release_term.change_type = "update"
          version_release_term.term_uri = term.uri
          version_release_term.term_identifier = term.identifier
          version_release_term.previous_label = previous_term_state.pref_label
          version_release_term.previous_label_language = previous_term_state.pref_label_language
          version_release_term.version_release = @version_release
          version_release_term.term = term
          version_release_term.save!
        end

        term.visibility = "visible"
        term.save!
        term_needs_reify.destroy!
        updated_term_identifiers << term.identifier
      end
    end

    # FIXME: What about relationships that are removed?...
    updated_term_identifiers.each do |identifier|
      term = Term.find_by(identifier: identifier)

      if term.broader.present?
        term.broader.each do |broader|
          if broader.present?
            broader_object = Term.find_by(uri: broader)
            broader_object.narrower = broader_object.narrower + [term.uri]
            broader_object.narrower.uniq
            broader_object.save
          end
        end
      end

      if term.narrower.present?
        term.narrower.each do |narrower|
          if narrower.present?
            narrower_object = Term.find_by(uri: narrower)
            narrower_object.broader = narrower_object.broader + [term.uri]
            narrower_object.broader.uniq
            narrower_object.save
          end

        end
      end

      if term.related.present?
        term.related.each do |related|
          if related.present?
            #related = related.split("(").last[0..-1]
            related_object = Term.find_by(uri: related)
            related_object.related = related_object.related + [term.uri]
            related_object.related.uniq
            related_object.save
          end
        end
      end
    end

    redirect_to vocabulary_term_new_path(vocab_id: "v3")
  end

  def verify_permission
    if !current_user.superuser?
      redirect_to root_path
    end
  end

  def version_release_params
    params.require(:version_release).permit(:release_identifier, :release_date)
  end
end