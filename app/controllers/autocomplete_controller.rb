class AutocompleteController < ActionController::Base

  def lcsh_subject
    authority_check = Mei::Loc.new('subjects')
    authority_result = authority_check.search(params[:q]) #URI escaping doesn't work for Baseball fields?
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

end
