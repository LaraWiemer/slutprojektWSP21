require_relative './model.rb'
require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'byebug'
enable :sessions
require 'fileutils'
require 'securerandom'



get('/') do
    #user_id = session[:user_id].to_i
    db = SQLite3::Database.new('db/handel.db')
    db.results_as_hash = true
    result = db.execute("SELECT * FROM advertisements")
    slim(:index, locals:{advertisements:result})
end




#Ads

get('/ads/new') do
    if login_check() == false
        redirect("/")
    end
    categories = get_categories()
    slim(:"/ads/create", locals:{categories:categories})
end

post("/ads/new") do
    ad_name = params[:ad_name]
    description = params[:description]
    category_id = params[:category]
    price = params[:price]
    user_id = session[:user_id].to_i
    original_filename = params[:file][:filename]
    file_ending = search_file_ending(original_filename)
    filename = SecureRandom.uuid + file_ending
    save_path = File.join("./public/img/uploaded_pictures/", filename)
    db_path = File.join("/img/uploaded_pictures/", filename)
    FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
    add_ad(ad_name, description, db_path, price, category_id, user_id)
    redirect("/")
end

get("/ads/edit") do
    if login_check() == false
        redirect("/")
    end
    ad_id = params[:ad_id].to_i
    user_id = session[:user_id].to_i
    ad_content = ad_content(ad_id)
    category_id = ad_to_category(ad_id)
    categories = get_categories()
    slim(:"/ads/edit", locals:{advertisements:ad_content, categories:categories, category_id:category_id})
end

post("/ads/:id/update") do
    id = params[:ad_id].to_i
    ad_name = params[:ad_name]
    description = params[:description]
    category_id = params[:category]
    price = params[:price]
    user_id = session[:user_id].to_i
    update_ad(ad_name, description, price, category_id, id)
    redirect("/users/profile")
end


post("/ads/:id/update_picture") do
    id = params[:ad_id].to_i
    original_filename = params[:file][:filename]
    file_ending = search_file_ending(original_filename)
    filename = SecureRandom.uuid + file_ending
    save_path = File.join("./public/img/uploaded_pictures/", filename)
    db_path = File.join("/img/uploaded_pictures/", filename)
    FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
    update_ad_picture(db_path, id)
    redirect('/users/profile')
end

post('/ads/:id/delete') do
    id = params[:ad_id].to_i
    user_id = session[:user_id]
    delete_ad(id)
    redirect('/users/profile')
end





get("/users/new") do
    slim(:"/users/create")
end

post("/users/new") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    phone_number = params[:phone_number]
    if password = password_confirm
        user_id = register_user(username, password, phone_number)
        redirect("/")
    else
        redirect("/register_error")
    end
end

get("/login") do
    slim(:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    login_result = login(username, password)
    if login_result == true
        redirect('/')
    else
        redirect('/login_error')
    end
end

get("/login_error") do
    slim(:login_error)
end

get("/register_error") do
    slim(:register_error)
end

get("/users/logout") do
    session[:user_id] = nil
    session[:group_id] = nil
    redirect("/")
end

get("/users/profile") do
    if login_check() == false
        redirect("/")
    end
    user_id = session[:user_id].to_i
    ads_by_user = ads_by_user(user_id)
    slim(:"/users/profile", locals:{advertisements:ads_by_user})
end

get("/users/edit") do
    if session[:group_id] != 2
        redirect("/")
    end
    users = get_user_content()
    user_to_group = get_user_to_group()
    categories = get_categories()
    byebug
    slim(:"/admin/users_edit", locals:{users:users, user_to_group:user_to_group, categories:categories})
end

