classdef (Sealed) openAIMessages   
    %openAIMessages - Create an object to manage and store messages in a conversation.
    %   messages = openAIMessages creates an openAIMessages object.
    %
    %   openAIMessages functions:
    %       addSystemMessage         - Add system message.
    %       addUserMessage           - Add user message.
    %       addUserMessageWithImages - Add user message with images for
    %                                  GPT-4 Turbo with Vision.
    %       addToolMessage           - Add a tool message.
    %       addResponseMessage       - Add a response message.
    %       removeMessage            - Remove message from history.
    %
    %   openAIMessages properties:
    %       Messages                 - Messages in the conversation history.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties(SetAccess=private)
        %MESSAGES - Messages in the conversation history.
        Messages = {}
    end
    
    methods
        function this = addSystemMessage(this, name, content)
            %addSystemMessage   Add system message.
            %
            %   MESSAGES = addSystemMessage(MESSAGES, NAME, CONTENT) adds a system
            %   message with the specified name and content. NAME and CONTENT
            %   must be text scalars.
            %
            %   Example:
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add system messages to provide examples of the conversation
            %   messages = addSystemMessage(messages, "example_user", "Hello, how are you?");
            %   messages = addSystemMessage(messages, "example_assistant", "Olá, como vai?");
            %   messages = addSystemMessage(messages, "example_user", "The sky is beautiful today");
            %   messages = addSystemMessage(messages, "example_assistant", "O céu está lindo hoje.");

            arguments
                this (1,1) openAIMessages 
                name {mustBeNonzeroLengthTextScalar}
                content {mustBeNonzeroLengthTextScalar}
            end

            newMessage = struct("role", "system", "name", string(name), "content", string(content));
            this.Messages{end+1} = newMessage;
        end

        function this = addUserMessage(this, content)
            %addUserMessage   Add user message.
            %
            %   MESSAGES = addUserMessage(MESSAGES, CONTENT) adds a user message
            %   with the specified content to MESSAGES. CONTENT must be a text scalar.
            %
            %   Example:
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add user message
            %   messages = addUserMessage(messages, "Where is Natick located?");

            arguments
                this (1,1) openAIMessages
                content {mustBeNonzeroLengthTextScalar}
            end

            newMessage = struct("role", "user", "content", string(content));
            this.Messages{end+1} = newMessage;
        end

        function this = addUserMessageWithImages(this, content, images, nvp)
            %addUserMessageWithImages   Add user message with images
            %
            %   MESSAGES = addUserMessageWithImages(MESSAGES, CONTENT, IMAGES) 
            %   adds a user message with the specified content and images 
            %   to MESSAGES. CONTENT must be a text scalar. IMAGES must be
            %   a string array of image URLs or file paths. 
            %
            %   messages = addUserMessageWithImages(__,Detail="low");
            %   specify how the model should process the images using
            %   "Detail" parameter. The default is "auto".
            %   - When set to "low", the model scales the image to 512x512 
            %   - When set to "high", the model scales the image to 512x512
            %   and also creates detailed 512x512 crops of the image
            %   - When set to "auto", the models chooses which mode to use
            %   depending on the input image. 
            %
            %   Example:
            %
            %   % Create a chat with GPT-4 Turbo with Vision
            %   chat = openAIChat("You are an AI assistant.", ModelName="gpt-4-vision-preview"); 
            %
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add user message with an image
            %   content = "What is in this picture?"
            %   images = "peppers.png"
            %   messages = addUserMessageWithImages(messages, content, images);
            %
            %   % Generate a response
            %   [text, response] = generate(chat, messages, MaxNumTokens=300);
            
            arguments
                this (1,1) openAIMessages
                content {mustBeNonzeroLengthTextScalar}
                images (1,:) {mustBeNonzeroLengthText}
                nvp.Detail string {mustBeMember(nvp.Detail,["low","high","auto"])} = "auto"
            end

            newMessage = struct("role", "user", "content", []);
            newMessage.content = {struct("type","text","text",string(content))};
            for img = images(:).'
                if startsWith(img,("https://"|"http://"))
                    s = struct( ...
                        "type","image_url", ...
                        "image_url",struct("url",img));
                else
                    [~,~,ext] = fileparts(img);
                    MIMEType = "data:image/" + erase(ext,".") + ";base64,";
                    % Base64 encode the image using the given MIME type
                    fid = fopen(img);
                    im = fread(fid,'*uint8');
                    fclose(fid);
                    b64 = matlab.net.base64encode(im);
                    s = struct( ...
                        "type","image_url", ...
                        "image_url",struct("url",MIMEType + b64));
                end

                s.image_url.detail = nvp.Detail;

                newMessage.content{end+1} = s;
                this.Messages{end+1} = newMessage;
            end

        end

        function this = addToolMessage(this, id, name, content)
            %addToolMessage   Add Tool message.
            %
            %   MESSAGES = addToolMessage(MESSAGES, ID, NAME, CONTENT)
            %   adds a tool message with the specified id, name and content. 
            %   ID, NAME and CONTENT must be text scalars.
            %
            %   Example:
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add function message, containing the result of 
            %   % calling strcat("Hello", " World")
            %   messages = addToolMessage(messages, "call_123", "strcat", "Hello World");

            arguments
                this (1,1) openAIMessages
                id {mustBeNonzeroLengthTextScalar}
                name {mustBeNonzeroLengthTextScalar}
                content {mustBeNonzeroLengthTextScalar}

            end

            newMessage = struct("tool_call_id", id, "role", "tool", ...
                "name", string(name), "content", string(content));
            this.Messages{end+1} = newMessage;
        end
       
        function this = addResponseMessage(this, messageStruct)
            %addResponseMessage   Add response message.
            %
            %   MESSAGES = addResponseMessage(MESSAGES, messageStruct) adds a response
            %   message with the specified messageStruct. The input
            %   messageStruct should be a struct with field 'role' and
            %   value 'assistant' and with field 'content'. This response
            %   can be obtained from calling the GENERATE function.
            %
            %   Example:
            %
            %   % Create a chat object
            %   chat = openAIChat("You are a helpful AI Assistant.");
            %
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add user message
            %   messages = addUserMessage(messages, "What is the capital of England?");
            %
            %   % Generate a response
            %   [text, response] = generate(chat, messages);
            %
            %   % Add response to history
            %   messages = addResponseMessage(messages, response);

            arguments
                this (1,1) openAIMessages
                messageStruct (1,1) struct
            end

            if ~isfield(messageStruct, "role")||~isequal(messageStruct.role, "assistant")||~isfield(messageStruct, "content")
                error("llms:mustBeAssistantCall",llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantCall"));
            end

            % Assistant is asking for function call
            if isfield(messageStruct, "tool_calls")
                toolCalls = messageStruct.tool_calls;
                validateAssistantWithToolCalls(toolCalls)
                this = addAssistantMessage(this, messageStruct.content, toolCalls);
            else
                % Simple assistant response
                validateRegularAssistant(messageStruct.content);
                this = addAssistantMessage(this,messageStruct.content);
            end
        end

        function this = removeMessage(this, idx)
            %removeMessage   Remove message.
            %
            %   MESSAGES = removeMessage(MESSAGES, IDX) removes a message at the specified
            %   index from MESSAGES. IDX must be a positive integer.
            %
            %   Example:
            %
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add user messages
            %   messages = addUserMessage(messages, "What is the capital of England?");
            %   messages = addUserMessage(messages, "What is the capital of Italy?");
            %
            %   % Remove the first message
            %   messages = removeMessage(messages,1);

            arguments
                this (1,1) openAIMessages
                idx (1,1) {mustBeInteger, mustBePositive}
            end
            if idx>numel(this.Messages)
                error("llms:mustBeValidIndex",llms.utils.errorMessageCatalog.getMessage("llms:mustBeValidIndex", string(numel(this.Messages))));
            end
            this.Messages(idx) = [];
        end
    end

    methods(Access=private)

        function this = addAssistantMessage(this, content, toolCalls)
            arguments
                this (1,1) openAIMessages
                content string
                toolCalls struct = []
            end

            if isempty(toolCalls)
                % Default assistant response
                 newMessage = struct("role", "assistant", "content", content);
            else
                % tool_calls message
                toolsStruct = repmat(struct("id",[],"type",[],"function",[]),size(toolCalls));
                for i = 1:numel(toolCalls)
                    toolsStruct(i).id = toolCalls(i).id;
                    toolsStruct(i).type = toolCalls(i).type;
                    toolsStruct(i).function = struct( ...
                        "name", toolCalls(i).function.name, ...
                        "arguments", toolCalls(i).function.arguments);
                end
                if numel(toolsStruct) > 1
                    newMessage = struct("role", "assistant", "content", content, "tool_calls", toolsStruct);
                else
                    newMessage = struct("role", "assistant", "content", content, "tool_calls", []);
                    newMessage.tool_calls = {toolsStruct};
                end
            end
            
            if isempty(this.Messages)
                this.Messages = {newMessage};
            else
                this.Messages{end+1} = newMessage;
            end
        end
    end
end

function mustBeNonzeroLengthTextScalar(content)
mustBeNonzeroLengthText(content)
mustBeTextScalar(content)
end

function validateRegularAssistant(content)
try
    mustBeNonzeroLengthText(content)
    mustBeTextScalar(content)
catch ME
    error("llms:mustBeAssistantWithContent",llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithContent"))
end
end

function validateAssistantWithToolCalls(toolCallStruct)
if ~(isstruct(toolCallStruct) && isfield(toolCallStruct, "id") && isfield(toolCallStruct, "function"))
    error("llms:mustBeAssistantWithIdAndFunction", ...
        llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithIdAndFunction"))
else
    functionCallStruct = [toolCallStruct.function];
end

if ~isfield(functionCallStruct, "name")||~isfield(functionCallStruct, "arguments")
    error("llms:mustBeAssistantWithNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithNameAndArguments"))
end

try
    for i = 1:numel(functionCallStruct)
        mustBeNonzeroLengthText(functionCallStruct(i).name)
        mustBeTextScalar(functionCallStruct(i).name)
        mustBeNonzeroLengthText(functionCallStruct(i).arguments)
        mustBeTextScalar(functionCallStruct(i).arguments)
    end
catch ME
    error("llms:assistantMustHaveTextNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:assistantMustHaveTextNameAndArguments"))
end
end
