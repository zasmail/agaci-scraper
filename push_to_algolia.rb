require 'json'
require 'pp'
require 'byebug'
require 'algoliasearch'
@products = []
@final_products = []
Algolia.init :application_id => "K1EM661A7Z", :api_key => "8ba3eb41c53f028ca5daf8d354273a5b"
agaci = Algolia::Index.new("agaci_init")

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

def same_record(a, b)
  return a['category'] == b['category'] && a['sub_category'] == b['sub_category'] && a['third_category'] == b['third_category']
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

def print_categories(product)
  product['categories'].each do |category|
    pp "1: #{category['category']}, 2: #{category['sub_category']}, 3:#{category['third_category']}, A: #{category['arrival'].nil? ? "--" : category['arrival']}, B: #{category['best_seller'].nil? ? "--" : category['best_seller']}"
  end
end

def format_category(category)
  category_string = ""
  category_level1 = ""
  category_level2 = ""
  category_level3 = ""
  if !category['category'].nil?
    category_string = category_string + category['category']
    category_level1 = category_level1 + category['category']
    category_level2 = category_level2 + category['category']
    category_level3 = category_level3 + category['category']
  end
  if !category['sub_category'].nil?
    category_string = category_string + " > " + category['sub_category']
    category_level2 = category_level2 + " > " + category['sub_category']
    category_level3 = category_level3 + " > " + category['sub_category']
  else
    category_level2 = nil
    category_level3 = nil
  end
  if !category['third_category'].nil?
    category_string = category_string + " > " + category['third_category']
    category_level3 = category_level3 + " > " + category['third_category']
  else
    category_level3 = nil
  end
  return {
    category_string: category_string,
    category_level1: category_level1,
    category_level2: category_level2,
    category_level3: category_level3,
  }
end

def separate_products(product)
  product['categories'].each do |category|
    formatted_category = format_category(category)
    @products << {
      objectID:         product['data_itemid'],
      name:             product['name'],
      link:             product['link'],
      price:            product['price'],
      sale_price:       product['sale_price'],
      is_on_sale:       product['sale_price'].nil?,
      swatches:         product['swatches'],
      category:         category,
      best_seller:      category['best_seller'],
      arrival:          category['arrival'],
      _tags:            formatted_category[:category_string],
      category_level1:  formatted_category[:category_level1],
      category_level2:  formatted_category[:category_level2],
      category_level3:  formatted_category[:category_level3],
    }
  end
end
["swatch_name",
 "swatch_image",
 "swatch_link",
 "swatch_primary",
 "images",
 "sizes",
 "color",
 "complementary_product_ids",
 "description",
 "details"]
def separate_swatches
  @products.each do |product|
    product[:swatches].each do |swatch|
      hierarchicalCategories = {
        lvl0: product[:category_level1],
        lvl1: product[:category_level2],
        lvl2: product[:category_level3],
      }
      @final_products << {
        objectID:                     product[:objectID] + product[:_tags],
        productID:                    product[:objectID],
        name:                         product[:name],
        link:                         product[:link],
        price:                        product[:price],
        sale_price:                   product[:sale_price],
        is_on_sale:                   !product[:sale_price].nil?,
        best_seller:                  product[:best_seller],
        arrival:                      product[:arrival],
        _tags:                        product[:_tags],
        hierarchicalCategories:       hierarchicalCategories,
        swatch_name:                  swatch['swatch_name'],
        swatch_image:                 swatch['swatch_image'],
        swatch_link:                  swatch['swatch_link'],
        swatch_primary:               swatch['swatch_primary'],
        images:                       swatch['images'],
        swatch_sizes:                 swatch['sizes'],
        swatch_color:                 swatch['color'],
        complementary_product_ids:    swatch['complementary_product_ids'],
        description:                  swatch['description'],
        details:                      swatch['details']
      }
    end
  end
end

def fix_price(product)
  product['price'] = product['price'][1..-1].to_f
  return product
end

file = File.read('products_with_swatches.json')
data_hash = JSON.parse(file)


data_hash.each do |product|
  product = fix_price(product)
  # print_categories(product)
  # pp "--------------------------------"
  product = handle_sub_category(product)
  # print_categories(product)
  # pp "--------------------------------"
  categories = flatten(product['categories'])
  product['categories'] = categories
  # print_categories(product)
  # pp "--------------------------------"
  separate_products(product)
end
separate_swatches
agaci.clear_index
agaci.add_objects(@final_products)
pp "hi"
