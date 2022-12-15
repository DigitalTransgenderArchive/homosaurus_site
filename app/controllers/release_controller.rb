class ReleaseController < ApplicationController

  def index
    @releases = VersionRelease.all.order('id DESC')
  end

  def show
    @release = VersionRelease.find_by(id: params[:release_id])
    @release_terms = @release.version_release_terms
    @release_terms = @release_terms.sort_by { |release_term| release_term.term.pref_label.downcase }
    @terms = @release_terms.map { |rt| rt.term }
    @terms.sort_by! { |term| term.pref_label.downcase }

    respond_to do |format|
      format.html
      format.nt { render body: Term.all_terms_full_graph(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonld { render body: Term.all_terms_full_graph(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttl { render body: Term.all_terms_full_graph(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
      format.csv { send_data Term.csv_download(@terms), filename: "Homosaurus_#{identifier}_#{Date.today}.csv" }
      format.xml { render body: Term.xml_basic_for_terms(@terms), :content_type => 'text/xml' }
      format.marc { render body: Term.marc_basic_for_terms(@terms), :content_type => 'text/xml' }

      format.ntV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:ntriples), :content_type => "application/n-triples" }
      format.jsonldV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:jsonld, standard_prefixes: true), :content_type => 'application/ld+json' }
      format.ttlV2 { render body: Term.all_terms_full_graph_v2(@terms).dump(:ttl, standard_prefixes: true), :content_type => 'text/turtle' }
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