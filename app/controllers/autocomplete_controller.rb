class AutocompleteController < ActionController::Base
  require 'languages'

  def lcsh_subject
    authority_check = Mei::Loc.new('subjects')
    authority_result = authority_check.search(params[:q]) #URI escaping doesn't work for Baseball fields?
    authority_result = [] if authority_result.blank?

    render json: authority_result
  end

  def languages
    params[:q] ||= ''
    original_param = params[:q]

    languages = Languages.search("^#{original_param}", case_sensitive: false)
    languages_array = []

    # Check for english
    if 'english'.include? original_param.downcase
      languages_array << ['English', 'en']
      languages_array << ['English (USA)', 'en-US']
      languages_array << ['English (UK)', 'en-GB']
    end

    # Prefer ISO639_1
    languages.select { |lang| lang.iso639_1.present? }.each do |lang|
      unless lang.iso639_1.to_s == 'en'
        languages_array << [lang.name, lang.iso639_1.to_s]
      end
    end

    languages.select { |lang| lang.iso639_1.blank? }.each do |lang|
      if lang.iso639_2.present?
        languages_array << [lang.name, lang.iso639_2.to_s]
      else
        languages_array << [lang.name, lang.iso639_3.to_s]
      end
    end

    languages_array = languages_array.take(params[:per_page].to_i) if params.has_key? :per_page

    items = languages_array.map do |u|
      {
          id: u[0],
          text: "#{u[0]} (#{u[1]})"
      }
    end

    render json: {
        total_count: items.size,
        items: items
    }
  end

  def self.form_languages
    languages_array = []
    Languages.all.each do |lang|
      if lang.iso639_1.present?
        unless lang.iso639_1.to_s == 'en'
          languages_array << [lang.name, lang.iso639_2.to_s]
        end
      elsif lang.iso639_2.present?
        languages_array << [lang.name, lang.iso639_2.to_s]
      else
        languages_array << [lang.name, lang.iso639_3.to_s]
      end
    end
    languages_array.sort_by! { |lang| lang[0] }
    languages_array = [['English', 'en'], ['English (USA)', 'en-US'], ['English (UK)', 'en-GB']] + languages_array
    languages_array
  end

end
