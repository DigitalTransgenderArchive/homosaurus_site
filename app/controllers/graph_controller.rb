class GraphController < ApplicationController
  def tree
    @terms = Term.find_with_conditions(q: "*:*", rows: '10000', fl: 'identifier_ssi, prefLabel_tesim, narrower_ssim', model: 'HomosaurusV3' )
    @data = {name: "Homosaurus V3"}
    @data[:children] = []

    top_level = Term.where(vocabulary_identifier: "v3", broader: []).sort_by { |t| t.pref_label.downcase }

    top_level.each do |top|
      top_row = { name: top.pref_label, ident: top.identifier }
      if top.narrower.present?
        top_row[:children] = get_narrower(top.narrower.map { |n| n.split('/').last })
      end
      @data[:children] << top_row
    end
  end

  # FIXME: This will only work because v3 identifiers are unique
  def get_narrower(ident_list, current_row=[])
    ident_list.sort_by{|t|t.downcase}.each do |ident|
      item_row = @terms.select { |row| row["identifier_ssi"] == ident }.first
      this_row = {name: item_row["prefLabel_tesim"].first, ident: item_row["identifier_ssi"]}
      if item_row["narrower_ssim"].present?
        this_row[:children] = []
        get_narrower(item_row["narrower_ssim"], this_row[:children])
      end
      current_row << this_row
    end

    current_row
  end


  def tree_data
    @terms = Term.find_with_conditions(q: "*:*", rows: '10000', fl: 'identifier_ssi, prefLabel_tesim, narrower_ssim', model: "HomosaurusV3" )
    @data = {name: "Homosaurus V3"}
    @data[:children] = []

    top_level = Term.where(vocabulary_identifier: "v3", broader: []).sort_by { |t| t.pref_label.downcase }

    top_level.each do |top|
      top_row = { name: top.pref_label, ident: top.identifier }
      if top.narrower.present?
        top_row[:children] = get_narrower(top.narrower.map { |n| n.split('/').last })
      end
      @data[:children] << top_row
    end

    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end
end