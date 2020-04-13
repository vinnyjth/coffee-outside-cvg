require "mini_magick"


Dir.glob("assets/raw_images/*").each do |i|
  image = MiniMagick::Image.open("./#{i}")
  image.resize "400x400^"
  image.gravity 'center'
  image.crop '400x400+0+0'
  image.write "assets/thumbnails/#{i.split('/')[-1]}"
end

Dir.glob("assets/raw_images/*").each do |i|
  image = MiniMagick::Image.open("./#{i}")
  image.resize "2000x2000>"
  image.write "assets/full_size/#{i.split('/')[-1]}"
end