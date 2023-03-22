namespace :scrape do
    desc 'Scrape restaurant data'
    task restaurants: :environment do
      require 'json'
      require 'open-uri'
      require 'down'
      require 'mime/types'
      require 'net/http'
      require_relative '../scraper'
  
      #   Restaurant.delete_all # Clear existing data from the database
  
      # Loop through the URLs and scrape data for each restaurant
      # urls = [
      #   Url.all.each do |url|
      #     {'name': url.name, 'url': url.url}
      #   end
      #  ]
       Url.all.each do |url|
        scraper = Scraper.new(url.url)
        # data = scraper.scrape
        if url.name == "Zomato"
          data = scraper.restaurant_data_zomato(url.url)
        else
          data = scraper.restaurant_data_magicpin(url.url)
        end
        # File.write("output.json", JSON.pretty_generate(data)) 
      # Save Restaurant Data
        create_restaurant(data)
      # Save Restaurant Data
      end
    end
    def create_restaurant(data)
      
      data.each do |restaurant_data|
        location_data = restaurant_data[:restaurant][:location]
        # Find for Location first
        location = Location.find_or_create_by(name: location_data)
        # end Find for Location first

        # Getting location Object to store its id and updating the params object
          restaurant_data[:restaurant][:location] = location
        # Getting location Object to store its id
        restaurant = Restaurant.find_or_create_by(name: restaurant_data[:restaurant][:name]) do |r|
          r.attributes = restaurant_params(restaurant_data)
        end
        
        # return
        if restaurant.save
           # Save Logo image and cover_img
          logo_url = restaurant_data[:restaurant][:logo_img]
          cover_url = restaurant_data[:restaurant][:cover_img]
          save_image_to_directory(logo_url,'logo',restaurant,'logo_img')
          save_image_to_directory(cover_url,'cover',restaurant,'cover_img')

          puts "Saved restaurant #{restaurant.name}"


          puts "Now creating RestaurantImage Object of #{restaurant.name}"
          
          # create_restaurant_images(restaurant,restaurant_data[:restaurant][:images])
          create_restaurant_related_products(restaurant,restaurant_data[:restaurant][:more_like_this])
          # File.write("output.json", JSON.pretty_generate(restaurant_data[:restaurant]))
          # puts "Now creating CategoryAndItems Object of #{restaurant_data[:restaurant][:category]}"
          create_category_and_items(restaurant,restaurant_data[:restaurant][:category])
          # puts "Created Object of #{restaurant_data[:restaurant][:category]}"
       

        else
          puts "Failed to save restaurant #{restaurant.name}: #{restaurant.errors.full_messages}"
        end
      end
    end

    def create_restaurant_related_products(restaurant,more_like_this)
      # File.write("output.json", JSON.pretty_generate(more_like_this))
      if more_like_this.present?
        more_like_this[:restaurant].each do |restaurant_data|
        

          # Getting location Object to store its id and updating the params object
          
          # Getting location Object to store its id
          location_data = restaurant_data[:restaurant][:location]
          # Find for Location first
          location = Location.find_or_create_by(name: location_data)
          restaurant_data[:restaurant][:location] = location
          new_restaurant_data = Restaurant.find_or_create_by(name: restaurant_data[:restaurant][:name]) do |r|
            r.attributes = restaurant_params(restaurant_data)
          end
          # Finaly Save MoreLikeThisContent Here
          more_like_this = MoreLikeThi.find_or_create_by(restaurant_id: restaurant.id, related_content_id: new_restaurant_data.id, restaurant_name: new_restaurant_data.name)
          # Finaly Save MoreLikeThisContent Here
          if new_restaurant_data.save ||  more_like_this.save
            create_restaurant_images(new_restaurant_data,restaurant_data[:restaurant][:images])
            puts "Now creating Restaurant data from more Like this Object of #{new_restaurant_data.name} and adding id to moreLikeThis Table"
          else
            puts "Failed to save restaurant #{new_restaurant_data.name}: #{new_restaurant_data.errors.full_messages}"
          end
          # File.write("output.json", JSON.pretty_generate(new_restaurant_data.name))
        end
      end
    end
    def create_restaurant_images(restaurant,images)
      # puts images.inspect
      if images.present?
        images[:images].each do |img|
          restaurant = Restaurant.find_by_id restaurant.id
          # img[:restaurant_id] = restaurant
          
          restaurant_images = RestaurantImage.find_or_create_by(name: img[:name], restaurant_id: restaurant.id) do |r|
            r.attributes = restaurant_images_params(img)
          end
          if restaurant_images.save
            save_image_to_directory(img[:image],'gallery',restaurant_images,'image')
          else
            puts "Failed to save restaurant #{restaurant_images.name}: #{restaurant_images.errors.full_messages}"
          end
          
        end
      end
    end
    def save_image_to_directory(img_url,name,restaurant,field_name)
      if img_url.present?
        uri = URI.parse(img_url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          response = http.get(uri.path)
          file = Down.download(img_url)
          mime_type = MIME::Types[file.content_type].first
          if mime_type == 'image/webp'
            filename = "#{File.basename(img_url)}-#{name}.webp"
          else
            filename = File.basename(img_url)
            # filename = "#{restaurant.id}-logo_url.jpg"
          end
          if name == "gallery"
            filepath = Rails.root.join('public', 'uploads', 'gallery', filename)
          else
            filepath = Rails.root.join('public', 'uploads', filename)
          end
          if File.exist?(filepath)
            puts "#{name} file already exists at #{filepath}. Skipping download..."
          else
            # filepath = File.expand_path(filename, Dir.pwd) 
            open(filepath, 'wb') do |file|
              file.write(response.body)
            end
            restaurant.update(field_name => filename)
          end
        end
      end
    end

    #Save Category and items here
    def create_category_and_items(restaurant,categories)
      categories.each do |category_data|
        category_name = category_data[:category_name]
        items_data = category_data[:items]
      
        category = Category.find_or_create_by(name: category_name, restaurant_id: restaurant.id)
      puts "category #{category}"
        if category.save
          items_data.each do |item_data|
            item_name = item_data[:name]
            item_price = item_data[:price]
            item_food_type = item_data[:food_type]
            description = item_data[:description]
            image = item_data[:image]
        
            item = Item.find_or_create_by(
              name: item_name,
              price: item_price,
              food_type: item_food_type,
              description: description,
              image: image,
              category_id: category.id,
              restaurant_id: restaurant.id
            )
          end
        end
      end      
    end
    private

    def restaurant_params(data)
      data.fetch(:restaurant, {}).except(:restaurant_details, :more_like_this, :images, :category)
    end
    def restaurant_images_params(data)
      data.fetch(:images, {})
    end
  end
  