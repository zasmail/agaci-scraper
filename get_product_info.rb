require 'byebug'
require 'open-uri'
require 'pp'
require 'nokogiri'
require 'progress_bar'
require 'json'

def get_swatch_info(swatch)
  url = swatch['swatch_link'] + "&format=ajax"
  page = Nokogiri::HTML(open(url))
  swatch['images'] = get_images(page)
  swatch['sizes'] = get_sizes(page)
  swatch['color'] = page.css(".selected").text.strip
  swatch['complementary_product_ids'] = complementary_product_ids(page)
  swatch['description'] = page.css("#tab1").text.strip
  swatch['details'] = page.css("#tab2").text.strip
  return swatch
end

def complementary_product_ids(page)
  ids = []
  page.css(".capture-product-id").each do |id|
    ids << id.text.strip
  end
  ids
end

def get_images(page)
  images = []
  index = 0
  page.css("img").each do |img|
    index = index
    image_link= img['data-zoom-image']
    if image_link.nil?
      break
    end
    images << {
      index: index,
      image_link: image_link,
    }
    index = index + 1
  end
  return images
end

def get_sizes(page)
  sizes = []
  page.css("li .emptyswatch a").each do |size|
    sizes << {
      size: size.text.strip,
      link: size['href']
    }
  end
  return sizes
end

file = File.read('products_with_categories.json')
data_hash = JSON.parse(file)
products = []
bad_products = []
bar = ProgressBar.new(data_hash.length)
data_hash.each do |product|
  bar.increment!
  swatches = []
  if product['swatches'].length < 1
    bad_products << product
  end
  product['swatches'].each do |swatch|
    swatches << get_swatch_info(swatch)
  end
  product['swatches'] = swatches
  products << product
end
File.open("products_with_swatches.json","w") do |f|
  f.write(products.to_json)
end
File.open("bad_products.json","w") do |f|
  f.write(bad_products.to_json)
end

pp "hi"
