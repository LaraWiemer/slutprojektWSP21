



def add_ad(ad_name, description, db_path, price, user_id)
    
  if price.include?("kr") == false
    price = price + " kr"
  end
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  db.execute("INSERT INTO advertisements(name, description, img_path, price, user_id) VALUES (?, ?, ?, ?, ?)", ad_name, description, db_path, price, user_id)
end

def register_user(username, password, phone_number)
  pwdigest = BCrypt::Password.create(password)
  db = SQLite3::Database.new('db/handel.db')
  db.execute("INSERT INTO users(username, pwdigest, phone_number) VALUES (?, ?, ?)", username, pwdigest, phone_number)
end

def search_file_ending(original_filename)
  array = original_filename.split(".")
  result = "." + array[1]
  return result
end

def login(username, password)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  pwdigest = result["pwdigest"]
  id = result["user_id"]
  if BCrypt::Password.new(pwdigest) == password
    session[:user_id] = id
    return true
  else
    return false
  end

end

def locate_user_id(username)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  id = db.execute("SELECT user_id FROM users WHERE username = ?")
  session[:user_id] = id
end

def ads_by_user(user_id)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM advertisements WHERE user_id = ?", user_id)
  return result
end

def get_db_path(id) 
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  result = db.execute("SELECT img_path FROM advertisements WHERE ad_id = ?", id)
end

def update_ad(ad_name, description, price, ad_id)
  price = price + " kr"
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  db.execute("UPDATE advertisements SET name = ?, description = ?, price = ? WHERE ad_id = ?", ad_name, description, price, ad_id)
end

def update_ad_picture(db_path, ad_id)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  db.execute("UPDATE advertisements SET img_path = ? WHERE ad_id = ?", db_path, ad_id)
end

def delete_ad(id)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  db.execute("DELETE FROM advertisements WHERE ad_id = ?", id)
end

def ad_content(ad_id)
  db = SQLite3::Database.new('db/handel.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM advertisements WHERE ad_id = ?", ad_id)
end



def get_user_prefrences(user_id)
  db = SQLite3::Database.new("db/handel.db")
  db.results_as_hash = true
  user_topic_id = db.execute("SELECT topic_id FROM users_topics WHERE user_id = ?",user_id)
  user_preferences = user_topic_id.map do |el|
    db.execute("SELECT topic FROM preferences WHERE topic_id = ?",el["topic_id"]).first
  end
  return user_preferences
end

