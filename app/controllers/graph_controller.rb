class GraphController < ApplicationController
  def tree
    @terms = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'identifier_ssi, prefLabel_tesim, narrower_ssim' )
    @data = {name: "Homosaurus V3"}
    @data[:children] = []

    top_level = HomosaurusV3Subject.where(broader: []).sort_by { |t| t.label.downcase }

    top_level.each do |top|
      top_row = { name: top.label, ident: top.identifier }
      if top.narrower.present?
        top_row[:children] = get_narrower(top.narrower)
      end
      @data[:children] << top_row
    end
  end

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
    @terms = HomosaurusV3Subject.find_with_conditions(q: "*:*", rows: '10000', fl: 'identifier_ssi, prefLabel_tesim, narrower_ssim' )
    @data = {name: "Homosaurus V3"}
    @data[:children] = []

    top_level = HomosaurusV3Subject.where(broader: []).sort_by { |t| t.label.downcase }

    top_level.each do |top|
      top_row = { name: top.label, ident: top.identifier }
      if top.narrower.present?
        top_row[:children] = get_narrower(top.narrower)
      end
      @data[:children] << top_row
    end

    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end
end