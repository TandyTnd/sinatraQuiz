# The Ruby Quiz App
# Date: 03-June-2021
# Author: Leonardo Castillejos
#         Óscar Zúñiga
require 'json'
require 'faraday'
require 'sinatra'
require 'time'
require 'aws-sdk-dynamodb'


#BASE URL for the microservice that gets the questions from AWS
BASE = 'https://3r690kl9q2.execute-api.us-east-1.amazonaws.com/default/Question'
#BASE URL for the microservice that checks if the answer is correct
lambdaCheckAnswer = "https://t4upfkbyug.execute-api.us-east-1.amazonaws.com/default/checkAnswer"
#BASE URL for the microservice that allows to get the scores and write themfrom Dynamp
lambdaHighscore = "https://8reoi7vn9l.execute-api.us-east-1.amazonaws.com/default/HighScore"

#Allows for sessions to be used by server.rb
enable :sessions

#Home route, shows the index
get '/' do
  erb :index
end

#Route for the questions, retrieves the questions from aws
# Parameters::
#   id:: The id of the question that will be retrieved from aws
get '/quiz/:id' do
  @idPregunta =  params[:id]
  
  parameters = '?id=' + @idPregunta
  questionURL = BASE + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  session[:idPregunta] = @idPregunta

  
  @question = ''
  @answers = []
  @preguntaActual = session[:preguntaActual]
  @cantidadPreguntas = session[:cantidadPreguntas]
  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @answers = data['answers']
  end
  erb :quiz
end

#Route that shows the final results of a quiz attempt
get '/checkResults' do
    @usuario = session[:usuario]
    @cantidadPreguntas = session[:cantidadPreguntas]
    @score = session[:score]
    @horaInicio = session[:horaInicio]
    @horaFinal = Time.now.getutc
    
  erb :checkResults
end

#Route for supporting function to correctly create the URL using the session
post'/submitAnswer' do
  @answer = params[:option]
  @idPregunta = session[:idPregunta]
    redirect '/checkAnswer/' + @idPregunta.to_s + '/' + @answer.to_s
end

#Route that invokes the screen where the user receives feedback
# Parameters::
#   id:: The id of the question that will be checked from aws
#   answer:: The answer the user choose
get'/checkAnswer/:id/:answer' do
  parameters = '?id=' + params[:id] + "&answer=" + params[:answer] 
  questionURL = lambdaCheckAnswer + parameters
  connection = Faraday.new(url: questionURL)
  response = connection.get
  @question = ""
  @rightData = ""
  @correct = ""
  @preguntaActual = session[:preguntaActual]
  @cantidadPreguntas = session[:cantidadPreguntas]

  if response.success?
    data = JSON.parse(response.body)
    puts data
    @question = data['question']
    @rightData = data['right']
    @correct = data['correct']
  end
  
  if @rightData
    session[:score] = session[:score] + 1
  end
    erb :checkAnswer 
end

#Route for supporting function that has the logic to know when the user has answered all the questions
post '/siguientePregunta' do
    if !session[:listaPreguntas].empty? 
      @siguientePregunta = session[:listaPreguntas].pop
      session[:preguntaActual] = session[:preguntaActual] + 1
      redirect '/quiz/' + @siguientePregunta.to_s
    else
      redirect '/checkResults'
    end  

end

#Route that invokes a supporting function that does the apps setup
post'/iniciaQuiz' do
  cantidadPreguntas = params[:customRange1]
  cantidadPreguntas =Integer(cantidadPreguntas)
  usuario = params[:idUsuario]
  session[:usuario] = usuario
  session[:cantidadPreguntas] = cantidadPreguntas
  session[:preguntaActual] = 1
  session[:score] = 0
  b = (0..2).to_a
  session[:listaPreguntas] = b.sample(cantidadPreguntas)
  primerPregunta = session[:listaPreguntas].pop
  
  
  session[:horaInicio] = Time.now.getutc
  puts session[:horaInicio]
  redirect '/quiz/' + primerPregunta.to_s
end

#Route thatt invokes the highscore screen
get'/highscore' do
    connection = Faraday.new(url:lambdaHighscore)
    response = connection.get
    @highscores = []
    
    if response.success?
      @highscores = JSON.parse(response.body)
    end
    puts @highscores
    erb :highscore
end

#Route that invokes lambda to upload the user score 
post '/postHighscore' do
  dynamodb = Aws::DynamoDB::Client.new
  
  new_item = {
    Username: session[:usuario],
    timestamp: session[:horaInicio].to_i,
    EndTimestamp: Time.now.getutc.to_i,
    Right: session[:score],
    Total: session[:cantidadPreguntas]
  }
  
  dynamodb.put_item(table_name: 'HighScores', item: new_item)
  
  redirect '/highscore'
  
end