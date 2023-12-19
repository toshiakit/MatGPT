classdef (Sealed) openAIMessages   
    %openAIMessages - Create an object to manage and store messages in a conversation.
    %   messages = openAIMessages creates an openAIMessages object.
    %
    %   openAIMessages functions:
    %       addSystemMessage   - Add system message.
    %       addUserMessage     - Add user message.
    %       addFunctionMessage - Add a function message.
    %       addResponseMessage - Add a response message.
    %       removeMessage      - Remove message from history.
    %
    %   openAIMessages properties:
    %       Messages           - Messages in the conversation history.

    % Copyright 2023 The MathWorks, Inc.

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

        function this = addFunctionMessage(this, name, content)
            %addFunctionMessage   Add function message.
            %
            %   MESSAGES = addFunctionMessage(MESSES, NAME, CONTENT) adds a function
            %   message with the specified name and content. NAME and
            %   CONTENT must be text scalars.
            %
            %   Example:
            %   % Create messages object
            %   messages = openAIMessages;
            %
            %   % Add function message, containing the result of 
            %   % calling strcat("Hello", " World")
            %   messages = addFunctionMessage(messages, "strcat", "Hello World");

            arguments
                this (1,1) openAIMessages
                name {mustBeNonzeroLengthTextScalar}
                content {mustBeNonzeroLengthTextScalar}
            end

            newMessage = struct("role", "function", "name", string(name), "content", string(content));
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
            if isfield(messageStruct, "function_call")
                funCall = messageStruct.function_call;
                validateAssistantWithFunctionCall(funCall)
                this = addAssistantMessage(this, funCall.name, funCall.arguments);
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

        function this = addAssistantMessage(this, contentOrfunctionName, arguments)
            arguments
                this (1,1) openAIMessages
                contentOrfunctionName string
                arguments string = []
            end

            if isempty(arguments)
                % Default assistant response
                 newMessage = struct("role", "assistant", "content", contentOrfunctionName);
            else
                % function_call message
                functionCall = struct("name", contentOrfunctionName, "arguments", arguments);
                newMessage = struct("role", "assistant", "content", "", "function_call", functionCall);
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

function validateAssistantWithFunctionCall(functionCallStruct)
if ~isstruct(functionCallStruct)||~isfield(functionCallStruct, "name")||~isfield(functionCallStruct, "arguments")
    error("llms:mustBeAssistantWithNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:mustBeAssistantWithNameAndArguments"))
end

try
    mustBeNonzeroLengthText(functionCallStruct.name)
    mustBeTextScalar(functionCallStruct.name)
    mustBeNonzeroLengthText(functionCallStruct.arguments)
    mustBeTextScalar(functionCallStruct.arguments)
catch ME
    error("llms:assistantMustHaveTextNameAndArguments", ...
        llms.utils.errorMessageCatalog.getMessage("llms:assistantMustHaveTextNameAndArguments"))
end
end
