# = ThirtyBoxes
#   a trival interface for the 30Boxes API by Shawn Veader
#   
# Author    :: Shawn Veader (veader@gmail.com)
# Copyright :: Copyright (c) 2006 Shawn Veader (veader@gmail.com)
# License   :: MIT <http://www.opensource.org/licenses/mit-license.php>
#
# Thanks to Scott Raymond <sco@redgreenblu.com> for his Flickr API code.
#
# USAGE:
#  require 'ThirtyBoxes'                  : include 30Boxes API
#  boxes = ThirtyBoxes.new                : create 30Boxes client
#  auth_url = boxes.authorization_Url     : create the url needed to obtain the
#																						auth_key from the user
#  boxes.auth_key = auth_key              : set the auth_key needed for some API
#																						calls
#  user = boxes.user                      : get current user's information (via
#																						the auth_key)
#  user = boxes.user('veader@gmail.com')  : search for user and pull their info
#  events = boxes.events_Get              : get events for user (via auth_key)
#  etc...
#

require 'cgi'
require 'net/http'
require 'rubygems'
require 'xmlsimple'
require 'parsedate'

class ThirtyBoxes
  attr_accessor :auth_key
  
  # NOTE: fill in your own API key and application name.
  # (API Key available at http://30boxes.com/api/api.php?method=getKeyForUser)
  def initialize(api_key, app_name)
    @auth_key = nil
    @api_key = api_key
    @app_name = app_name
    @host = 'http://30boxes.com'
    @api_path = '/api/api.php'
  end

  # given an API method and parameters, returns an XmlSimple document...	
  def request(method, *params)
    response = XmlSimple.xml_in(http_get(request_url(method, params)), 
																{'ForceArray' => false})
    raise response['err']['msg'] if response['stat'] != 'ok'
    response
  end
	
  # takes an API call and creates the appropriate URL for the REST API...
  def request_url(method, *params)
    url = "#{@host}#{@api_path}?method=#{method}&apiKey=#{@api_key}"
    url += "&authorizedUserToken=#{@auth_key}" if @auth_key
    params[0][0].each_key do |key| 
			url += "&#{key}=" + CGI::escape(params[0][0][key]) 
		end if params[0][0]
		url
  end
	
  # does an HTTP GET on a given URL and returns the body of the response...
  def http_get(url)
  	puts "API URL: #{url}" # DEBUG
    Net::HTTP.get_response(URI.parse(url)).body.to_s
  end
  
  # generate an authorization URL to get the needed authorization key...
  def authorization_Url(return_url=nil,app_logo_url=nil)
    # name of application is required.
    raise 'Application Name Required' if @app_name.nil?
		param_hash = {}
		param_hash['applicationName'] = @app_name
		param_hash['returnUrl'] = return_url unless return_url.nil?
		param_hash['applicationLogoUrl'] = app_logo_url unless app_logo_url.nil?
  	request_url('user.Authorize', [param_hash])
  end
  
  # get a user's information...
  # pass either an ID or email address to lookup a specific user or if
  #		the auth_key is present and no lookup specified, pull current
  #		user's information...
  # implements: user.FindByEmail, user.FindById, and user.GetAllInfo
  def user(lookup=nil)
    if lookup
      user = user_FindByEmail('email' => lookup) rescue user_FindById('id' => lookup)
      return User.new(user['user']) if user['user']
    elsif @auth_key
      user = user_GetAllInfo
      return User.new(user['user']) if user['user']
    end
    nil # fall through return...
  end

  # call the event method with the given parameters and return an EventList...
  def events(method, params)
    # can't do this without an auth_key...
    raise 'Authentication Key required.' if @auth_key.nil?
    
    events = request(method, params)
    return EventList.new(events['eventList']) if events['eventList']
    
    nil # fall through return...
  end
  
  # implements: events.Get to return EventList instead of XmlSimple...
  def events_Get(start_date=nil, end_date=nil)
    param_hash = {}
    param_hash['start'] = start_date unless start_date.nil?
    param_hash['end'] = end_date unless end_date.nil?
    
    events('events.Get',param_hash)
  end
  
  # implements: events.Search to return EventList instead of XmlSimple...
  def events_Search(query=nil)
    events('events.Search',{'query' => query})
  end
  
  # implements: events.TagSearch to return EventList instead of XmlSimple...
  def events_TagSearch(tags=nil)
    events('events.TagSearch',{'tag' => tags})
  end

	# implements: events.AddByOneBox to return EventList instead of XmlSimple...
	def events_AddByOneBox(event=nil)
		events('events.AddByOneBox',{'event' => event})
	end
  
  
  # where the "magic" happens...
  # any method not defined explicitly will be passed on to the 30Boxes API,
  #   and return as an XmlSimple document...
  def method_missing(method_id, *params)
    request(method_id.id2name.gsub(/_/, '.'), params[0])
  end

	# method to abstract the parsing of dates...
	def self.get_date(date)
    ParseDate.parsedate(date) unless date.nil? or date.empty?
    #DateTime.strptime(date,'%Y-%m-%dd') unless date.nil?
	end


  # --------------------------------------------------------------------------
  class User
    attr_reader :id, :last_name, :first_name, :personal_site, :avatar, :emails, :primary_email, :buddies, :im, :feeds
    # other info => :start_day, :use_24_hour_clock, :create_date
    
    def initialize(user_hash)
      @id = user_hash['id']
      @last_name = user_hash['lastName']
      @first_name = user_hash['firstName']
      @personal_site = user_hash['personalSite']
      @avatar = user_hash['avatar']

			# TODO: things to add
			# dateFormat
			# timeZone
			# createDate
			# startDay
			# use24HourClock
			# otherContact { type, value }
      
      @emails  ||= []
      @buddies ||= []
      @feeds   ||= []
      @im      ||= []
      
      # collect the emails...
      unless user_hash['email'].nil?
        for email in user_hash['email']
          @primary_email = email['address'] if email['primary'] == '1'
          @emails << email['address']
        end
      end
      
      # collect buddies...
      @buddies = user_hash['buddy'].collect { |buddy| Buddy.new(buddy) } unless user_hash['buddy'].nil?
      
      # collect feeds...
      @feeds = user_hash['feed'].collect { |feed| Feed.new(feed) } unless user_hash['feed'].nil?
      
      # collect IMs...
      @im = user_hash['IM'].collect { |im| Im.new(im) } unless user_hash['IM'].nil?
    end
  end # User
  
  class Buddy
    attr_reader :id, :last_name, :first_name
  	
    def initialize(buddy_hash)
      @id         = buddy_hash['id']
      @first_name = buddy_hash['firstName']
      @last_name  = buddy_hash['lastName']
    end
  end # Buddy
  
  class Im
    attr_reader :username, :type
    
    def initialize(im_hash)
      @username = im_hash['username']
      @type     = im_hash['type']
    end
  end # Im
  
  class Feed
    attr_reader :name, :url
    
    def initialize(feed_hash)
      @name = feed_hash['name']
      @url  = feed_hash['url']
    end
  end # Feed
    
  class EventList
    attr_reader :events, :user_id, :start_date, :end_date, :search
    
    def initialize(list_hash)
      @user_id = list_hash['userId'] unless list_hash['userId']
      @search = list_hash['search'].nil? ? list_hash['tagSearch'] : list_hash['search']
      @start_date = ThirtyBoxes.get_date(list_hash['listStart']) 
      @end_date = ThirtyBoxes.get_date(list_hash['listEnd']) 
      
      @events ||= []
      
      # collect the events...
      unless list_hash['event'].nil?
        begin
          @events = list_hash['event'].collect { |event| Event.new(event) }
        rescue TypeError # have only one, not many events...
          @events << Event.new(list_hash['event'])
        end
      end
    end
  end # EventList
  
  class Event
    attr_reader :start_date, :end_date, :id, :notes, :summary, :tags, :all_day_event, :repeat_end_date, :repeat_type, :privacy
    # other info => invitation[isInvitation] <- and others within invitation...
  	
    def initialize(event_hash)
      @id = event_hash['id']
      @start_date = ThirtyBoxes.get_date(event_hash['start']) 
      @end_date = ThirtyBoxes.get_date(event_hash['end']) 
      @notes = event_hash['notes']
      @summary = event_hash['summary']
      @tags = event_hash['tags']
      @all_day_event = (event_hash['allDayEvent'] == '1')
      @repeat_end_date = ThirtyBoxes.get_date(event_hash['repeatEndDate']) 
      @repeat_type = event_hash['repeatType']
      @privacy = event_hash['privacy']

			# TODO: things to add
			# repeateSkipDates
			# reminder
			# invitation { isInvitation }
    end
  end # Event
end
