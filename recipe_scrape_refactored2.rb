require 'open-uri'
require 'nokogiri'
require 'rubygems'
require 'postmark'
require 'mail'
require 'json'

class Recipe
  attr_accessor :page, :url, :name, :image, :servings, :ingredients, :instructions

  @@homepage_url = "http://www.epicurious.com" 
  
  def self.new_recipe_of_the_day
    homepage = Nokogiri::HTML(open("#{@@homepage_url}"))
    recipe_of_day_selector = homepage.css("div#pageWrapper div#primary.contentContainer 
                                      div#primary_content div#HProw_rm.HProw.rounded 
                                      div#hp-rm-right.hp-module-right div#hp-recipecentral 
                                      a:last-of-type")
    self.new.tap do |r|
      r.url = @@homepage_url + recipe_of_day_selector[0]["href"]
      r.full_scrape
    end
  end

  def scrape_page
    self.page = Nokogiri::HTML(open("#{self.url}"))
  end

  def scrape_name
    self.name = self.page.css("div#headline h1").text 
  end

  def scrape_image
    image_url_selector = self.page.css("div#recipe_thumb a img")[0]["src"]
    self.image = @@homepage_url + image_url_selector
  end

  def scrape_servings
    self.servings = self.page.css("div#recipe_summary p span").text
  end

  def scrape_ingredients
    ingredients_list = self.page.css("ul.ingredientsList li")
    self.ingredients = ingredients_list.map {|li| li.text}
  end

  def scrape_prep
    preparation = self.page.css("div#preparation.instructions p")
    self.instructions = preparation.map {|i| i.text}
  end

  def full_scrape
    self.scrape_page
    self.scrape_name
    self.scrape_image
    self.scrape_servings
    self.scrape_ingredients
    self.scrape_prep
  end
end

class Email
  attr_accessor :content

  def set_content(name, image, url, servings, ingredients, instructions)
    self.content = "<h2>" + name + "</h2>"
    self.content += "<img src=" + image + "><br>"
    self.content += "<br><a href='#{url}' target='_blank'>" + url + "</a>"
    self.content += "<br><h3>Yield: </h3><p>" + servings + "</p>"
    self.content += "<h3>Ingredients:</h3>"
    self.content += "<ul>"
    
    ingredients.each do |ingredient|
      self.content += "<li>" + ingredient.to_s + "</li>"
    end
    
    self.content += "</ul>"
    self.content += "<h3>Preparation:</h3>"
    
    instructions.each do |instruction|
      self.content += "<p>" + instruction.to_s + "</p>"
    end
  end

  def send(name)
   
   content = self.content

   puts "Please enter your email address:"
   email_address = gets.strip

    message = Mail.new do
      from            ''  #sender email address
      to              email_address
      subject         'Recipe of the Day - ' + name
     
      content_type    'text/html; charset=UTF-8'
      body            content
     
      delivery_method Mail::Postmark, :api_key => 'your-postmark-api-key'
    end
   
    message.deliver
    puts "Check your email for the recipe of the day from Epicurious!"
  end
end


recipe = Recipe.new_recipe_of_the_day
email = Email.new
email.set_content(recipe.name, recipe.image, recipe.url, recipe.servings, recipe.ingredients, recipe.instructions)
email.send(recipe.name)