class VersionRelease < ActiveRecord::Base
  belongs_to :vocabulary
  has_many :version_release_terms
  has_many :edit_requests

  # Remove terms from a release
  def delete_term_from_release(term_identifiers)
    vController = VocabularyController.new
    term_identifiers.each do |identifier|
      release_term = self.version_release_terms.find_by(term_identifier: identifier)
      term = Term.find_by(identifier: identifier)
      vController.clear_relations(term)
      release_term.destroy
      term.destroy
    end
  end

  def fix_duplicate_release_term(release_identifier, correct_identifier)
    vController = VocabularyController.new
    version_release_term = VersionReleaseTerm.find_by(term_identifier: release_identifier)
    release_term = Term.find_by(identifier: release_identifier)
    correct_term = Term.find_by(identifier: correct_identifier)

    release_term.broader.each do |broader|
      if broader.present?
        broader_object = Term.find_by(uri: broader)
        correct_term.broader = correct_term.broader + [broader_object.uri]
        correct_term.broader.uniq!
        broader_object.narrower = broader_object.narrower + [correct_term.uri]
        broader_object.narrower.uniq!
        broader_object.save
      end
    end

    release_term.narrower.each do |narrower|
      if narrower.present?
        narrower_object = Term.find_by(uri: narrower)
        correct_term.narrower = correct_term.narrower + [narrower_object.uri]
        correct_term.narrower.uniq!
        narrower_object.broader = narrower_object.broader + [correct_term.uri]
        narrower_object.broader.uniq!
        narrower_object.save
      end
    end

    release_term.related.each do |related|
      if related.present?
        related_object = Term.find_by(uri: related)
        correct_term.related = correct_term.related + [related_object.uri]
        correct_term.related.uniq!
        related_object.related = related_object.related + [correct_term.uri]
        related_object.related.uniq!
        related_object.save
      end
    end

    vController.clear_relations(release_term)
    version_release_term.destroy

      #term.destroy
    release_term.is_replaced_by = correct_term.uri
    release_term.visibility = "redirect"
    release_term.save!
  end

  def approved_edit_requests
    return self.edit_requests.where(status: "approved")
  end

  def statistics
    return {
      "terms_added" => self.edit_requests.reject{|er| not er.previous().nil? }.count,
      "terms_modified" => self.edit_requests.reject{|er| er.previous().nil? }.count,
      "approved" => self.edit_requests.where(status: "approved").count,
      "pending" => self.edit_requests.where(status: "pending").count,
      "total" => self.edit_requests.count
    }
  end
  
  def self.get_next_identifier(change_type)
    current_identifier = VersionRelease.all()[-1].release_identifier
    last_published = VersionRelease.where(status: "Published").last
    #current_identifier = last_published.release_identifier
    ci_parts = current_identifier.split(".").map{ |x| x.to_i }
    #while VersionRelease.where(release_identifier: ci_parts.join(".")).count != 0
    if change_type == "Major"
      ci_parts[0] += 1
      ci_parts[1] = 0
      ci_parts[2] = 0
    elsif change_type == "Minor"
      ci_parts[1] += 1
      ci_parts[2] = 0
    elsif change_type == "Patch"
      ci_parts[2] += 1
    end
    #end
    return ci_parts.join(".")
  end
  # Returns whether this version release can be published
  def publishable?
    # If another release has since been published, return false
    if VersionRelease.where("id > #{self.id}").where(status: "Published").count > 0
      return false
    end
    # If there is a pending release preceding this, return false
    if VersionRelease.where("id < #{self.id}").where(status: "Pending").count == 0
      return false
    end
    return true
  end

end
