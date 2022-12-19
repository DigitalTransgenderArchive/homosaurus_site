class VersionReleaseTerm < ActiveRecord::Base
  belongs_to :version_release
  belongs_to :term

  serialize :changed_uris, Array
  serialize :changed_uri_labels, Array

  def self.append_redirect(new_ident)
    version = VersionRelease.last
    term = Term.find_by(identifier: new_ident)
    replaced_terms = Term.where(is_replaced_by: "https://homosaurus.org/v3/#{new_ident}").order("lower(pref_label) ASC")
    version_release_term = VersionReleaseTerm.new
    version_release_term.change_type = "redirect"
    version_release_term.term_uri = term.uri
    version_release_term.term_identifier = term.identifier
    version_release_term.version_release = version
    version_release_term.term = term

    replaced_terms.each do |r_term|
      version_release_term.changed_uris += [r_term.uri]
      version_release_term.changed_uri_labels += [r_term.pref_label]
    end

    version_release_term.save!
  end
end