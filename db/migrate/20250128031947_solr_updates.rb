class SolrUpdates < ActiveRecord::Migration[5.2]
  def up
    x = EditRequest.find_by(id: 6850).my_changes
    x[4] = x[4].last(3)
    EditRequest.find_by(id: 6850).update(my_changes: x)
    x = EditRequest.find_by(id: 7091).my_changes
    x[4] = x[4].last(2)
    EditRequest.find_by(id: 7091).update(my_changes: x)
    Vocabulary.last(2).each do |v|
      docs = []
      v.terms.all.each do |t|
        pp "==== #{v.identifier}/#{t.identifier} ===="
        docs.append(t.generate_solr_content(v, {}))
      end
      DSolr.put_docs docs
    end
  end
  def down
  end
end
