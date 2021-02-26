require_relative './model.rb'
require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions



get('/') do
    slim(:index)
end

get('/ad/new') do
    slim(:"ads/create")
end

post("/ad/new") do
    ad_name = params[:new_ad_name]
    description = params[:description]
    img_url = params[:img]
    price = params[:price]
    path = File.join("/img/uploaded_pictures/",params[:file][:filename])    
    File.write(path,File.read(params[:file][:tempfile]))
    add_ad(ad_name, description, img_url, price)
    redirect("/")
end


