class VersionRelease < ActiveRecord::Base
  belongs_to :vocabulary
  has_many :version_release_terms

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
end