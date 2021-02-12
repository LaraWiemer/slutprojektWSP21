



def add_ad(ad_name, description, img_url, price)
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    db.execute("INSERT INTO advertisements(name, description, img_url, price) VALUES (?, ?, ?, ?)", ad_name, description, img_url, price)
end

def login_user(username)
    
end