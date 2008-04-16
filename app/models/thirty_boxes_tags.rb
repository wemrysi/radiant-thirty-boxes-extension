require 'ThirtyBoxes'

module ThirtyBoxesTags
  include Radiant::Taggable

  # Give all the 30 Boxes tags their own namespace.
  tag '30boxes' do |tag|
    tag.expand
  end

  # Main container tag for 30 Boxes events.
  tag '30boxes:events' do |tag|
    tag.expand
  end

  # Cycle through events.
  #
  # Has the following attributes:
  #   tags: comma separated list of tags to limit the events to
  #   days: number of days from now to include events, defaults to 14
  #   limit: maximum number of events to return, unlimited by default
  tag '30boxes:events:each' do |tag|
    limit = (tag.attr['limit'] || 0).to_i
    tags = (tag.attr['tags'] || '').split(',')
    days = (tag.attr['days'] || 14).to_i
    start_date = Date.today
    end_date = start_date + days
    content = ''

    config = ThirtyBoxesConfig.attributes
    boxes = ThirtyBoxes.new(config[:api_key], config[:api_name])
    boxes.auth_key = config[:auth_token]
    events = boxes.events_GetDisplayList(start_date.to_s, end_date.to_s).events
    
    unless tags.empty?
      events.reject! { |event| (event.tags.to_s.split & tags).empty? }
    end

    events.each_with_index do |event, idx|
      break if (limit > 0) && (idx == limit)
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

  # Displays the start date of the current event.
  #
  # Specify the 'format' attribute with a valid date format string to
  # control the display of the date.
  tag '30boxes:events:start_date' do |tag|
    fmt = tag.attr['format'] || '%b %d, %Y'
    Time.local(*tag.locals.event.start_date).strftime(fmt)
  end
end
