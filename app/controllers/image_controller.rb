require 'RMagick'

class ImageController < ApplicationController
	before_filter :check_sizes, :only => [:show, :show_gray, :show_crazy]

	def show
		gabba = Gabba::Gabba.new("UA-42448491-1", "stevensegallery.com")
		gabba.event("Images", "Show", "Size", "#{@width*@height}", true)
		gabba.page_view("Show", "#{@width}/#{@height}")
		//Gabba::Gabba.new("UA-42448491-1", "stevensegallery.com").event("Images", "Show", "Size", "#{@width*@height}", true)
		return_image(@width,@height)
	end

	def show_gray
		gabba = Gabba::Gabba.new("UA-42448491-1", "stevensegallery.com")
		gabba.event("Images", "ShowGray", "Size", "#{@width*@height}", true)
		gabba.page_view("ShowGray", "#{@width}/#{@height}")
		//Gabba::Gabba.new("UA-42448491-1", "stevensegallery.com").event("Images", "ShowGray", "Size", "#{@width*@height}", true)
		return_image(@width,@height,:grayscale)
	end

private
	def check_sizes
		@width = params[:width].to_i
		@height = params[:height].to_i
		return render :nothing => true, :status => 400 if @height == nil || @width == nil || @height < 1 || @width < 1
		return render :nothing => true, :status => 403 if @height > 2000 || @width > 2000
	end

	def return_image(width, height, *args)
		grayscale = args.include?(:grayscale)
		crazy = args.include?(:crazy)
		filename = get_image_filename(width, height, grayscale, crazy)
		image = Magick::Image.read(filename).first
		response.headers["Content-Type"] = image.mime_type
		render :text => image.to_blob
	end

	def get_image_filename(width, height, grayscale=false, crazy=false)
		path = ['images','generated']
		path << 'grayscale' if grayscale
		path << 'crazy' if crazy
		path << "#{width}x#{height}.jpg"
		filename = Rails.root.join(*path)
		return filename if FileTest.exists?(filename)

		original_path = ['images','source']
		original_path << 'crazy' if crazy
		original_path << '*.*'
		original_filename = Dir.glob(Rails.root.join(*original_path)).sample
		image_original = Magick::Image.read(original_filename).first
		image = image_original.resize_to_fill(width,height)
		image = image.quantize(256,Magick::GRAYColorspace) if grayscale
		image.write(filename)
		filename
	end
end
