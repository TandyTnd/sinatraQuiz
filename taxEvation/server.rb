require 'json'
require 'faraday'
require 'sinatra'
require 'time'

URL = 'https://kss1ggcwh4.execute-api.us-west-2.amazonaws.com/default/books'
BASE = 'https://3r690kl9q2.execute-api.us-east-1.amazonaws.com/default/Question'

lambdaCheckAnswer = "https://t4upfkbyug.execute-api.us-east-1.amazonaws.com/default/checkAnswer"
lambdaHighscore = "https://8reoi7vn9l.execute-api.us-east-1.amazonaws.com/default/HighScore"


enable :sessions

get '/' do
  erb :index
end


get '/ejemplo' do
  @mensaje = 'Esta es una prueba.'
  @info = ['primavera', 'verano', 'otoño', 'invierno']
  erb :ejemplo
end

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

get '/checkResults' do
    @usuario = session[:usuario]
    @cantidadPreguntas = session[:cantidadPreguntas]
    @score = session[:score]
    @horaInicio = session[:horaInicio]
    @horaFinal = Time.now.getutc
  erb :checkResults
end


post'/submitAnswer' do
  puts "sumbit answer aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  @answer = params[:option]
  @idPregunta = session[:idPregunta]
    redirect '/checkAnswer/' + @idPregunta.to_s + '/' + @answer.to_s
end

get'/checkAnswer/:id/:answer' do
  puts "checkAnswer aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
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
  
  if @correct
    session[:score] = session[:score] + 1
  end
    erb :checkAnswer 
end

post '/siguientePregunta' do

    if !session[:listaPreguntas].empty? 
      @siguientePregunta = session[:listaPreguntas].pop
      session[:preguntaActual] = session[:preguntaActual] + 1
      redirect '/quiz/' + @siguientePregunta.to_s
    else
      redirect '/checkResults'
    end  

end

get '/resultado/:score' do
  @score = params[:score]
  @mensaje = 'Esta es una prueba.'
  @info = ['primavera', 'verano', 'otoño', 'invierno']
  erb :resultado
end



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

post '/postHighscore' do
  
end