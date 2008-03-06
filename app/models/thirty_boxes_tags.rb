require 'ThirtyBoxes'

module ThirtyBoxesTags
  include Radiant::Taggable

  tag '30boxes' do |tag|
    tag.expand
  end

  tag '30boxes:events' do |tag|
    tag.expand
  end

  tag '30boxes:events:each' do |tag|
    content = ''
    config = ThirtyBoxesConfig.attributes
    boxes = ThirtyBoxes.new(config[:api_key], config[:api_name])
    boxes.auth_key = config[:auth_token]

    boxes.events_GetDisplayList.events.each do |event|
      tag.locals.event = event
      content << tag.expand
    end

    content
  end

  %w(summary notes).each do |attr|
    tag "30boxes:events:#{attr}" do |tag|
      tag.locals.event.send(attr)
    end
  end

  tag '30boxes:events:date' do |tag|
    tag.locals.event.start_date
  end
end
