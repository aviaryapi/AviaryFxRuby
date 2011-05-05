# Aviary Effects API Ruby Library

## Introduction

A library for the Aviary Effects API written in Ruby.

## Install

1. Download the latest AviaryFX Ruby Library and extract
2. Install the gem:

<pre><code>$ sudo gem install aviary_fx-1.0.0.gem 
</code></pre>

## Test

To test, run test/sample.rb from the command line.

<pre><code>$ ruby sample.rb</code></pre>

## Instantiate an AviaryFX object

The Aviary Effects API is exposed via the AviaryFX class.

To create an instance of the class with your API key and API secret:

<pre><code>require 'aviary_fx'
afx = AviaryFX::API.new("demoapp", "demoappsecret")
</code></pre>

## Get a list of filters

The getFilters() method Array of AviaryFX::FilterInfo objects with label, uid, thumb, description and parameters for each filter. These can be used to render images.

To get the array of filters:

<pre><code>get_filters_response = afx.get_filters()
puts get_filters_response.inspect
</pre></code>

## Upload an image to the AviaryFX Service

The upload() method is used to upload image files to the AviaryFX Service to apply effects to them. This method returns a hash with the url to the file. The returned image url should be used for subsequent interactions.

To upload an image:

<pre><code>response = afx.upload("/full/path/to/image_file.ext")
puts response.inspect
</code></pre>

## Render thumbnails

Use the renderOptions() method to render a thumbnail grid of the image with preset filter options for the selected filter. This returns an array with a url to the thumbnail grid and render option parameters for each of the requested number of options for that filter.

To render a 3x3 thumbnail grid with 128px x 128px cells:

<pre><code>backgroundcolor = "0xFFFFFFFF"
format = "jpg"
quality = "100"
scale = "1"
cols = "3"
rows = "3"
cellwidth = "128"
cellheight = "128"
filterid = "22"
filepath = "http://somedomain.com/your_file_name.ext"
# Call the API method renderOptions via the AviaryFX wrapper:
response = afx.render_options(backgroundcolor, format, quality, scale, filepath, filterid, cols, rows, cellwidth, cellheight)
puts response.inspect
</code></pre>

## Render full image

Once an option is selected call the render() method along with the filter ID, image url and the parameters for the selected option. This returns a dict with the URL to rendered image.

<pre><code>backgroundcolor = "0xFFFFFFFF"
format = "jpg"
quality = "100"
scale = "1"
width = "0"
height = "0"
filterid = "20"
filepath = "http://somedomain.com/your_file_name.ext"
# renderparamters can be specified in JSON format:
json_render_parameters = '{"parameters":[{"id":"Color Count","value":"14"},{"id":"Saturation","value":"1.0353452422505582"},{"id":"Curve Smoothing","value":"3.8117529663284664"},{"id":"Posterization","value":"9"},{"id":"Pattern Channel","value":"7"}]}'
rpc = AviaryFX::RenderParameterCollection.new_from_json(json_render_parameters)
# Call the API method render via the AviaryFX wrapper:
return afx.render(backgroundcolor, format, quality, scale, filepath, filterid, width, height, rpc)
puts response.inspect
</code></pre>

## Methods

Check out the official [Aviary Effects API documentation](http://developers.aviary.com/effects-api) for more details about the Aviary Effects API and class methods.

## Feedback and questions

Found a bug or missing a feature? Don't hesitate to create a new issue here on GitHub, post to the [Google Group](http://groups.google.com/group/aviaryapi) or email us.


