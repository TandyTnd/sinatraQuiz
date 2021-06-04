# The Ruby Quiz App
# Date: 03-June-2021
# Author: Leonardo Castillejos
#         Óscar Zúñiga

require 'json'
require 'aws-sdk-dynamodb'

#Constant that contains the dynamo client instance
DYNAMODB = Aws::DynamoDB::Client.new
#Constant that contains the name of the table that will be used
TABLE_NAME = 'HighScores'

#-------------------------------------------------------------------
# The +HttpStatus+ class represents the posible HTTP status codes
# to return in the response
class HttpStatus
  OK = 200
  CREATED = 201
  BAD_REQUEST = 400
  METHOD_NOT_ALLOWED = 405
end

#--------------------------------------------------------------------
# Generates a response for the lambda to return
# to its client
#
# Parameters::
#   code:: The HTTP code that indicate the client if the transaction was successful or not
#   body:: the response the user expects it may be a question or it may be an error
#          explaining what went wrong
# Returns:: An object with the statusCode and a JSON  or an error.
def make_response(code, body)
  {
    statusCode: code,
    headers: {
      "Content-Type" => "application/json; charset=utf-8"
    },
    body: JSON.generate(body)
  }
end

#--------------------------------------------------------------------
# Generates an object with all the entries in the Dynamo table 'HighScores' in a list
#
# Parameters::
#   items:: The entries in the table 'HighScores'
# Returns:: An object all the entries in 'HighScores' in list format with the attributes. User, Right, Total, Time

def make_result_list(items)
  items.map do |item| {
      'User' => item['Username'],
      'Right' => item['Right'].to_i,
      'Total' => item['Total'].to_i,
      'Time' => item['EndTimestamp'].to_i - item['timestamp'].to_i
    }
  end
end

#--------------------------------------------------------------------
# Sorts the items obtained from the table 'HighScores'
#
# Parameters::
#   items:: The entries in the table 'HighScores'
# Returns:: The entries of the table 'HighScores' sorted
def sort_items(items)
  items.sort! {|a, b| a['Right'] <=> b['Right']}
  items.sort! {|a, b| a['Total'] <=> b['Total']}
end

#--------------------------------------------------------------------
# Gets the scores stored in the table 'HighScores', sorts them and puts them in a format ready to become a JSON 
#
# Returns:: The entries of the table 'HighScores' sorted and formated
def get_scores
  items = DYNAMODB.scan(table_name: TABLE_NAME).items
  sort_items(items)
  make_result_list(items)
end

#--------------------------------------------------------------------
# Parses the body given by the client and checks if it has the keys 'Username' and 'timestamp' 
#
# Parameters::
#   body:: The body of the clients request, expected to contain Username' and 'timestamp', 
#          endTimeStamp, Right and Total
# Returns:: The data formatted so that it can be inserted into the table 'HighScore'
def parse_body(body)
  if body
    begin
      data = JSON.parse(body)
      data.key?('Username') and data.key?('timestamp') ? data : nil
    rescue JSON::ParserError
      nil
    end
  else
    nil
  end
end

#--------------------------------------------------------------------
# Inserts a wow in the Table 'HighScore'
#
# Parameters::
#   body:: The body of the clients request, expected to contain Username' and 'timestamp', 
#          endTimeStamp, Right and Total

def store_score_item(body)
  data = parse_body(body)
  if data
    DYNAMODB.put_item(table_name: TABLE_NAME, item: data)
    true
  else
    false
  end
end


#--------------------------------------------------------------------
# Handles get HTTP Methods
#
# Returns:: A response with a 200 code and all the rows in the table 'HighScores'


def handle_get
  make_response(HttpStatus::OK, get_scores)
end

#--------------------------------------------------------------------
# Handles Post HTTP Methods
#
# Returns:: A response with a 201 code and a message notifying that a row was succesfully inserted
# into'HighScores'
def handle_post
  make_response(HttpStatus::CREATED,
    {message: 'Resource created or updated'})
end

#--------------------------------------------------------------------
# Handles unsuccesful requests to insert
#
# Returns:: A response with a 400 code and a message notifying that their request
# was wrong and could not be inserted into'HighScores'
def handle_bad_request
  make_response(HttpStatus::BAD_REQUEST,
    {message: 'Bad request (invalid input)'})
end

#--------------------------------------------------------------------
# Handles unsuccesful requests to insert
#
# Returns:: A response with a 400 code and a message notifying that their request
# was wrong and could not be inserted into'HighScores'
def handle_bad_method(method)
  make_response(HttpStatus::METHOD_NOT_ALLOWED,
    {message: "Method not supported: #{method}"})
end

#--------------------------------------------------------------------
# Handles the client's request based on what HTTP request it send
# and the parameters they sent
#
# Parameters::
#   event:: Contains the HTTP method that the user sent and
#           constains the parameters the user sent
# Returns:: An object with the statusCode and a JSON, a notification or an error.
def lambda_handler(event:, context:)
  method = event.dig('requestContext', 'http', 'method')
  case method
  when 'GET'
    handle_get

  when 'POST'
    if store_score_item(event['body'])
      handle_post
    else
      handle_bad_request
    end

  else
    handle_bad_method(method)
  end
end

