class HomeController < ApplicationController
  before_filter :get_afx, :only => [:upload, :render_image, :get_filters, :render_options]

  def get_afx
    @afx = AviaryFX::API.new("demoapp", "demoappsecret")
    require 'json'
  end

  def upload
    file_path = RAILS_ROOT + "/public/_tmp_image_upload_#{params[:file].original_filename}"
    File.open(file_path, "wb") do |f|
     while buff = params[:file].read(4096)
       f.write(buff)
     end
    end
  
    response = @afx.upload(file_path)
    File.delete(file_path)
    render :text => response.to_json
  end
  
  def get_filters
        
    filters = @afx.get_filters()
    f_array = []
    filters.each do |f|
      f_array.push({:label => f.label, :uid => f.uid})
    end

    f_hash = {:filter => f_array}
    render :text => f_hash.to_json
  end
  

  def render_options
    backgroundcolor = "0xFFFFFFFF"
    format = "jpg"
    quality = "100"
    scale = "1"
    cols = "3"
    rows = "3"
    cellwidth = "128"
    cellheight = "128"
    filterid = params[:filterid]
    filepath = params[:filepath]
    renderOptionsGrid = @afx.render_options(backgroundcolor, format, quality, scale, filepath, filterid, cols, rows, cellwidth, cellheight)
    
    logger.info renderOptionsGrid.inspect
    
    render_array = []
    renderOptionsGrid.renders.each do |r|
      render_array.push({:col => r.col, :row => r.row, :parameters => r.render_parameter_collection.parameters.collect {|p| {:uid => p.uid, :id => p.id, :value => p.value}}})
    end
    
    grid_hash = {:renderOptionsGrid => {:url => renderOptionsGrid.url}, :renderOptionParams => {:render => render_array}}
    
    render :text => grid_hash.to_json
    
    
  end

  def render_image
    backgroundcolor = "0xFFFFFFFF"
    format = "jpg"
    quality = "100"
    scale = "1"
    width = "0"
    height = "0"
    filterid = params[:filterid]
    filepath = params[:filepath]
    
    renderParameters = "{\"parameters\":" + params[:renderParameters] + "}"
    renderParameterCollection = AviaryFX::RenderParameterCollection.new_from_json(renderParameters)
    
    response = @afx.render(backgroundcolor, format, quality, scale, filepath, filterid, width, height, renderParameterCollection);

    render :text => response.to_json
  end


  def main
  end


end
