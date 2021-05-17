module Model

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

  def ads_by_user(user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT ad_id FROM ad_to_user WHERE user_id = ?",user_id)
    ads_by_user = result.map do |el|
      db.execute("SELECT * FROM advertisements WHERE ad_id = ?", el["ad_id"]).first
    end
    return ads_by_user
  end


  def get_db_path(id) 
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT img_path FROM advertisements WHERE ad_id = ?", id)
  end

  def update_ad(ad_name, description, price, category_id, ad_id)
    if price.include?("kr") == false
    price = price + " kr"
    end
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("UPDATE advertisements SET name = ?, description = ?, price = ? WHERE ad_id = ?", ad_name, description, price, ad_id)
    db.execute("UPDATE ad_to_category SET category_id = ? WHERE ad_id = ?", category_id, ad_id)
  end

  def update_ad_picture(db_path, ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("UPDATE advertisements SET img_path = ? WHERE ad_id = ?", db_path, ad_id)
  end

  def delete_ad(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("DELETE FROM advertisements WHERE ad_id = ?", ad_id)
    db.execute("DELETE FROM ad_to_user WHERE ad_id = ?", ad_id)
    db.execute("DELETE FROM ad_to_category WHERE ad_id = ?", ad_id)
  end

  def ad_content(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    ad_content = db.execute("SELECT * FROM advertisements WHERE ad_id = ?", ad_id).first
    return ad_content
  end

  def ad_to_category(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    category_id = db.execute("SELECT * FROM ad_to_category WHERE ad_id = ?", ad_id).first
    return category_id
  end

  def get_categories()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM categories")
  end

  def search_file_ending(original_filename)
    array = original_filename.split(".")
    result = "." + array[1]
    return result
  end

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

  # def get_group_id(username, phone_number)
  #   db = SQLite3::Database.new('db/handel.db')
  #   db.results_as_hash = true
  #   result = db.execute("SELECT group_id FROM user_to_group WHERE username = ? AND phone_number = ?", username, phone_number)
  # end

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

  # def get_user_preferences(user_id)
  #   db = SQLite3::Database.new('db/handel.db')
  #   db.results_as_hash = true
  #   result = db.execute("SELECT category_id FROM users_categories WHERE user_id = ?",user_id)
  #   user_preferences = result.map do |el|
  #     db.execute("SELECT * FROM categories WHERE category_id = ?", el["category_id"]).first
  #   end
  #   return user_preferences
  # end

  def get_ads()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM advertisements")
    return result
  end

  def get_user_content()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM users")
  end

  def get_user_to_group()
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT * FROM user_to_group")
  end

  def all_of(*strings)
    return /(#{strings.join("|")})/
  end
 
  def check_user_id_ad(ad_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    return db.execute("SELECT user_id FROM ad_to_user WHERE ad_id = ?", ad_id).first
  end



end