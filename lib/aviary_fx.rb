require 'digest/md5'
require 'rest-client'
require 'nokogiri'
require 'json'


# We open the Nokogiri::XML module to add a attributes2hash method for an XML node.

module Nokogiri::XML
  class Node

    # Returns:
    # +Hash+ of the attribute key/values of the node
    def attributes2hash
      a = {}
        self.attributes().each do |k, v|
        a[k.to_sym] = v.value
      end
      return a
    end
  end
end

# This module contains classes that are representations of AviaryFX objects, such as
# Filter, FilterParameter, Render, RenderParameter, RenderParameterCollection, etc.
#
# It also contains an API class to use as an API wrapper for the AviaryFX API.


module AviaryFX

  # Holds information about an AviaryFX filter, such as uid, label, description, and
  # an array of FilterParameter objects.

  class FilterInfo
    attr_reader :uid, :label, :description
    # Array of FilterParameter objects
    attr_reader :parameters

    def initialize(options = {})
      @uid = options[:uid]
      @label = options[:label]
      @description = options[:description]
      @parameters = options[:parameters] || []
    end

    def self.new_from_xml(xml_node)
      return self.new(:label => xml_node.attributes()["label"].value,
                      :uid => xml_node.attributes()["uid"].value,
                      :description => xml_node.xpath("description").text,
                      :parameters => xml_node.xpath("filtermetadata/parameter").collect{|p| FilterParameter.new_from_xml(p)})
    end
  end

  # Holds information about an AviaryFX FilterParameter, with properties such as
  # uid, id, type, min, max, and value, although all of these will not always
  # be present for a given filter parameter.

  class FilterParameter
    attr_reader :uid, :id, :type, :min, :max, :value
    # All attributes available from the XML response from Aviary, including ones that may not
    # specifically be mentioned at the time of this writing.
    attr_reader :raw_attributes

    def initialize(options = {})
      @uid = options[:uid]
      @id = options[:id]
      @type = options[:type]
      @min = options[:min]
      @max = options[:max]
      @value = options[:value]
      @raw_attributes = options
    end

    def self.new_from_xml(xml_node)
      self.new(xml_node.attributes2hash)
    end
  end

  # Holds information about an AviaryFX RenderOptionsGrid, including a URL for the grid
  # and an array of the renders in the grid.

  class RenderOptionsGrid
    # Array of Render objects
    attr_reader :renders
    # String containing the URL to the rendered grid
    attr_reader :url

    def initialize(options = {})
      @url = options[:url]
      @renders = options[:renders] || []
    end

    def self.new_from_xml(xml_node)
      self.new(:url => xml_node.xpath("//ostrichrenderresponse/url").text,
               :renders => xml_node.xpath("//ostrichrenderresponse/renders/render").collect {|r| Render.new_from_xml(r) })
    end
  end

  # Holds information about an AviaryFX Render, such as the row and column corresponding to its
  # position in its parent grid as well as a RenderParmeterCollection object.
  class Render
    # Row in the corresponding RenderOptionsGrid
    attr_reader :row

    # Column in the corresponding RenderOptionsGrid
    attr_reader :col

    # RenderParameterCollection objection containing the render parameters for this render
    attr_reader :render_parameter_collection

    def initialize(options = {})
      @row = options[:row]
      @col = options[:col]
      @render_parameter_collection = options[:render_parameter_collection] || RenderParameterCollection.new
    end

    def self.new_from_xml(xml_node)

      self.new(:row => xml_node.attributes()["row"].value,
               :col => xml_node.attributes()["col"].value,
               :render_parameter_collection => RenderParameterCollection.new_from_xml(xml_node.xpath("parameters")))
    end
  end

  # A container class for holding an array of RenderParameter objects.  It is its own class
  # primarily to provide an organized way to convert a set of RenderParameter objects into an XML
  # representation and to convert JSON to a collection of RenderParameter objects.

  class RenderParameterCollection
    # Array of RenderParameter objects
    attr_reader :parameters

    def initialize(options)
      @parameters = options[:parameters] || []
    end

    def self.new_from_xml(xml_node)
      self.new(:parameters => xml_node.xpath("parameter").collect {|p| RenderParameter.new_from_xml(p)})
    end

    # Create a collection of RenderParameter objects from a basic JSON string.

    # Example: '{"parameters":[{"id":"Color Count","value":"14"},{"id":"Saturation","value":"1.0353452422505582"},{"id":"Curve Smoothing","value":"3.8117529663284664"},{"id":"Posterization","value":"9"},{"id":"Pattern Channel","value":"7"}]}'
    def self.new_from_json(json)
      p_hash = JSON.parse(json)

      self.new(:parameters => p_hash["parameters"].collect {|p| RenderParameter.new(:uid => p["uid"], :id => p["id"], :value => p["value"]) })

    end

    def to_xml
      builder = Nokogiri::XML::Builder.new do |xml|
          xml.parameters {
            self.parameters.each do |p|
              xml.parameter({"uid" => p.uid, "id" => p.id, "value" => p.value})
            end
          }
      end

      return Nokogiri::XML(builder.to_xml).root.to_s.gsub(/\n  /, "").gsub(/\n/, "")

    end

  end

  # Holds information about an AviaryFX render parameter, such as id, uid, and value.

  class RenderParameter
    attr_reader :id, :uid, :value

    # all attributes provided in the XML response from the Aviary server, including ones
    # that may not be mentioned specifically at the time of this writing.
    attr_reader :raw_attributes

    def initialize(options = {})
      @id = options[:id]
      @uid = options[:uid]
      @value = options[:value]
      @raw_attributes = options
    end

    def self.new_from_xml(xml_node)
      self.new(xml_node.attributes2hash)
    end
  end

  # The purpose of the AviaryFX::API class is to serve as a wrapper
  # for API calls to the Aviary API

  # First, insantiate the class, passing in your api_key and api_secret.
  #
  # afx = AviaryFX::API.new("your_key", "your_secret")
  #
  # Next, call one of the public methods:
  # * get_time
  # * get_filters
  # * upload
  # * render_options
  # * render
  #
  #
  # Example:
  # afx.get_filters()

  class API

    VERSION = "0.2"
    PLATFORM = "html"
    HARDWARE_VERSION = "1.0"
    SOFTWARE_VERSION = "Ruby"
    APP_VERSION = "1.0"

    # The Base URL For API calls
    SERVER      =   "http://cartonapi.aviary.com/services"

    # The URL fragment for the get_time method
    GET_TIME_URL    = "/util/getTime"

    # The URL fragment for the get_filters method
    GET_FILTERS_URL   =   "/filter/getFilters"

    # The URL fragment for the upload method
    UPLOAD_URL    =   "/ostrich/upload"

    # The URL fragment for the render method
    RENDER_URL    =   "/ostrich/render"

    # Initialize the API wrapper class
    #
    # Params:
    # +api_key+:: +String+ containing your API key
    # +api_secret+:: +String+ containing your API secret

    def initialize(api_key, api_secret)
      @api_key = api_key
      @api_secret = api_secret
    end

    # Uploads an image to the Aviary server.
    #
    # Params:
    # +filename+:: +String+ containing the full local path to the file to upload
    #
    # Returns:
    # +Hash+ containing the URL on the server of the uploaded file.

    def upload(filename)
      params_hash = standard_params
      params_hash[:api_sig] = get_api_signature(params_hash)
      f = File.new(filename, "rb")
      params_hash[:file] = f

      uri = SERVER + UPLOAD_URL
      xml_response = RestClient.post(uri, params_hash)

      xml_doc = load_xml_response(xml_response)

      return {:url => xml_doc.xpath("//file").first.attributes()["url"].value}
    end

    # Renders image based on render parameters.
    #
    # Params:
    # +backgroundcolor+:: +String+ containing the background color
    # +format+:: +String+
    # +quality+:: +String+
    # +scale+:: +String+
    # +filepath+:: +String+ containing the URL of the image to provide options for
    # +filterid+:: +String+ containing the ID of the filter to use
    # +width+:: +String+ containing the width of the image to return
    # +height+:: +String+ containing the height of the image to return
    # +renderparameters+:: +RenderParameterCollection+ object
    #
    # Returns:
    # +Hash+ containing the URL to the rendered image

    def render(backgroundcolor, format, quality, scale, filepath, filterid, width, height, render_parameter_collection)
      params_hash = {
        :calltype => "filteruse",
        :cols => "0",
        :rows => "0",
        :backgroundcolor => backgroundcolor,
        :cellwidth => width,
        :cellheight => height,
        :filterid => filterid,
        :filepath => filepath,
        :quality => quality,
        :scale => scale,
        :format => format,
        :renderparameters => render_parameter_collection.to_xml}

      uri = SERVER + RENDER_URL

      xml_doc = call_api(uri, params_hash)

      return {:url => xml_doc.xpath("//ostrichrenderresponse/url").text}
    end

    # Renders a filter options thumbnail grid and returns render parameters for each option.
    #
    # Params:
    # +backgroundcolor+:: +String+ containing the background color
    # +format+:: +String+
    # +quality+:: +String+
    # +scale+:: +String+
    # +filepath+:: +String+ containing the URL of the image to provide options for
    # +filterid+:: +String+ containing the ID of the filter to use
    # +cols+:: +String+ containing the number of columns to provide in the RenderOptionsGrid
    # +rows+:: +String+ containing the number of rows to provide in the RenderOptionsGrid
    # +cellwidth+:: +String+ containing the width of each cell returned in the grid.
    # +cellheight+:: +String+ containing the height of each cell returned in the grid.
    #
    # Returns:
    # +RenderOptionsGrid+ object

    def render_options(backgroundcolor, format, quality, scale, filepath, filterid, cols, rows, cellwidth, cellheight)
      params_hash = {
        :calltype => "previewRender",
        :backgroundcolor => backgroundcolor,
        :format => format,
        :quality => quality,
        :scale => scale,
        :filepath => filepath,
        :filterid => filterid,
        :cols => cols,
        :rows => rows,
        :cellwidth => cellwidth,
        :cellheight => cellheight }

      uri = SERVER + RENDER_URL;

      xml_doc = call_api(uri, params_hash)

      return RenderOptionsGrid.new_from_xml(xml_doc)

    end

    # Gets a list of available filters.
    #
    # Returns:
    # +Array+ of Filter objects.

    def get_filters
      params_hash = {}
      uri = SERVER + GET_FILTERS_URL
      xml_doc = call_api(uri, params_hash)


      filters = []
      xml_doc.xpath("//filter").each do |f|
        filter= FilterInfo.new_from_xml(f)
        filters.push filter
      end

      return filters
    end


    # Returns the current server time from the AviaryFX API server
    #
    # Returns:
    # +String+ containing the current time on the server

    def get_time
      params_hash = {}
      uri = SERVER + GET_TIME_URL
      xml_doc = call_api(uri, params_hash)

      servertimes = xml_doc.root.xpath("servertime")

      return servertimes.first.text.to_s
    end


    private


    #
    # Returns hash of the standard parameters that must be sent on every API call
    #
    # Returns:
    # +Hash+ of standard parameters that must be sent on every API call

    def standard_params
      params_hash = {}
      params_hash[:api_key] = @api_key
      params_hash[:ts] = Time.now.to_i
      params_hash[:version] = VERSION
      params_hash[:platform] = PLATFORM
      params_hash[:hardware_version] = HARDWARE_VERSION
      params_hash[:software_version] = SOFTWARE_VERSION
      params_hash[:app_version] = APP_VERSION
      return params_hash
    end


    # Calls the API at the given URL with the given parameters and returns the resultant XML document
    #
    # Params:
    # +uri+:: +String+ object containing URL of the API method to call
    # +params_hash+:: +Hash+ object containing the parameters to be sent to the API method
    #
    # Returns:
    # +Nokogiri::XML::Document+ Object

    def call_api(uri, params_hash)
      params_hash = standard_params.merge(params_hash)
      params_hash[:api_sig] = get_api_signature(params_hash)
      xml_response =  request(uri, params_hash)
      return load_xml_response(xml_response)
    end

    # Converts an XML string into a Nokogiri XML Document
    # Also raises error if the XML cannot be loaded or the response contains errors from the API
    #
    # Params:
    # +xml_response+:: +String+ object containing XML
    #
    # Returns:
    # +Nokogiri::XML::Document+ object

    def load_xml_response(xml_response)
      begin
        xml_doc = Nokogiri::XML(xml_response)
      rescue
        raise StandardError, "Unable to load XML response from API"
      end

      response = xml_doc.xpath("response")

      if !response || response.empty? || response.first.attributes()["status"].value != "ok"
        raise StandardError, "Error loading response or error returned from API"
      end

      return xml_doc
    end

    #
    # Sends a standard POST to the given URL with the given POST parameters and returns the response
    #
    # Params:
    # +uri+:: +String+ containing the URL to which to POST
    # +post_hash+:: +Hash+ containing the hash of parameters to POST
    #
    # Returns:
    # +String+ containing the response from the server.

    def request(uri, post_hash)
      url = URI.parse(uri)
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(post_hash)
      sock = Net::HTTP.new(url.host, url.port)
      res = sock.start {|http| http.request(req)}
      return res.body
    end


    #
    # Returns the API signature for the params
    #
    # Params:
    # +params_hash+:: +Hash+ containing the base parameters to be sent to the server, not including the API signature
    #
    # Returns:
    # +String+ containing the API signature to be used with the given params hash.
    #

    def get_api_signature(params_hash)
      params_string = params_hash.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }.collect {|e| "#{e.first}#{e.last}" }.join("")
      string_to_md5 =  @api_secret + params_string
      api_sig = Digest::MD5.hexdigest(string_to_md5)
      return api_sig
    end

  end

end
