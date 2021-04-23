



def add_ad(ad_name, description, db_path, price, user_id)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("INSERT INTO advertisements(name, description, img_path, price) VALUES (?, ?, ?, ?)", ad_name, description, db_path, price)
    current_ad = db.execute("SELECT * FROM advertisements WHERE name = ? AND description = ? ", ad_name, description).first
    ad_id = current_ad["ad_id"]
    db.execute("INSERT INTO user_to_ad(user_id, ad_id) VALUES (?,?)", user_id, ad_id)
end

def register_user(username, password, phone_number)
    pwdigest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/handel.db')
    db.execute("INSERT INTO users(username, pwdigest, phone_number) VALUES (?, ?, ? , ?)", username, pwdigest, phone_number)
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
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
        session[:user_id] = id
        return true
      else
        return false
      end

end

