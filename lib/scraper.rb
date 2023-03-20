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
    page = @agent.get(url)
    if ! page.uri.to_s.end_with?('/Restaurant/')
      puts "This is not a restaurant listing URL"
      related_restaurant(page, nil)
      return
    end
    
    restaurants = []
   
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
          }
        }
        restaurants << restaurant
      rescue => e
        puts "Error occurred: #{e.message}"
        next
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
    # extract the cover image url
    

    # extract the logo image url
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
    name = details_page.search('.merchant-name h1 a').text.strip if details_page.search('.merchant-name h1 a').present?
    location = details_page.at('a.merchant-locality').text.strip if details_page.at('a.merchant-locality').present?
    cuisines = details_page.search('.detail-sub-section.merchant-top-content a').map { |cuisine| cuisine.text.strip }.reject(&:empty?) if details_page.search('.detail-sub-section.merchant-top-content a').present?
   
    store_details = {
      restaurant:{
        name: name,
        location: location,
        cuisines: cuisines,
        save_percentage: nil,
  
        phone: phones,
        cover_img: cover_img,
        logo_img: logo_img,
        images: { 
          images: images,
        },
        price_range: cost_for_two,
        rating: rating,
        description: description,
        address: address
      }
    }

    store_details
  end

  def restaurant_data_zomato(url)
    return "Coming Soon!"
  end

  def restaurant_data_swiggy(url)
    return "Coming Soon!"
  end

  def restaurant_data_anon(url)
    return "Coming Soon!"
  end
end
