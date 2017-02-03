require 'byebug'
require 'open-uri'
require 'pp'
require 'nokogiri'
require 'progress_bar'
require 'json'

# product = {
#   id: id,
#   data_itemid: data_itemid,
#   index: index,
#   name: name,
#   link: link,
#   price: price,
#   sale_price: sale_price,
#   swatches: swatches,
#   arrival_order: arrival_order,
#   best_seller_order: best_seller_order,
#   category: category,
#   sub_category: sub_category,
# }

#srule=newarrivals&sz=100&start=0
#srule=bestsellers&sz=100&start=0
# http://www.agacistore.com/whats-new/
# http://www.agacistore.com/whats-new-swimwear/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-dresses/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-tops/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-bottoms/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-bottoms/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-jumpsuits-rompers/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-jackets-coats/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-clothes-sweaters-cardigans/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-oshoes/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-boutique-five/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-Lingerie/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-Accessories/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-so-exclusive/?sz=100&format=ajax
# http://www.agacistore.com/whats-new-back-in-stock/
# http://www.agacistore.com/whats-new-best-sellers/
# http://www.agacistore.com/whats-new-best-sellers-clothes/
# http://www.agacistore.com/whats-new-best-sellers-oshoes/
# http://www.agacistore.com/whats-new-best-sellers-boutique-five/
# http://www.agacistore.com/whats-new-best-sellers-accessories/
# http://www.agacistore.com/whats-new-%23trendingnow/
# http://www.agacistore.com/whats-new-current-obsession/



def get_categories
  url = "http://www.agacistore.com/" #NEW ARRIVALS
  page = Nokogiri::HTML(open(url))
  nav_container = page.css('.menu-category')
  categories = []
  nav_container.css(".level-1 > li").each do |nav|
    category = nav.css("a").first.text.strip
    link = nav.css("a").first['href']
    sub_categories = []
    nav.css(".level-2").css("li").each do |sub_nav|
      if sub_nav.css("a").first.nil?
      else
        sub_category = sub_nav.text.strip
        sub_link = sub_nav.css("a").first['href']
        sub_categories << {
          sub_category: sub_category,
          sub_link: sub_link
        }
      end
    end
    categories << {
      category: category,
      link: link,
      sub_categories: sub_categories,
    }
  end
  categories.delete(categories[-1])
  categories
end

@products = {}

def handle_category(category, sub_category=nil, third_category=nil)
  arrivals = true
  best_seller = true
  index = 0
  while arrivals do
    arrivals = get_page_results(index, category, sub_category, third_category, true, false)
    index = index + 100
  end
  index = 0
  while best_seller do
    best_seller = get_page_results(index, category, sub_category, third_category, false, true)
    index = index + 100
  end
end

def get_page_results(index, category, sub_category=nil, third_category=nil, arrival=false, best_seller=false)
  base_url = category[:link]
  if arrival
    url = base_url + "?srule=newarrivals&sz=100&start=" + index.to_s + "&format=ajax"
  else
    url = base_url + "?srule=bestsellers&sz=100&start=" + index.to_s + "&format=ajax"
  end
  page = Nokogiri::HTML(open(url))

  rows = page.css('div.product-tile')
  if rows.length < 1
    return false
  end

  rows.each do |product_container|
    arrival_order = index
    product = handle_product(product_container, index, category[:category], sub_category, third_category, arrival,  best_seller)
    index = index + 1
  end
  return true
end

def handle_product(product, index, category, sub_category=nil, third_category=nil, arrival=false,  best_seller=false)
  id = product['id']
  data_itemid =  product['data-itemid']
  name = product.css(".name-link").first.text
  link = product.css(".name-link").first['href']

  if product.css(".price").first.nil?
    price = product.css(".product-standard-price").text
    sale_price = product.css(".product-sales-price").text
  else
    sale_price = nil
    price = product.css(".price").first.text
  end
  swatches = []
  product.css(".swatch-list li").each do |swatch|
    if swatch.css("img").first.nil?
      break
    end
    swatch_name = swatch.css("img").first.attributes['title'].value
    swatch_image = swatch.css("img").first.attributes['src'].value
    swatch_link = swatch.css("a").first.attributes['href'].value
    swatch_primary = swatch.css("a").first.attributes['class'].value == "swatch selected"
    swatches << {
      swatch_name: swatch_name,
      swatch_image: swatch_image,
      swatch_link: swatch_link,
      swatch_primary: swatch_primary,
    }
  end

  final_categories = {
    category: category,
    sub_category: sub_category,
    third_category: third_category,
    arrival: arrival ? index : nil,
    best_seller: best_seller ? index : nil,
  }
  if @products[link].nil?
    final_product = {
      id: id,
      data_itemid: data_itemid,
      name: name.strip,
      link: link,
      price: price,
      sale_price: sale_price,
      swatches: swatches,
      categories: [final_categories]
    }
    @products[link] = final_product
  else
    @products[link][:categories] << final_categories
  end
  @products[link]
end
categories = get_categories

barCategory = ProgressBar.new(categories.length)
categories.each do |category|
  barCategory.increment!
  handle_category(category, nil, nil)
  pp "1: #{category[:category]}"
  barSubCategory = ProgressBar.new(category[:sub_categories].length)
  category[:sub_categories].each do |sub_category|
    barSubCategory.increment!
    replacement = category
    replacement[:link] = sub_category[:sub_link]
    handle_category(replacement, sub_category[:sub_category], nil)
    pp "1: #{category[:category]}, 2: #{sub_category[:sub_category]}"
    page = Nokogiri::HTML(open(sub_category[:sub_link]+ "?format=ajax"))

    page.css(".active").css(".level-2" ).each do |third|

      replacement = category
      replacement[:link] = third.css("a").first['href']
      if third.text.strip.include? "Earrings"
        handle_category(replacement, sub_category, "Earrings")
        pp "1: #{replacement[:category]}, 2: #{sub_category[:sub_category]}, 3: Earrings"
        replacement[:link] = third.css("a").last['href']
        handle_category(replacement, sub_category, "Drop Earrings")
        pp "1: #{replacement[:category]}, 2: #{sub_category[:sub_category]}, 3: Drop Earrings"
      else
        handle_category(replacement, sub_category, third.text.strip)
        pp "1: #{replacement[:category]}, 2: #{sub_category[:sub_category]}, 3: #{third.text.strip}"
      end

    end
    # hande_sub_category(sub_category)
  end
end

File.open("products.json","w") do |f|
  f.write(@products.to_json)
end


pp "hi"
