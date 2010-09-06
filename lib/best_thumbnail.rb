require 'rubygems'
require 'RMagick'

class Array
  def self.average(vectors)
    result = Array.new(vectors.first.size, 0)
    vectors.each do |vector|
      vector.each_with_index do |value,index|  
        result[index] += value
      end
    end
    result.map!{|value| value.to_f / vectors.size}
  end
  
  def variance(average)
    result = 0
    self.each_with_index do |value,index|
      result += (value - average[index])**2
    end
    Math.sqrt(result.to_f / average.size)
  end
end

class BestThumbnailLookupError < StandardError; end

class BestThumbnail
  
  HISTOGRAM_COLUMN_COUNT = 256
  INTEGER_MAX = 2**31-1
  
  def initialize(files)
    @files = files
    @histograms = {}
  end
  
  def find
    begin
      build_histograms
    rescue => err
      raise BestThumbnailLookupError, err
    end
    
    best_thumb = nil
    closest_result = INTEGER_MAX

    @histograms.each_pair do |filename, value|
      res = value.variance(@average_histogram)
      if res < closest_result 
        closest_result = res
        best_thumb = filename
      end
    end
    puts "Best file #{best_thumb}"
    best_thumb
  end
   
  private
  def pixel_intensity(pixel)
    (306*(pixel.red) + 601*(pixel.green) + 117*(pixel.blue))/1024
  end

  def pixel_color(pixel)
    pixel.green & 240 + (pixel.red & 224) / 16 + (pixel.blue & 128) / 128
    #(Math.log(pixel.green + 1) * 100).to_i
  end
  
  def build_histograms
    @files.each do |filename|
      puts "Processing #{filename}"
      image = Magick::Image.read(filename).first
      
      puts "Creating Histogram for #{filename}"
      histogram = image.quantize(256, Magick::RGBColorspace, false, 0, false).color_histogram()
      greens = Array.new(HISTOGRAM_COLUMN_COUNT, 0)
      histogram.each_pair do |color, count| 
        greens[color.intensity * 255 / Magick::MaxRGB] += count 
      end
      @histograms[filename] = greens
    end
    @average_histogram = Array.average(@histograms.values)
  end

end
