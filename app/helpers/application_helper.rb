# frozen_string_literal: true

# app/helpers/application_helper.rb

module ApplicationHelper
  def bootstrap_class_for_flash(type)
    case type
    when 'success' then 'alert-success'
    when 'error' then 'alert-danger'
    when 'alert' then 'alert-warning'
    else 'alert-info' # 'notice' falls here
    end
  end

  def render_chapter_table(items)
    content_tag(:div, class: 'table-responsive') do
      content_tag(:table, class: 'table table-striped table-hover table-sm mb-0 mel-table') do
        concat(content_tag(:thead) do
          content_tag(:tr) do
            concat(content_tag(:th, 'Item', class: 'col-item'))
            concat(content_tag(:th, class: 'text-center col-installed') do
              concat(content_tag(:span, 'Installé', class: 'd-none d-sm-inline'))
              concat(content_tag(:span, 'INS', class: 'd-inline d-sm-none'))
            end)
            concat(content_tag(:th, class: 'text-center col-required') do
              concat(content_tag(:span, 'Requis', class: 'd-none d-sm-inline'))
              concat(content_tag(:span, 'REQ', class: 'd-inline d-sm-none'))
            end)
            concat(content_tag(:th, 'Conditions de la tolérance', class: 'col-conditions'))
          end
        end)
        concat(content_tag(:tbody) do
          items.each do |item|
            tr_options = {}
            if item[:installed].to_i.positive? && item[:installed] == item[:required]
              tr_options[:class] = 'clickable-row'
              tr_options[:data] = { item_name: item[:name] }
            end

            concat(content_tag(:tr, tr_options) do
              concat content_tag(:td, item[:name], class: 'col-item')
              concat content_tag(:td, item[:installed], class: 'text-center col-installed')
              concat content_tag(:td, item[:required], class: 'text-center col-required')
              concat content_tag(:td, item[:notes], class: 'col-conditions')
            end)
          end
        end)
      end
    end
  end

  def markdown(text)
    return '' if text.blank?

    MarkdownService.new.render(text)
  end
end
