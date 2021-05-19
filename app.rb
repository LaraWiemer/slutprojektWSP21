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


#Checks if the user is logged in, when there is an ad_id it checks if the ad belongs to the user. If the ad does not belong to the user they get redirected to /error, otherwise they go on to the wanted route
#@param [String] :ad_id, the id of the ad in question
#@see Model#check_user_id

before all_of("/ads", "/ads/new", "/ads/:id/edit", "/ads/:id/update", "/ads/:id/delete", "/ads/:id/update", "/ads/:id/update_picture", "/users/:id") do
    ad_id = params[:ad_id]
    if session[:user_id] == nil
        redirect("/error")
    end
    if ad_id != nil
        result = check_user_id_ad(ad_id)
        if session[:user_id] != result["ad_id"]
            redirect("/error")
        end
    end
end


#Checks if the user is an admin before they can access certain routes, if they are not they are redirected to /error

before all_of("/admin/", "/admin/:id/edit", "/admin") do
    if session[:group_id] != 2
        redirect("/error")
    end
end

#Displays the home-page
#@see Model#get_ads

get('/') do 
    advertisements = get_ads()
    slim(:index, locals:{advertisements:advertisements})
end


#Displays the form that allows the user to create an ad
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
#@see Model#search_file_ending
#@see Model#add_ad

post("/ads") do 
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


#Displays the form that can be used to edit an ad
#@param [Integer] :ad_id, the id of the ad being edited
#@see Model#ad_content
#@see Model#ad_to_category
#@see Model#get_categories

get("/ads/:id/edit") do
    ad_id = params[:ad_id].to_i
    user_id = session[:user_id].to_i
    ad_content = ad_content(ad_id)
    category_id = ad_to_category(ad_id)
    categories = get_categories()
    slim(:"/ads/edit", locals:{advertisements:ad_content, categories:categories, category_id:category_id})
end


#Updates the chosen ad and redirects to /users/:id
#@param [Integer] :id, the id of the ad being updated
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
    redirect("/users/:id")
end


#Updates the image of the selected ad and redirects to /users/:id
#@param [Integer] :ad_id, the id of the ad being updated
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
    redirect('/users/:id')
end


#Deletes the selected ad and redirects to /users/:id
#@param [Integer] :id, the id of the ad being deleted
#@see Model#delete_ad

post('/ads/:id/delete') do
    id = params[:ad_id].to_i
    user_id = session[:user_id]
    delete_ad(id)
    redirect('/users/:id')
end


#Displays the form that creates a new user

get("/users/new") do
    slim(:"/users/create")
end


#Creates a new user and redirects to / if successful, if the password and the confirmed password do not match the route redirects to /error/register. If the creation of the user was successful the user is also logged in.
#@param [string] :username, the username of the user being created
#@param [string] :password, the password of the user being created
#@param [string] :password_confirm, the confirmation of the password of the user being created
#@param [string] :phone_number, the phone number of the user being created
#@see Model#register_user

post("/users") do
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
        redirect("/error/register")
    end
end


#Logs out the user

get("/users/logout") do
    session[:user_id] = nil
    session[:group_id] = nil
    redirect("/")
end


#Deletes a user, can only be accessed if you are the user being deleted or if you are an admin
#@param [Integer] :user_id, the id of the user being deleted
#@see Model#delete_user

post("/users/:id/delete") do
    user_id = params[:user_id].to_i
    if session[:user_id] == user_id || session[:group_id] == 2
        delete_user(user_id)
    end
    if session[:group_id] == 2
        redirect("/admin/")
    else
        redirect("/")
    end
end


#Shows a list of all the users and allows to delete the users, can only be accessed by admins
#@see Model#get_user_content
#@see Model#get_user_to_group

get("/admin/") do
    users = get_all_user_content()
    user_to_group = get_user_to_group()
    slim(:"/admin/index", locals:{users:users, user_to_group:user_to_group})
end


#Displays the form that lets admins edit a users access clearance
#@param [Integer] :user_id, the users id

get("/admin/:id/edit") do
    id = params[:user_id].to_i
    user_content = get_user_content(id)
    user_group = get_one_user_to_group(id)
    group_content = get_groups()
    slim(:"/admin/edit", locals:{users:user_content, user_group:user_group, groups:group_content})
end


#Updates a users access clearance
#@param [String] :user_id, the id of the user being updated
#@param [String] :group, the id of the new group
#@see Model#admin_update_useraccess

post("/admin/:id/update") do
    user_id = params[:user_id]
    group_id = params[:group]
    admin_update_useraccess(user_id, group_id)
    redirect("/admin/")
end


#Shows a users profile
#@param [string] :user_id, the id of the user whose profile is being shown
#@see Model#ads_by_user

get("/users/:id") do
    id = session[:user_id].to_i
    ads_by_user = ads_by_user(id)
    slim(:"/users/index", locals:{advertisements:ads_by_user})
end


#Displays the form that allows a user to log in

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
        redirect('/error/login')
    end
    if session[:login_tries] > 3
        redirect("/error/too_many_login_tries")
    end
end


#Displays the error page that is shown when a user tries to access a page that they do not have access to

get('/error') do
  slim(:"/error/not_logged_in")  
end


#Displays the error page for when a login attempt has failed

get("/error/login") do
    slim(:"/error/login")
end


#Displays the error page for when a user has failed in attempting to register as a user

get("/error/register") do
    slim(:"/error/register")
end


