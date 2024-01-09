function [response, streamedText] = sendRequest(parameters, token, endpoint, timeout, streamFun)
%sendRequest Sends a request to an ENDPOINT using PARAMETERS and
%   api key TOKEN. TIMEOUT is the nubmer of seconds to wait for initial
%   server connection. STREAMFUN is an optional callback function.

%   Copyright 2023 The MathWorks, Inc.

arguments
    parameters
    token
    endpoint
    timeout
    streamFun = []
end

% Define the headers for the API request

headers = [matlab.net.http.HeaderField('Content-Type', 'application/json')...
    matlab.net.http.HeaderField('Authorization', "Bearer " + token)];

% Define the request message
request = matlab.net.http.RequestMessage('post',headers,parameters);

% Create a HTTPOptions object;
httpOpts = matlab.net.http.HTTPOptions;

% Set the ConnectTimeout option
httpOpts.ConnectTimeout = timeout;

% Send the request and store the response
if isempty(streamFun)
    response = send(request, matlab.net.URI(endpoint),httpOpts);
    streamedText = "";
else
    % User defined a stream callback function
    consumer = llms.stream.responseStreamer(streamFun);
    response = send(request, matlab.net.URI(endpoint),httpOpts,consumer);
    streamedText = consumer.ResponseText;
end
end