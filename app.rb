require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions




get('/ad/new') do
    slim(:"ads/create")
end

post("/ad/new") do

end


