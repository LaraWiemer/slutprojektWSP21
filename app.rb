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

get('/ads/new') do
    slim(:"ads/create")
end

post("/ads/new") do
    ad_name = params[:ad_name]
    description = params[:description]
    price = params[:price]
    user_id = session[:user_id]
    original_filename = params[:file][:filename]
    file_ending = search_file_ending(original_filename)
    filename = SecureRandom.uuid + file_ending #gör så att den kollar ändelse; params[:file][:filename]
    save_path = File.join("./public/img/uploaded_pictures/", filename)
    db_path = File.join("/img/uploaded_pictures/", filename)
    #File.write(save_path,File.read(params[:file][:tempfile]))
    FileUtils.cp(params[:file][:tempfile], "./public/img/uploaded_pictures/#{filename}")
    add_ad(ad_name, description, db_path, price, user_id)
    redirect("/")
end

get("/register") do
    slim(:register_user)
end

post("/register") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    phone_number = params[:phone_number]
    if password = password_confirm
        register_user(username, password, phone_number)
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
