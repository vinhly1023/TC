class SearchController < ApplicationController
  PER_PAGE = 50

  def index
    q = params[:q].to_s.strip
    return if q.blank?
    @rs = search_result q
    @search_string = @rs[:search_string]
  end

  def search_result(search_string)
    start_loop = Time.now.to_f
    condition = q_string_to_hash search_string

    if condition.blank?
      runs = Run.paginate(page: params[:page], per_page: PER_PAGE).where("JSON_SEARCH(data, 'one', ? COLLATE utf8_general_ci) IS NOT NULL", "%#{search_string}%").order(updated_at: :desc)
    else
      filter = []
      template = []
      args = []

      condition.each do |key, value|
        template << '(json_extract(data, ?)) = ? COLLATE utf8_general_ci'
        args << "$.#{key}" << "\"#{value}\""
      end

      filter << template.join(' and ')
      filter += args

      runs = Run.paginate(page: params[:page], per_page: PER_PAGE).where(filter).order(id: :desc)

      new_search = []
      condition.each { |k, v| new_search << "#{k}: #{v}" }
      new_search = new_search.join('; ')
    end

    end_loop = Time.now.to_f
    duration = (end_loop - start_loop).round(3)

    { runs: runs, duration: duration, search_string: new_search || search_string }
  end

  def q_string_to_hash(q_string)
    return if q_string.blank?

    conditions = q_string.split(';')
    conditions.reject!(&:empty?)
    conditions.reject! { |c| !c.include?(':') }
    conditions.map! { |c| c.split(':').map(&:strip) }
  end
end
