# The Ruby Quiz App
# Date: 03-June-2021
# Author: Leonardo Castillejos
#         Óscar Zúñiga

require 'json'
require 'yaml'

#Constant where the YAML file is loaded
ANSWERS = YAML.load_file('answers.yaml')


# Creates an url in string format
#
# Parameters::
#   host:: The host of the service
#   path:: The path in the host
#   index:: The index of the question
def make_url(host, path, index)
    "https://#{host}#{path}?id=#{index}&answer=#{answer}"
end

# Generates a response for the lambda to return
# to its client
#
# Parameters::
#   id:: The id of the question that is being checked
#   answer:: the response the user gave that will be reviewed to check if it is correct
# Returns:: An object with the statusCode and a JSON that contains id, right, correct, question
def check_resource_by_id(id, answer)
    if ANSWERS[id]['answer'] == answer.to_i
        make_response(200, {id: id, right: true, correct: ANSWERS[id]['completeAnswer'], question: ANSWERS[id]['question']})
    else
        make_response(200, {id: id, right: false, correct: ANSWERS[id]['completeAnswer'], question: ANSWERS[id]['question']})
    end
end

# Generates a response for the lambda to return
# to its client
#
# Parameters::
#   code:: The HTTP code that indicate the client if the transaction was successful or not
#   body:: the response the user expects it may be a question or it may be an error
#          explaining what went wrong
# Returns:: An object with the statusCode and a JSON that contains what is returned in +check_resource_by_id(id, answer)+ or an error.
def make_response(code, body)
  {
    statusCode: code,
    headers: {
      "Content-Type" => "application/json; charset=utf-8"
    },
    body: JSON.generate(body)
  }
end

# Handles the client's request based on what HTTP request it send
# and the parameters they sent
#
# Parameters::
#   event:: Contains the HTTP method that the user sent and
#           constains the parameters the user sent
# Returns:: An object with the statusCode and a JSON that contains what is returned in +check_resource_by_id(id, answer)+ or an error.
def lambda_handler(event:, context:)
    method = event.dig('requestContext', 'http', 'method')
    case method
    when 'GET'
        query_string = event['queryStringParameters'] || {}
        if query_string['id']
            id = query_string['id'].to_i
            if 0 <= id and id < ANSWERS.size
                answer = query_string['answer']
                if answer.length > 0
                    check_resource_by_id(id, answer)
                else
                    make_response(404, {error: "answer is empty not found"})
                end
            else
                make_response(404, {error: "ID #{id} not found"})
            end
        else
            make_response(405, {error: "Method not allowed: #{method}"})
        end
    end
end
