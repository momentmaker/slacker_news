require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'csv'
require 'net/http'
require 'redis'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end


def get_articles()
  articles = []

  CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |row|
    articles << row.to_hash
  end
  articles
end

def write_article(article)
  column_header = ["name", "url", "desc"]

  CSV.open('articles.csv', 'a+') do |csv|
    csv << article
    #binding.pry
  end
end

def check_valid(article)

  articles = get_articles
  #binding.pry
  if article[:title] == "" && article[:url] == "" && article[:desc] == ""
    return 'all'
  elsif article[:title] == ""
    return 'title'
  elsif article[:url] == ""
    return 'url'
  elsif article[:url] !~ /^(www)\.\w+\..{2,6}$/
    return 'url'
  end


  # url = article[:url]

  # if url[-1,1] != '/' &&  url[-5,4] != 'html'
  #   url << '/'
  #   #binding.pry
  #   article[:url] = url
  # end

  # if url[0..9] != 'http://'
  #   url.insert(0, "http://")
  #   return 'url'
  # end

  # url = URI.parse(article[:url])
  # req = Net::HTTP.new(url.host, url.port)
  # res = req.request_head(url.path)

  # if res.code != "200"
  #   return 'url'

  # end

  articles.each do |row|
    return 'same' if row[:url] == article[:url]
  end


  if article[:desc].length < 20
    return 'desc'
  end

  return nil
end


get '/' do
  @articles = get_articles
  #binding.pry
  erb :index
end

get '/submit' do
  erb :submit_article
end

post '/submit' do
  article = {
    title: params[:title],
    url: params[:url],
    desc: params[:desc]
  }

  item = [params[:title], params[:url], params[:desc]]

  if check_valid(article) == nil
    write_article(item)
    redirect '/'
  else
    if check_valid(article) == 'all'
      @error = "Invalid inputs. Please enter all the data."
    elsif check_valid(article) == 'title'
      @error = "Error... Please enter the title."
    elsif check_valid(article) == 'same'
      @error = "This article has already been submitted."
    elsif check_valid(article) == 'url'
      @error = "Error... Please enter the proper URL format."
    elsif check_valid(article) == 'desc'
      @error = "Error... Please enter longer description."
    end
    erb :submit_article
  end
end
