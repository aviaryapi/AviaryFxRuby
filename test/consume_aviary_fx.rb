require File.join('..', 'lib', 'aviary_fx')

# The following class contains methods
# to get the public methods of the AviaryFX
# API wrapper class.

# To use this class, insantiate it, passing in your api_key
# and api_secret, then call the appropriate test functions

# You can change the parameters passed to the public AviaryFX
# methods in the appropriate test methods below


class ConsumeAviaryFX

  def initialize(api_key, api_secret)
    # Insantiate an AvaiaryFX object, the API wrapper.
    @afx = AviaryFX::API.new(api_key, api_secret)
  end

  def test_render(filepath)
    
    # You can change the following parameters to your test values:
    backgroundcolor = "0xFFFFFFFF"
    format = "jpg"
    quality = "100"
    scale = "1"
    width = "0"
    height = "0"
    filterid = "29"
    
    # renderparamters can be specified in JSON format:
    
    json_render_parameters =  '{"parameters":[{"uid":"0","id":"Scale Factor","value":"1"},{"uid":"1","id":"Rotation in Degrees","value":"337.4212729692043"},{"uid":"2","id":"Crop Left","value":"0"},{"uid":"3","id":"Crop Right","value":"0"},{"uid":"4","id":"Crop Top","value":"0"},{"uid":"5","id":"Crop Bottom","value":"0"},{"uid":"6","id":"Background Color","value":"0"},{"uid":"7","id":"Flip Horizontal","value":"false"},{"uid":"8","id":"Flip Vertical","value":"true"},{"uid":"9","id":"Use Proportional Cropping","value":"false"},{"uid":"10","id":"Cropping Proportions","value":"1"},{"uid":"11","id":"Preserve Original Orientation","value":"true"}]}'
    rpc = AviaryFX::RenderParameterCollection.new_from_json(json_render_parameters)
    
    # Call the API method render via the AviaryFX wrapper:
    return @afx.render(backgroundcolor, format, quality, scale, filepath, filterid, width, height, rpc)
  end
  
  
  def test_render_options(filepath)
      
      #You can change the following parameters to your test values:
      backgroundcolor = "0xFFFFFFFF"
      format = "jpg"
      quality = "100"
      scale = "1"
      cols = "10"
      rows = "10"
      cellwidth = "128"
      cellheight = "128"
      filterid = "22"
    
      # Call the API method renderOptions via the AviaryFX wrapper:
      response = @afx.render_options(backgroundcolor, format, quality, scale, filepath, filterid, cols, rows, cellwidth, cellheight)
      
      return response
  end
  
  def test_get_filters
    # Call the API method getFilters via the AviaryFX wrapper:
    return @afx.get_filters
  end
  
  def test_upload
    # Call the API method upload via the AviaryFX wrapper:
    # You can specify our own valid local filename below:
    return @afx.upload("uploads/ostrich.jpg")
  end
  
end
