require 'open-uri'
require 'uri'
require 'mechanize'
require 'nokogiri'
require 'selenium-webdriver'
require 'set'

class Scraper
  attr_reader :url

  def initialize(url)
    @url = url
    @agent = Mechanize.new { |a| a.user_agent_alias = 'Linux Firefox' }
    @visited_urls = Set.new
  end

  def restaurant_data_magicpin(url, max_depth = 1, depth = 1)
    puts url
    restaurants = []
    page = @agent.get(url)
    uri = URI.parse(url)
    if uri.scheme.nil? || uri.host.nil?
      puts "Invalid URL"
      return restaurants
    elsif  !page.uri.to_s.end_with?('/Restaurant/') && !page.uri.to_s.end_with?('/india/')
      begin
        puts "This is not a restaurant listing URL"
        more_like_this = related_restaurant(page, nil)
        restaurant = more_like_this
      rescue => e
        puts "Error occurred: #{e.message}"
        # next
      end
     restaurants << restaurant
    else
      puts "This is a restaurant listing URL2"
      page.search('.store').take(5).each do |restaurant_elem|
        begin
          name = restaurant_elem.search('.merchant-name span a').text.strip if restaurant_elem.search('.merchant-name span a').present?
          location = restaurant_elem.at('p.merchant-location').text.strip if restaurant_elem.at('p.merchant-location').present?
          cuisines = restaurant_elem.search('.store-info .tags .tag:has(p.tag-title:contains("Cuisines:")) a').map { |cuisine| cuisine.text.strip }.reject(&:empty?) if restaurant_elem.search('.store-info .tags .tag:has(p.tag-title:contains("Cuisines:")) a').present?
          save_percentage = restaurant_elem.search('.save-percent').text.strip if restaurant_elem.search('.save-percent').present?
          details_url = restaurant_elem.at('.merchant-name span a')['href']
          # extract the cover image url
          cover_img = restaurant_elem.at('.cover-image-holder img.cover-image')['src']
  
          # extract the logo image url
          logo_img = restaurant_elem.at('.merchant-logo-holder img.merchant-logo')['src']
          restaurant_details = restaurant_details_extract_magicpin(details_url)
  
          restaurant = {
            restaurant: {
              name: name,
              web_name: 'Magicpin',
              location: location,
              cuisines: cuisines,
              cover_img: cover_img,
              logo_img: logo_img,
              save_percentage: save_percentage,
              phone: restaurant_details[:phone],
              images: restaurant_details[:images],
              price_range: restaurant_details[:price_range],
              rating: restaurant_details[:rating],
              description: restaurant_details[:description],
              address: restaurant_details[:address],
              more_like_this: restaurant_details[:more_like_this]
            },
            type: 'Listing'
          }
          restaurants << restaurant
        rescue => e
          puts "Error occurred: #{e.message}"
          next
        end
      end
    
    end
   
    restaurants
  end

  def restaurant_details_extract_magicpin(details_url)
    return if @visited_urls.include?(details_url)

    @visited_urls.add(details_url)
    details_page = @agent.get(details_url)

    phone_elems = details_page.search('.merchant-call .merchant-sub-content')
    phones = phone_elems.map { |phone_elem| phone_elem.text.strip } if phone_elems.present?
    address = details_page.at('.merchant-address .merchant-sub-content').text.strip if details_page.at('.merchant-address .merchant-sub-content').present?
    description = details_page.search('.merchant-description').text.strip if details_page.search('.merchant-description').present?
    rating_elem = details_page.at('.ratings-value')
    rating = rating_elem.text.strip.split('/').first.to_f if rating_elem.present?
    cost_for_two_elem = details_page.at('.merchant-sub-content')
    cost_for_two = cost_for_two_elem.text.strip if cost_for_two_elem.present?
    tab_link = details_page.link_with(text: 'Photos')
    page = tab_link.click if tab_link
    images = []
    if page.present?
      images = page.search('.gallery-photo-holder img').map do |img|
        # Extract the filename from the image URL
        filename = img['src'].split('/').last
        # , id: SecureRandom.uuid
        { image: img['src'], name: filename, restaurant_id: nil}
      end
    end
   
    restaurant_details = {
      phone: phones,
      images: { 
        images: images,
      },
      price_range: cost_for_two,
      rating: rating,
      description: description,
      address: address
    }

    sections = []
    found_start = false
      # div = details_page.search('a.voucher-card[data-subject-type="merchant"]')
      details_page.css('section.collections-container').each do |section|
        if section.css('h2.collections-header').text == 'More like this!'
          found_start = true
          sections << section
        elsif found_start
          break
        end
      end
      sections.each do |section|
        section.css('a.voucher-card').each do |store_link|
          cover_img = store_link.at('.voucher-banner-holder img')['src']
          store_url = store_link['href']
          store_details = related_restaurant(store_url, cover_img)
          restaurant_details[:more_like_this] ||= {}
          restaurant_details[:more_like_this][:restaurant] ||= []
          restaurant_details[:more_like_this][:restaurant] << store_details if store_details
        end
      end

    restaurant_details
  end

  def related_restaurant(details_url, cover_img)
    return if @visited_urls.include?(details_url)
    @visited_urls.add(details_url)
    details_page = @agent.get(details_url)
    
    logo_img = details_page.at('img.merchant-logo')['src']
    phone_elems = details_page.search('.merchant-call .merchant-sub-content')
    phones = phone_elems.map { |phone_elem| phone_elem.text.strip } if phone_elems.present?
    address = details_page.at('.merchant-address .merchant-sub-content').text.strip if details_page.at('.merchant-address .merchant-sub-content').present?
    description = details_page.search('.merchant-description').text.strip if details_page.search('.merchant-description').present?
    rating_elem = details_page.at('.ratings-value')
    rating = rating_elem.text.strip.split('/').first.to_f if rating_elem.present?
    cost_for_two_elem = details_page.at('.merchant-sub-content')
    cost_for_two = cost_for_two_elem.text.strip if cost_for_two_elem.present?
    tab_link = details_page.link_with(text: 'Photos')
    page = tab_link.click if tab_link
    images = []
    if page.present?
      images = page.search('.gallery-photo-holder img').map do |img|
        # Extract the filename from the image URL
        filename = img['src'].split('/').last
        # , id: SecureRandom.uuid
        { image: img['src'], name: filename, restaurant_id: nil}
      end
    end

    # Fetch items now
    items = []
    if details_page.link_with(text: 'Items')
      page_item = details_page
    elsif details_page.link_with(text: 'Delivery')
      # tab_link_item = details_page.link_with(text: 'Delivery')
      page_item = details_page
    else
      page_item = details_page
    end
    categories = page_item.search('.categoryListing') # select all elements with class name 'categoryListing'
    result = []
    categories.each do |category|
    
      category_name = category.at('h4.categoryHeading').text.strip # fetch the category name
      
      items = category.search('.itemDetails')
      items_array = items.map do |item|
        # puts item.at('article.itemInfo a')
        item_name = item.at('article.itemInfo a').text.strip  # fetch the item name
        item_description = item.search('.description').text.strip # fetch the item name
        item_price = item.at('span.itemPrice').text.strip.scan(/\d+/).join.to_i # fetch the item price
        veg_icon = item.at('img[src$="veg-icon.svg"]') # check if the item has a vegetarian icon
        nonveg_icon = item.at('img[src$="non-veg-icon.svg"]') 
        image_element = item.search('span.itemImageHolder img')[1] if item.search('img.itemImage').length > 1
        image = image_element['src'] if image_element.present?
        
        if veg_icon
          food_type = "veg"
        else
          food_type = "non-veg"
        end
        { name: item_name, price: item_price , food_type: food_type, image: image, description: item_description }
      end
      
      result << { category_name: category_name, items: items_array }
    end
    # Fetch items now

    name = details_page.search('.merchant-name h1 a').text.strip if details_page.search('.merchant-name h1 a').present?
    location = details_page.at('a.merchant-locality').text.strip if details_page.at('a.merchant-locality').present?
    cuisines = details_page.search('.detail-sub-section.merchant-top-content a').map { |cuisine| cuisine.text.strip }.reject(&:empty?) if details_page.search('.detail-sub-section.merchant-top-content a').present?
   
    store_details = {
      restaurant:{
        name: name,
        location: location,
        cuisines: cuisines,
        save_percentage: nil,
        web_name: 'Magicpin',
        phone: phones,
        cover_img: cover_img,
        logo_img: logo_img,
        images: { 
          images: images,
        },
        price_range: cost_for_two,
        rating: rating,
        description: description,
        address: address,
        category: result
      }
    }

    store_details
  end

  def restaurant_data_zomato(url)
    puts url
    restaurants = []
    page = @agent.get(url)
    doc = Nokogiri::HTML(page.body)

    # script_tag = page.search("//script[contains(text(),'window.__PRELOADED_STATE__')]").first
    script_tag = page.search('//script[contains(text(), "window.__PRELOADED_STATE__")]').first
    json_data = script_tag.content.match(/JSON.parse\("(.*)"\);/)[1].gsub('\\"', '"').gsub('\\\\', '\\')
    data = JSON.parse(json_data)
    res_id = data["pageUrlMappings"].values[0]['resId']

    name =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_BASIC_INFO']['name']
    location =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_RES_HEADER_DETAILS']['LOCALITY']['text']
    cuisines =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_BASIC_INFO']['cuisine_string'].split(',')
    rating =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_BASIC_INFO']['rating']['rating_text']
    cover_img = data['entities']['IMAGES'].values[0]['url']
    description =  data['pages']['restaurant']["#{res_id}"]['navbarSection'][1]['pageDescription'] if data['pages']['restaurant']["#{res_id}"]['navbarSection'].present?
    address =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_RES_CONTACT']['address']
    phone =  data['pages']['restaurant']["#{res_id}"]['sections']['SECTION_RES_CONTACT']['phoneDetails']['phoneStr'].split(',')
    
    categories =  data['pages']['restaurant']["#{res_id}"]['navbarSection'][1]['children'] if data['pages']['restaurant']["#{res_id}"]['navbarSection'].present?
    
    result = []
    categories.each do |category|
      cat_items =  data['pages']['restaurant']["#{res_id}"]['order']['menuList']['menus'] 
      cat_items.map do |item|
        category_name = item['menu']['name'] # fetch the category name
        real_items = item['menu']['categories'][0]['category']['items']
        items_array = real_items.map do |real_item|
          item_name =   real_item['item']['name'] # fetch the item name
          item_description = real_item['item']['desc'] # fetch the item name
          item_price = real_item['item']['min_price'] # fetch the item name
          dietary_slugs = real_item['item']['dietary_slugs'][0] # fetch the item name
          image = real_item['item']['item_image_url'] # fetch the item name
          # puts item_name, item_description, item_price, dietary_slugs,image
          if dietary_slugs == "veg"
            food_type = "veg"
          else
            food_type = "non-veg"
          end
          { name: item_name, price: item_price , food_type: food_type, image: image, description: item_description }
        end
        result << { category_name: category_name, items: items_array }
      end
      
    end
    # File.write("output.json", JSON.pretty_generate(result)) 
   
    # puts result
    restaurant = {
        restaurant: {
          name: name,
          web_name: 'Zomato',
          location: location,
          cuisines: cuisines,
          cover_img: cover_img,
          logo_img: nil,
          save_percentage: nil,
          phone: phone,
          images: nil,
          price_range: nil,
          rating: rating,
          description: description,
          address: address,
          more_like_this: nil,
          category: result
        },
        type: 'Listing'
      }
      restaurants << restaurant
      restaurants
  end

  def restaurant_data_swiggy(url)
    return "Coming Soon!"
  end

  def restaurant_data_anon(url)
    return "Coming Soon!"
  end
end
