module ViewHelper
  def tc_input_group(label, input, opts = {})
    col_size = opts[:class] && opts[:class][/col-\w+-\d+/] || 'col-sm-5'
    <<-HTML.html_safe
      <div class="form-group #{opts[:group_class]}">
        #{label}
        <div class="#{col_size}">
          #{input}
        </div>
        #{tc_link_tag(opts[:link]) unless opts[:link].nil?}
      </div>
    HTML
  end

  def tc_label_tag(symbol, text)
    label_tag symbol, text, class: 'col-sm-2 control-label'
  end

  def tc_text_field_tag(symbol, text, opts = {})
    options = opts.dup
    options[:class] = 'form-control'
    text_field_tag symbol, text, options
  end

  def tc_password_field_tag(symbol, text, opts = {})
    options = opts.dup
    options[:class] = 'form-control'
    password_field_tag symbol, text, options
  end

  def tc_text_area_tag(symbol, text, size, opts = {})
    options = opts.dup
    options[:class] = 'form-control'
    options[:size] = size
    text_area_tag symbol, text, options
  end

  def tc_select_tag(symbol, options, opts = {})
    opts_dup = opts.dup
    opts_dup[:class] = 'form-control'
    select_tag symbol, options_for_select(options), opts_dup
  end

  def tc_text_input_group(symbol, label_text, value_text = '', opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_text_field_tag(symbol, value_text, opts),
      opts
    )
  end

  def tc_password_input_group(symbol, label_text, value_text = '', opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_password_field_tag(symbol, value_text, opts)
    )
  end

  def tc_text_area_group(symbol, label_text, value_text, size, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_text_area_tag(symbol, value_text, size, opts),
      opts
    )
  end

  def tc_select_group(symbol, label_text, options, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_select_tag(symbol, options, opts),
      opts
    )
  end

  def tc_radio_buttons(symbol, options, selected = nil)
    result = "<div id=\"#{symbol}\" class=\"btn-group btn-group-sm hidden-input\">"
    options.each do |option|
      key = option.is_a?(Array) ? option[0] : option
      value = option.is_a?(Array) ? option[1] : option
      if option.is_a?(Array)
        is_selected = selected.is_a?(Array) ? option == selected : option[0] == selected
      else
        is_selected = option == selected
      end

      result += <<-HTML
        <label class="btn btn-default#{' active' if is_selected}">
          #{radio_button_tag symbol, key, is_selected}
          <span>#{value}</span>
        </label>
      HTML
    end

    result += '</div>'
    result.html_safe
  end

  def tc_radio_buttons_group(symbol, label_text, options, selected = nil, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_radio_buttons(symbol, options, selected),
      opts
    )
  end

  def tc_checkboxes(symbol, options, _selected = [])
    result = "<div id=#{symbol} class=\"btn-group btn-group-sm select_all\">"

    options.each do |option|
      key = option.is_a?(Array) ? option[0] : option
      value = option.is_a?(Array) ? option[1] : option

      result += <<-HTML
        <label class="btn btn-default hidden-input">
          #{check_box_tag("#{symbol}[]", value, false)}
          <span>#{key}</span>
        </label>
      HTML
    end
    result += '</div>'

    if options.size > 1
      select_all_id = symbol.to_s + '_all'
      result += <<-HTML
        <div id="#{select_all_id}" class="btn-group btn-group-sm select_all">
          <label class="btn btn-default hidden-input"><input name="#{select_all_id}" value="all" type="checkbox">
            <span>ALL</span>
          </label>
        </div>
      HTML
    end

    result.html_safe
  end

  def tc_checkboxes_group(symbol, label_text, options, selected = [], opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_checkboxes(symbol, options, selected),
      opts
    )
  end

  def tc_link_tag(link)
    <<-HTML
      <label class="control-label">
        <a href="#{link[:href]}">#{link[:text]}</a>
      </label>
    HTML
  end

  def tc_file_browser_group(symbol, label_text, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_file_browser(symbol, opts),
      opts
    )
  end

  def tc_file_browser(symbol, opts = {})
    <<-HTML.html_safe
      <div class="input-group">
        #{tc_text_field_tag('', '', opts)}
        <span class="input-group-btn">
          <span class="btn btn-default btn-file">Browse&hellip; #{file_field_tag symbol, opts}</span>
        </span>
      </div>
    HTML
  end

  def tc_release_date_group(symbol, label_text)
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_release_date(symbol)
    )
  end

  def tc_release_date(symbol)
    <<-HTML.html_safe
      <div class="input-group">
        <div class="input-group-btn">
          <button class="btn btn-default dropdown-toggle" type="button" data-toggle="dropdown" aria-expanded="true">
            Select
            <span class="caret"></span>
          </button>
          <ul role="menu" class="dropdown-menu" id="#{symbol}_opts">
          </ul>
        </div>
        #{tc_text_field_tag symbol, ''}
      </div>
    HTML
  end

  def tc_number_field_tag(symbol, text, span_text, opts = {})
    options = opts.dup
    options[:class] = 'form-control'

    <<-HTML.html_safe
      <div class="input-group">
        #{number_field_tag symbol, text, options}
        <span class='input-group-addon'>#{span_text}</span>
      </div>
    HTML
  end

  def tc_number_input_group(symbol, label_text, value_text, span_text, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      tc_number_field_tag(symbol, value_text, span_text, opts),
      opts
    )
  end

  def tc_submit_tag(value, opts = {})
    opt = { class: 'btn btn-success' }
    opt.merge!(opts) { |_key, v1, v2| "#{v1} #{v2}" }

    <<-HTML.html_safe
    <div class="form-group">
      <div class="col-sm-offset-2 col-sm-2">
        #{submit_tag value, opt}
      </div>
    </div>
    HTML
  end

  def tc_checkbox_group_origin(symbol, label_text, value, checked = false, opts = {})
    tc_input_group(
      tc_label_tag(symbol, label_text),
      check_box_tag(symbol, value, checked),
      opts
    )
  end

  def generate_controls(outpost_name, crls)
    return '' if crls.blank?

    suffix = outpost_name.parameterize.underscore
    html = ''

    crls.each do |parms|
      k = parms[:name].parameterize.underscore
      opts = parms[:options].nil? ? {} : parms[:options]

      case parms[:type]
      when 'tc_text_input_group'
        html << tc_text_input_group("#{k}_#{suffix}", k.titleize, parms[:value], opts)
      when 'tc_password_input_group'
        html << tc_password_input_group("#{k}_#{suffix}", k.titleize, parms[:value], opts)
      when 'tc_text_area_group'
        html << tc_text_area_group("#{k}_#{suffix}", k.titleize, parms[:value], parms[:size], opts)
      when 'tc_radio_buttons_group'
        html << tc_radio_buttons_group("#{k}_#{suffix}", k.titleize, parms[:value].split(','), parms[:selected], opts)
      when 'tc_checkboxes_group'
        html << tc_checkboxes_group("#{k}_#{suffix}", k.titleize, parms[:value].split(','), parms[:selected], opts)
      when 'tc_select_group'
        html << tc_select_group("#{k}_#{suffix}", k.titleize, parms[:value], opts)
      when 'tc_release_date_group'
        html << tc_release_date_group("#{k}_#{suffix}", k.titleize)
      when 'tc_file_browser_group'
        html << tc_file_browser_group("#{k}_#{suffix}", k.titleize, opts)
      end
    end

    html.html_safe
  rescue => e
    Rails.logger.error "Error while generating control #{ModelCommon.full_exception_error e}"
    ''
  end

  def tc_app_config(config_text, message_id, config_controls, submit_control)
    <<-HTML.html_safe
      <div class="content-header">
        <div class="header-inner">
          <p class='subheader'>#{config_text}</p>
        </div>
      </div>
      <div id="#{message_id}"></div>
      <div class="form-horizontal">
        #{Array.[](config_controls).join('')}
    #{submit_control}
      </div>
    HTML
  end
end
