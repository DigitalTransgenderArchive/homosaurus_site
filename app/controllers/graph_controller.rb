class GraphController < ApplicationController
  def tree
    @data = hierarchy
  end

  def tree_data
    @data = hierarchy
    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end

  private

  def hierarchy
    vocab = Vocabulary.find_by(identifier: Vocabulary.latest)
    identifiers = vocab.terms.where(visibility: "visible").pluck(:id, :identifier).to_h
    ids = identifiers.keys

    labels = {}
    TermRelationship.where(term_id: ids, relation_id: Relation::Pref_label).pluck(:term_id, :language_id, :data).group_by(&:first).each do |id, rows|
      row = rows.find { |r| r[1].to_s == I18n.locale.to_s } || rows.find { |r| r[1].to_s == "en" } || rows.first
      labels[id] = row[2]
    end

    children = Hash.new { |hash, key| hash[key] = [] }
    TermRelationship.where(term_id: ids, relation_id: Relation::Narrower).pluck(:term_id, :data).each do |parent, child|
      children[parent] << child.to_i if identifiers.key?(child.to_i)
    end
    with_broader = TermRelationship.where(term_id: ids, relation_id: Relation::Broader).distinct.pluck(:term_id)

    by_label = ->(list) { list.uniq.sort_by { |id| labels[id].to_s.downcase } }
    node = lambda do |id, seen|
      row = { name: labels[id], ident: identifiers[id] }
      kids = by_label.(children[id]).reject { |kid| seen.include?(kid) }
      seen.merge(kids)
      row[:children] = kids.map { |kid| node.(kid, seen) } if kids.any?
      row
    end

    { name: "Homosaurus #{vocab.version.upcase}", children: by_label.(ids - with_broader).map { |id| node.(id, Set[id]) } }
  end
end
