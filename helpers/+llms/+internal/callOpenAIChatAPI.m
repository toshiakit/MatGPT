function [text, message, response] = callOpenAIChatAPI(messages, functions, nvp)
% This function is undocumented and will change in a future release

%callOpenAIChatAPI Calls the openAI chat completions API.
%
%   MESSAGES and FUNCTIONS should be structs matching the json format
%   required by the OpenAI Chat Completions API.
%   Ref: https://platform.openai.com/docs/guides/gpt/chat-completions-api
%
%   Currently, the supported NVP are, including the equivalent name in the API:
%    - FunctionCall (function_call)
%    - ModelName (model)
%    - Temperature (temperature)
%    - TopProbabilityMass (top_p)
%    - NumCompletions (n)
%    - StopSequences (stop)
%    - MaxNumTokens (max_tokens)
%    - PresencePenalty (presence_penalty)
%    - FrequencyPenalty (frequence_penalty)
%    - ApiKey
%    - TimeOut
%    - StreamFun
%   More details on the parameters: https://platform.openai.com/docs/api-reference/chat/create
%
%   Example
%   
%   % Create messages struct
%   messages = {struct("role", "system",...
%       "content", "You are a helpful assistant");
%       struct("role", "user", ...
%       "content", "What is the edit distance between hi and hello?")};
%
%   % Create functions struct
%   functions = {struct("name", "editDistance", ...
%       "description", "Find edit distance between two strings or documents.", ...
%       "parameters", struct( ...
%       "type", "object", ...
%       "properties", struct(...
%           "str1", struct(...
%               "description", "Source string.", ...
%               "type", "string"),...
%           "str2", struct(...
%               "description", "Target string.", ...
%               "type", "string")),...
%       "required", ["str1", "str2"]))};
%
%   % Define your API key
%   apiKey = "your-api-key-here"
%
%   % Send a request
%   [text, message] = llms.internal.callOpenAIChatAPI(messages, functions, ApiKey=apiKey)

%   Copyright 2023 The MathWorks, Inc.

arguments
    messages
    functions
    nvp.FunctionCall = []
    nvp.ModelName = "gpt-3.5-turbo"
    nvp.Temperature = 1
    nvp.TopProbabilityMass = 1
    nvp.NumCompletions = 1
    nvp.StopSequences = []
    nvp.MaxNumTokens = inf
    nvp.PresencePenalty = 0
    nvp.FrequencyPenalty = 0
    nvp.ApiKey = ""
    nvp.TimeOut = 10
    nvp.StreamFun = []
end

END_POINT = "https://api.openai.com/v1/chat/completions";

parameters = buildParametersCall(messages, functions, nvp);

[response, streamedText] = llms.internal.sendRequest(parameters,nvp.ApiKey, END_POINT, nvp.TimeOut, nvp.StreamFun);

% If call errors, "choices" will not be part of response.Body.Data, instead
% we get response.Body.Data.error
if response.StatusCode=="OK"
    % Outputs the first generation
    if isempty(nvp.StreamFun)
        message = response.Body.Data.choices(1).message;
    else
        message = struct("role", "assistant", ...
            "content", streamedText);
    end
    if isfield(message, "function_call")
        text = "";
    else
        text = string(message.content);
    end
else
    text = "";
    message = struct();
end
end

function parameters = buildParametersCall(messages, functions, nvp)
% Builds a struct in the format that is expected by the API, combining
% MESSAGES, FUNCTIONS and parameters in NVP.

parameters = struct();
parameters.messages = messages;

parameters.stream = ~isempty(nvp.StreamFun);

if ~isempty(functions)
    parameters.functions = functions;
end

if ~isempty(nvp.FunctionCall)
    parameters.function_call = nvp.FunctionCall;
end

parameters.model = nvp.ModelName;

dict = mapNVPToParameters;

nvpOptions = keys(dict);
for i=1:length(nvpOptions)
    if isfield(nvp, nvpOptions(i))
        parameters.(dict(nvpOptions(i))) = nvp.(nvpOptions(i));
    end
end
end

function dict = mapNVPToParameters()
dict = dictionary();
dict("Temperature") = "temperature";
dict("TopProbabilityMass") = "top_p";
dict("NumCompletions") = "n";
dict("StopSequences") = "stop";
dict("MaxNumTokens") = "max_tokens";
dict("PresencePenalty") = "presence_penalty";
dict("FrequencyPenalty ") = "frequency_penalty";
end