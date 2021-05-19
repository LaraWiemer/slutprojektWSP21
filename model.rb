module Model


  #Creates an ad through inserting it into the database
  # @param [String] :ad_name, the name of the ad
  # @param [String] :description, the description of the ad
  # @param [String] :db_path, the path for the image of the ad
  # @param [String] :price, the price of the ad
  # @param [String] :category_id, the id of the category of the ad
  # @param [String] :user_id, the id of the user that is creating the ad
  
  def add_ad(ad_name, description, db_path, price, category_id, user_id) 
    if price.include?("kr") == false
      price = price + " kr"
    end
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("INSERT INTO advertisements(name, description, img_path, price) VALUES (?, ?, ?, ?)", ad_name, description, db_path, price)
    ad_id_hash = db.execute("SELECT ad_id FROM advertisements WHERE name = ? AND img_path = ?", ad_name, db_path).first
    ad_id = ad_id_hash["ad_id"].to_i
    db.execute("INSERT INTO ad_to_user(user_id, ad_id) VALUES (?, ?)", user_id, ad_id)
    db.execute("INSERT INTO ad_to_category(ad_id, category_id) VALUES (?, ?)", ad_id, category_id)
  end


  #Finds the ads that belong to the selected user
  #@param [Integer], :user_id, the id of the user
  #@return [array], all id's of the ads owned by the user

  def ads_by_user(user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT ad_id FROM ad_to_user WHERE user_id = ?",user_id)
    ads_by_user = result.map do |el|
      db.execute("SELECT * FROM advertisements WHERE ad_id = ?", el["ad_id"]).first
    end
    return ads_by_user
  end


  #Finds the filepath to the image of an ad
  #@params [String] :id, the id of the ad
  #@return [Hash], contains the image path of the selected ad

  def get_db_path(id) 
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT img_path FROM advertisements WHERE ad_id = ?", id)
  end


  #Updates an ad, if the price string does not already end with " kr" the function will add this
  #@param [String] :ad_name, the new name of the ad
  #@param [String] :description, the new description of the ad
  #@param [String] :price, the new price of the ad
  #@param [Integer] :category_id, the id of the new category
  #@param [Integer] :ad_id, the id of the ad

  def update_ad(ad_name, description, price, category_id, ad_id)
    if price.include?("kr") == false
    price = price + " kr"
    end
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("UPDATE advertisements SET name = ?, description = ?, price = ? WHERE ad_id = ?", ad_name, description, price, ad_id)
    db.execute("UPDATE ad_to_category SET category_id = ? WHERE ad_id = ?", category_id, ad_id)
  end


  #Updates the image path of an ad
  #@param [String] :db_path, the new image path
  #@param [Integer] :ad_id, the id of the ad being updated

  def update_ad_picture(db_path, ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("UPDATE advertisements SET img_path = ? WHERE ad_id = ?", db_path, ad_id)
  end


  #Deletes an ad from the database
  #@param [Integer] :ad_id, the id of the ad being deleted

  def delete_ad(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("DELETE FROM advertisements WHERE ad_id = ?", ad_id)
    db.execute("DELETE FROM ad_to_user WHERE ad_id = ?", ad_id)
    db.execute("DELETE FROM ad_to_category WHERE ad_id = ?", ad_id)
  end


  #Finds the content of an ad
  #@param [Integer] :ad_id, the id of the ad
  #@return [Hash], the content of the ad

  def ad_content(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    ad_content = db.execute("SELECT * FROM advertisements WHERE ad_id = ?", ad_id).first
    return ad_content
  end


  #Finds the category of an ad
  #@param [Integer] :ad_id, the id of the ad
  #@return [Hash], the category_id of the ad

  def ad_to_category(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    category_id = db.execute("SELECT * FROM ad_to_category WHERE ad_id = ?", ad_id).first
    return category_id
  end


  #Selects everything from the categories table in the database
  #@return [Hash], the data from the categories table

  def get_categories()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM categories")
  end


  #Searches for the fileending of the original filename
  #@param [String] :original_filename, the filename that was uploaded
  #@return [String], the fileending

  def search_file_ending(original_filename)
    array = original_filename.split(".")
    result = "." + array[1]
    return result
  end


  #Creates a user
  #@param [String] :username, the username of the new user
  #@param [String] :password, the password of the new user
  #@param [String] :phone_number, the phone number of the new user
  #@return [Array], the user_id and the group_id

  def register_user(username, password, phone_number)
    pwdigest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash
    db.execute("INSERT INTO users(username, pwdigest, phone_number) VALUES (?, ?, ?)", username, pwdigest, phone_number)
    result = db.execute("SELECT user_id FROM users WHERE username = ? AND pwdigest = ?", username, pwdigest).first.first
    user_id = result
    group_id = 1
    db.execute("INSERT INTO user_to_group(user_id, group_id) VALUES (?, ?)", user_id, group_id)
    return [user_id, group_id]
  end


  #Checks if the login data is correct
  #@param [String] :username, the username of the user attempting to log in
  #@param [String] :password, the password of the user attempting to log in
  #@return [Array], If the password matches the password in the database return an array with the user_id and group_id
  #@return [nil], If the username or password does not match the database return nil

  def login(username, password)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
   result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    if result != nil
      pwdigest = result["pwdigest"]
      user_id = result["user_id"]
      group_id_hash = db.execute("SELECT group_id FROM user_to_group WHERE user_id = ?", user_id).first
      group_id = group_id_hash["group_id"]    
      if BCrypt::Password.new(pwdigest) == password
       return [user_id, group_id]
      else
        return nil
     end
   else
      return nil
    end
  end


  #Selects all ads
  #@return [Array], returns an array with all the ads as hashes

  def get_ads()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM advertisements")
    return result
  end


  #Selects all content from the users table in the database
  #@return [Array], returns an array with all the users as hashes

  def get_all_user_content()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM users")
  end


  #Selects all content from the user_to_group table in the database
  #@return [Array], returns an array with each user to group relation in a hash

  def get_user_to_group()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM user_to_group")
  end


  #Selects all content from the groups table
  #@return [Array], returns an array with each group as a hash

  def get_groups()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM groups")
  end


  #Selects all data about a user
  #@param [String] :user_id, the id of the user
  #@return [Hash], the information about the user

  def get_user_content(user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM users WHERE user_id = ?", user_id).first
  end


  #Selects the id of the group the user is in
  #@param [Integer] :user_id, the id of the user
  #@return [Hash], the user_id to group_id relation

  def get_one_user_to_group(user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM user_to_group WHERE user_id = ?", user_id).first
  end


  #Joins the strings into an array
  #@params [String] :strings, the strings
  #@return [Array], the strings in an array

  def all_of(*strings)
    return /(#{strings.join("|")})/
  end
 

  #Finds the id of the user who the ad belongs to
  #@param [Integer] :ad_id, the id of the ad
  #@return [Hash], the user_id of the user that the ad belongs to

  def check_user_id_ad(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT user_id FROM ad_to_user WHERE ad_id = ?", ad_id).first
  end


  #Updates the users group through updating the group_id in the table user_to_group in the database
  #@param [Integer] :user_id, the id of the user
  #@param [Integer] :group_id, the id of the new group

  def admin_update_useraccess(user_id, group_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("UPDATE user_to_group SET group_id = ? WHERE user_id = ?", group_id, user_id)    
  end


  #Deletes a user
  #@param [Integer] :user_id, the id of the user

  def delete_user(user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("DELETE FROM users WHERE user_id = ?", user_id)
    db.execute("DELETE FROM user_to_group WHERE user_id = ?", user_id)
    array = db.execute("SELECT * FROM ad_to_user WHERE user_id = ?", user_id)
    array.each do |ad_id|
      db.execute("DELETE FROM advertisements WHERE ad_id = ?", ad_id)
    end
  end

end