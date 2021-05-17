require_relative './model.rb'
require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'byebug'
enable :sessions
require 'fileutils'
require 'securerandom'

include Model

before all_of("/ads/new", "/ads/edit", "/ads/:id/update", "/ads/:id/delete", "/ads/:id/update", "/ads/:id/update_picture", "/users/profile") do
    ad_id = params[:ad_id]
    if session[:user_id] == nil
        redirect("/error")
    end
    if ad_id != nil
        result = check_user_id_ad(ad_id)
        if session[:user_id] == result["ad_id"]
            redirect("/error")
        end
    end
end

before all_of("/login", "/register") do
    if session[:sleep] == true
        redirect("/")
    end
end


#Visa startsidan
#@see Model#get_ads

get('/') do 
    advertisements = get_ads()
    slim(:index, locals:{advertisements:advertisements})
end


#Shows the form that allows the user to create an ad
#@see Model#get_categories

get('/ads/new') do
    categories = get_categories()
    slim(:"/ads/create", locals:{categories:categories})
end


#Creates a new ad and redirects to /
#@param [string] :ad_name, the name of the advertisement
#@param [string] :description, the description of the advertisement
#@param [string] :category, the category of the advertisement
#@param [string] :price, the price of the advertisement
#@param [string] :file, the image file of the advertisement
#@param [string] :filename, the image files name of the advertisement
#@see Model#add_ad

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


#Views the form that can be used to edit an ad
#@param [string] :ad_id, the id of the ad being edited
#@see Model#ad_content
#@see Model#ad_to_category
#@see Model#get_categories

get("/ads/edit") do
    ad_id = params[:ad_id].to_i
    user_id = session[:user_id].to_i
    ad_content = ad_content(ad_id)
    category_id = ad_to_category(ad_id)
    categories = get_categories()
    slim(:"/ads/edit", locals:{advertisements:ad_content, categories:categories, category_id:category_id})
end


#Updates the chosen ad and redirects to /users/profile
#@param [string] :id, the id of the ad being updated
#@param [string] :ad_name, the new name of the ad being updated
#@param [string] :description, the new description of the ad being updated
#@param [string] :category_id, the id of the new category of the ad being updated
#@param [string] :price, the new price of the ad being updated
#@see Model#update_ad

post("/ads/:id/update") do
    id = params[:id].to_i
    ad_name = params[:ad_name]
    description = params[:description]
    category_id = params[:category]
    price = params[:price]
    user_id = session[:user_id].to_i
    update_ad(ad_name, description, price, category_id, id)
    redirect("/users/profile")
end


#Updates the image of the selected ad and redirects to /users/profile
#@param [string] :ad_id, the id of the ad being updated
#@param [string] :file, the new image file of the ad being updated
#@param [string] :filename, the new name of the image of the ad being updated
#@see Model#search_file_ending
#@see Model#update_ad_picture

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


#Deletes the selected ad and redirects to /users/profile
#@param [string] :id, the id of the ad being deleted
#@see Model#delete_ad

post('/ads/:id/delete') do
    id = params[:ad_id].to_i
    user_id = session[:user_id]
    delete_ad(id)
    redirect('/users/profile')
end


#Shows the form that creates a new user

get("/users/new") do
    slim(:"/users/create")
end


#Creates a new user and redirects to / if successful, if the password and the confirmed password do not match the route redirects to /register_error
#@param [string] :username, the username of the user being created
#@param [string] :password, the password of the user being created
#@param [string] :password_confirm, the confirmation of the password of the user being created
#@param [string] :phone_number, the phone number of the user being created
#@see Model#register_user

post("/users/new") do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    phone_number = params[:phone_number]
    if password = password_confirm
        array = register_user(username, password, phone_number)
        session[:user_id] = array[0]
        session[:group_id] = array[1]
        redirect("/")
    else
        redirect("/register_error")
    end
end


#Logs out the user

get("/users/logout") do
    session[:user_id] = nil
    session[:group_id] = nil
    redirect("/")
end


#Shows a list of all the users and allows to delete the users, can only be accessed by admins
#@see Model#get_user_content
#@see Model#get_user_to_group

get("/admin/edit") do
    if session[:group_id] != 2
        redirect("/")
    end
    users = get_user_content()
    user_to_group = get_user_to_group()
    slim(:"/admin/users_edit", locals:{users:users, user_to_group:user_to_group})
end


#Shows a users profile
#@param [string] :user_id, the id of the user whose profile is being shown
#@see Model#ads_by_user

get("/users/profile") do
    user_id = session[:user_id].to_i
    ads_by_user = ads_by_user(user_id)
    slim(:"/users/profile", locals:{advertisements:ads_by_user})
end


#Shows the form that allows a user to log in

get("/login") do
    slim(:login)
end


#Logs a user in, keeps track of the amount of login tries a computer has, if they have more than 3 login_tries they get a cool-down effect, the tracker is reset after the user has been slept for 30 seconds or after a successful login attempt. If the user is successfully logged in the route redirects to /, if the login attempt is unsuccessful but the user does not have more than 3 tries the route redirects to /login, if the login attempt is unsuccessful and the user has more than 3 tries the route will sleep the user for 30 seconds and then redirect to /too_many_login_tries
#@param [string] :username, the username of the user being logged in
#@param [string] :password, the password of the user being logged in
#@see Model#login

post('/login') do
    if session[:login_tries] == nil
        session[:login_tries] = 1
    end
    username = params[:username]
    password = params[:password]
    login_result = login(username, password)
    session[:user_id] = login_result[0]
    session[:group_id] = login_result[1]
    if login_result != nil
        session[:login_tries] = nil
        redirect('/')
    else
        session[:login_tries] += 1
        redirect('/error-- /login_error')
    end
    if session[:login_tries] > 3
        redirect("/error/too_many_login_tries")
    end
end


#

get("/error/too_many_login_tries") do
    session[:sleep] = true
    sleep(30)
    session[:sleep] = false
    redirect("/login")
end

get('/error') do
  slim(:"/error/error")  
end

get("/error/login_error") do
    slim(:"/error/login")
end

get("/register_error") do
    slim(:"/error/register")
end



