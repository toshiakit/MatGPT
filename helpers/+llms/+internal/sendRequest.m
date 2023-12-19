function response = sendRequest(parameters, token, endpoint, timeout)
% This function is undocumented and will change in a future release

%sendRequest Sends a request to an ENDPOINT using PARAMETERS and
%   api key TOKEN. TIMEOUT is the nubmer of seconds to wait for initial
%   server connection.

%   Copyright 2023 The MathWorks, Inc.

arguments
    parameters
    token
    endpoint
    timeout
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
response = send(request, matlab.net.URI(endpoint),httpOpts);
end