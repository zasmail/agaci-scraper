require 'json'
require 'pp'
require 'byebug'


def handle_category(product)
  level_1s = product['categories'].map{ |category| category['category'] }.uniq
  categories = []
  level_1s.each do |level_1|
    level_2s = product['categories'].reject{ |a| a['category'] != level_1}
    categories << flatten(level_2s)
  end
  product['categories'] = categories.flatten
  return handle_sub_category(product)
end

def handle_sub_category(product)
  categories = []
  product['categories'].each do |category|
    if !category['sub_category'].nil?
      if category['sub_category'].class != String
        category['sub_category'] = category['sub_category']['sub_category']
      end
    end
    categories << category
  end
  product['categories'] = categories
  return product
end

def handle_third(product)

end

def flatten(categories)
  flattened = []
  categories.each do |category|
    best_seller = find_best_seller(categories, category)
    arrival = find_arrival(categories, category)
    if arrival.nil?
      arrival = best_seller
    end
    if best_seller.nil?
      best_seller = arrival
    end
    if arrival.nil? || best_seller.nil?
      # byebug
    end
    category['best_seller'] = best_seller['best_seller']
    category['arrival'] = arrival['arrival']
    flattened << category
  end
  return flattened.uniq
end

def same_record(a, b)
  return a['category'] == b['category'] && a['sub_category'] == b['sub_category'] && a['third_category'] == b['third_category']
end

def find_best_seller(categories, category)
  categories.detect{ |b_category| same_record(category, b_category) &&! b_category['best_seller'].nil? }
end
def find_arrival(categories, category)
  categories.detect{ |b_category| same_record(category, b_category) && !b_category['arrival'].nil? }
end

file = File.read('products.json')
data_hash = JSON.parse(file)
products = []
data_hash.each do |url, product|
  categories = []
  handled = handle_category(product)
  pp "Product: #{product['name']}"
  handled['categories'].each do |category|
    pp "1: #{category['category']}, 2: #{category['sub_category']}, 3:#{category['third_category']}"
  end
  products << handled

  # level_1s = product['categories'].map{ |category| category['category'] }.uniq
  # level_1s.each do |level_1|
  #   level_2s = product['categories'].reject{ |a| a['category'] != level_1}
  #   byebug
  # end
end
File.open("products_with_categories.json","w") do |f|
  f.write(products.to_json)
end
# handle_category(data_hash.first[1])
# product = data_hash.first[1]
# product['categories'].each do |category|
  # pp "1: #{category['category']}, 2: #{category['sub_category']}, 3:#{category['third_category']}"
# end
pp "hi"
