ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  # unless html_tag =~ /^<label/
  #   %{<div class="has-error">#{html_tag}<span class="help-block">#{instance.error_message.first}</span></div>}.html_safe
  # else
  #   %{#{html_tag}}.html_safe
  # end

  html = %(<div class="field_with_errors">#{html_tag}</div>).html_safe

  form_fields = [
    'textarea',
    'input',
    'select'
  ]

  elements = Nokogiri::HTML::DocumentFragment.parse(html_tag).css "label, " + form_fields.join(', ')

# abort(elements.inspect)
  elements.each do |e|
    if e.node_name.eql? 'label'
      html = %(<div class="control-group error">#{e}</div>).html_safe
    elsif form_fields.include? e.node_name
      if instance.error_message.kind_of?(Array)
        # abort(instance.error_message.inspect)
        html = %(<div class="control-group error">#{html_tag}<span class="help-inline">&nbsp;#{instance.error_message.uniq.join(', ')}</span></div>).html_safe
      else
        html = %(<div class="control-group error">#{html_tag}<span class="help-inline">&nbsp;#{instance.error_message}</span></div>).html_safe
      end
    end
  end
  html
end