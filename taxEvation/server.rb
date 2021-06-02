require 'json'
require 'faraday'
require 'sinatra'

URL = 'https://kss1ggcwh4.execute-api.us-west-2.amazonaws.com/default/books'
BASE = 'https://3r690kl9q2.execute-api.us-east-1.amazonaws.com/default/Question'

lambdaCheckAnswer = "https://t4upfkbyug.execute-api.us-east-1.amazonaws.com/default/checkAnswer"

POSIBLE = [0,1,2]

get '/' do
  erb :index
end


get '/ejemplo' do
  @mensaje = 'Esta es una prueba.'
  @info = ['primavera', 'verano', 'otoño', 'invierno']
  erb :ejemplo
end

get '/quiz/:id' do
  parameters = '?id=0'
  questionURL = BASE + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  @question = ''
  @answers = []
  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @answers = data['answers']
  end
  erb :quiz
end

post'/submitAnswer' do
  @answer = params[:option]
  redirect '/checkAnswer/0/'+ @answer
end

get'/checkAnswer/:id/:answer' do
  parameters = '?id=' + params[:id] + "&answer=" + params[:answer] 
  questionURL = lambdaCheckAnswer + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  @question = ""
  @rightData = ""
  @correct = ""
  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @rightData = data['right']
    @correct = data['correct']
  end
    erb :checkAnswer 
end

get '/resultado/:score' do
  @score = params[:score]
  @mensaje = 'Esta es una prueba.'
  @info = ['primavera', 'verano', 'otoño', 'invierno']
  erb :resultado
end



