classdef openAIAudio
    %openAIAudio Collection of static methods to connect to Audio API from OpenAI.
    %
    %   openAIAudio Functions:
    %       speech          - Text to Speech API from OpenAI that generates
    %                         audio from text. 
    %       transcriptions  - Speech to Text API from OpenAI that generates
    %                         text transcription from an audio file.
    %       translations    - Speech to Text API from OpenAI that generates
    %                         English translation from a foreign language audio file. 

    methods (Access=public,Static)

        function [y,Fs,response] = speech(text,nvp)
            % SPEECH  Generate speech using the OpenAI API
            %
            %   [y,Fs,response] = OPENAIAUDIO.SPEECH(text) generates audio
            %   from the input TEXT using the OpenAI API, and returns 
            %   sampled data, y, and a sample rate for that data, Fs.
            %   use `audiowrite(filename,y,Fs)` to save the audio to a file.
            %
            %   [y,Fs,response] = OPENAIAUDIO.SPEECH(__, Name=Value) specifies additional options
            %   using one or more name-value arguments:
            %
            %       ModelName            - Name of the model to use for speech generation. 
            %                              "tts-1" (default) or "tts-1-hd"
            %       Voice                - The voice to use in generated audio. Options are:
            %                              "alloy" (default), "echo", "fable", "onyx",
            %                              "nova", and "shimmer". The preview is available here 
            %                              https://platform.openai.com/docs/guides/text-to-speech/voice-options
            %       Speed                - The speed of the generated, from 0.25 to 4. Default is 1. 
            %       TimeOut              - Connection Timeout in seconds (default: 10 secs)
            %
            
            arguments
                text               (1,1) {mustBeTextScalar}
                nvp.ModelName      (1,1) {mustBeMember(nvp.ModelName,["tts-1","tts-1-hd"])} = "tts-1"
                nvp.Voice          (1,1) {mustBeMember(nvp.Voice,["alloy","echo","fable","onyx","nova","shimmer"])} = "alloy"
                nvp.Speed          (1,2) {mustBeNumeric,mustBeInRange(nvp.Speed,0.25,4)} = 1
                nvp.TimeOut        (1,1) {mustBeReal,mustBePositive} = 10
                nvp.ApiKey               {mustBeNonzeroLengthTextScalar} 
            end

            endpoint = "https://api.openai.com/v1/audio/speech";
            apikey = getenv("OPENAI_API_KEY");
            timeout = nvp.TimeOut;
            params = struct("model",nvp.ModelName,"input",text,"voice",nvp.Voice);
            if nvp.Speed ~= 1
                params.speed = nvp.Speed;
            end
            
            % Send the HTTP Request
            response = sendRequest(apikey, endpoint, params, timeout);
            if isfield(response.Body.Data,"error")
                y = [];
                Fs = [];
            else
                y = response.Body.Data{1};
                Fs = response.Body.Data{2};
            end            

        end

        function [output,response] = transcriptions(filepath,nvp)
            % TRANSCRIPTIONS  Transcribe audio using the OpenAI API
            %
            %   [output, response] = OPENAIAUDIO.TRANSCRIPTIONS(filepath) generates
            %   text transcription from the input audio file FILEPATH using the
            %   OpenAI API.
            %
            %   [output, response] = OPENAIAUDIO.TRANSCRIPTIONS(__, Name=Value) 
            %   specifies additional options using one or more name-value arguments:
            %
            %       ModelName               - Name of the model to use for transcription. 
            %                                 Only "whisper-1" is currently available.
            %       Language                - The language of the input audio. This 
            %                                 improves the accuracy and latency. Use 
            %                                 the ISO-639-1 format to specify the language
            %                                 https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
            %       Prompt                  - An optional text to guide the model's style 
            %                                 or continue a previous audio segment.
            %       ResponseFormat          - The format of the transcript output: 
            %                                 "json" (default), "text", "srt", "vtt", 
            %                                 or "verbose_json" 
            %       Temperature             - The sampling temperature between 0 and 1. 
            %                                 Higher values like 0.8 will make the output 
            %                                 more random. Default is 0.
            %       TimestampGranularities  - The timestamp granularity used when 
            %                                 ResponseFormat is set to "verbose_json": 
            %                                 "segment" (default), and/or "word". Choosing 
            %                                 "word" will add latency.  
            %       TimeOut                 - Connection Timeout in seconds (default: 10 secs)
            %

            arguments
                filepath                          {mustBeValidFileType(filepath)}
                nvp.ModelName                     {mustBeMember(nvp.ModelName,"whisper-1")}= "whisper-1"
                nvp.Language                      {mustBeValidLanCode(nvp.Language)}
                nvp.Prompt                        {mustBeTextScalar}
                nvp.ResponseFormat                {mustBeMember(nvp.ResponseFormat, ...
                                                    ["json","text","srt","vtt","verbose_json"])} = "json"
                nvp.Temperature             (1,1) {mustBeInRange(nvp.Temperature,0,1)} = 0
                nvp.TimestampGranularities  (1,:) {mustBeText,mustBeMember(nvp.TimestampGranularities, ...
                                                    ["segment","word"])}
                nvp.TimeOut                 (1,1) {mustBeReal,mustBePositive} = 10
                nvp.ApiKey                        {mustBeNonzeroLengthTextScalar} 
            end
    
            endpoint = "https://api.openai.com/v1/audio/transcriptions";
            apikey = getenv("OPENAI_API_KEY");
            timeout = nvp.TimeOut;

            import matlab.net.http.io.*
            params = struct('model', nvp.ModelName, 'file', FileProvider(filepath));
            if isfield(nvp,"Language")
                params.language = nvp.Language;
            end
            if isfield(nvp,"Prompt")
                params.prompt = nvp.Prompt;
            end
            if nvp.ResponseFormat ~= "json"
                params.response_format = nvp.ResponseFormat;
            end
            if nvp.Temperature > 0
                params.temperature = nvp.Temperature;
            end
            if isfield(nvp,"TimestampGranularities")
                if nvp.ResponseFormat == "verbose_json"
                    if isscalar(nvp.TimestampGranularities) && nvp.TimestampGranularities ~= "segment"
                        params.timestamp_granularities = {nvp.TimestampGranularities};
                    else
                        params.timestamp_granularities = nvp.TimestampGranularities;
                    end
                else
                    warning("set ResponseFormat to 'verbose_json' to enable TimestampGranularities.")
                end
            end
            keyval = [fieldnames(params) struct2cell(params)].';
            body = MultipartFormProvider(keyval{:});

            % Send the HTTP Request
            response = sendRequest(apikey, endpoint, body, timeout);
            if isfield(response.Body.Data,"error")
                output = "";
            else
                output = response.Body.Data;
            end   
        end

        function [output,response] = translations(filepath,nvp)
            % TRANSLATIONS  Translate audio into English text using the OpenAI API
            %
            %   [output, response] = OPENAIAUDIO.TRANSLATIONS(filepath) generates
            %   English translation from the input audio file FILEPATH using the
            %   OpenAI API.
            %
            %   [output, response] = OPENAIAUDIO.TRANSLATIONS(__, Name=Value) 
            %   specifies additional options using one or more name-value arguments:
            %
            %       ModelName               - Name of the model to use for transcription. 
            %                                 Only "whisper-1" is currently available.
            %       Prompt                  - An optional text to guide the model's style 
            %                                 or continue a previous audio segment.The 
            %                                 prompt must be in English.
            %       ResponseFormat          - The format of the transcript output: 
            %                                 "json" (default), "text", "srt", "vtt", 
            %                                 or "verbose_json"
            %       Temperature             - The sampling temperature between 0 and 1. 
            %                                 Higher values like 0.8 will make the output 
            %                                 more random. Default is 0.
            % 

            arguments
                filepath                          {mustBeValidFileType(filepath)}
                nvp.ModelName                     {mustBeMember(nvp.ModelName,"whisper-1")}= "whisper-1"
                nvp.Prompt                        {mustBeTextScalar}
                nvp.ResponseFormat                {mustBeMember(nvp.ResponseFormat, ...
                                                    ["json","text","srt","vtt","verbose_json"])} = "json"
                nvp.Temperature             (1,1) {mustBeInRange(nvp.Temperature,0,1)} = 0
                nvp.TimeOut                 (1,1) {mustBeReal,mustBePositive} = 10
                nvp.ApiKey                        {mustBeNonzeroLengthTextScalar} 
            end

            endpoint = "https://api.openai.com/v1/audio/translations";
            apikey = getenv("OPENAI_API_KEY");
            timeout = nvp.TimeOut;

            import matlab.net.http.io.*
            params = struct('model', nvp.ModelName, 'file', FileProvider(filepath));
            if isfield(nvp,"Prompt")
                params.prompt = nvp.Prompt;
            end
            if nvp.ResponseFormat ~= "json"
                params.response_format = nvp.ResponseFormat;
            end
            if nvp.Temperature > 0
                params.temperature = nvp.Temperature;
            end
            keyval = [fieldnames(params) struct2cell(params)].';
            body = MultipartFormProvider(keyval{:});

            keyval = [fieldnames(params) struct2cell(params)].';
            body = MultipartFormProvider(keyval{:});

            % Send the HTTP Request
            response = sendRequest(apikey, endpoint, body, timeout);
            if isfield(response.Body.Data,"error")
                output = "";
            else
                output = response.Body.Data;
            end
            
        end

    end
    
end

function response = sendRequest(apikey,endpoint,body,timeout)
    % sendRequest send request to the given endpoint, return response
    headers =  matlab.net.http.HeaderField('Authorization', "Bearer " + apikey);
    if isa(body,'struct')
        headers(2) =  matlab.net.http.HeaderField('Content-Type', 'application/json');
    end
    request =  matlab.net.http.RequestMessage('post', headers, body);
    httpOpts = matlab.net.http.HTTPOptions;
    httpOpts.ConnectTimeout = timeout;
    response = send(request, matlab.net.URI(endpoint), httpOpts);
end

function mustBeValidFileType(filePath)
    mustBeFile(filePath);
    s = dir(filePath);
    if ~endsWith(s.name, [".flac",".mp3",".mp4",".mpeg",".mpga",".m4a",".ogg",".wav","webm"])
        error("Not a valid file type")
        % error("llms:pngExpected", ...
        %     llms.utils.errorMessageCatalog.getMessage("llms:pngExpected"));
    end
    mustBeLessThan(s.bytes,4e+6)
end

function mustBeNonzeroLengthTextScalar(content)
    mustBeNonzeroLengthText(content)
    mustBeTextScalar(content)
end

function mustBeValidLanCode(code)
    mustBeTextScalar(code)
    if strlength(code) ~= 2
        error("Use 2-letter ISO-639-1 language code.")
    end
    
end