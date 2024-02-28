classdef MsgHelper
    %MSGHELPER Collection of static methods for message processing
    %   MsgHelper has multiple static methods that can be used for the
    %   message processing used by MatGPT

    methods (Access=public,Static)

        function [contextwindow,cutoff] = getModelDetails(modelName)
            % provide context window for a given model
            % supported models
            models = [ ...
                struct('name','gpt-3.5-turbo','attributes',struct('contextwindow',4096,'cutoff','Sep 2021'),'legacy',false), ...
                struct('name','gpt-3.5-turbo-1106','attributes',struct('contextwindow',16385,'cutoff','Sep 2021'),'legacy',false), ...
                struct('name','gpt-3.5-turbo-16k','attributes',struct('contextwindow',16385,'cutoff','Sep 2021'),'legacy',false), ...
                struct('name','gpt-4','attributes',struct('contextwindow',8192,'cutoff','Sep 2021'),'legacy',false), ...
                struct('name','gpt-4-0613','attributes',struct('contextwindow',8192,'cutoff','Sep 2021'),'legacy',false), ...
                struct('name','gpt-4-1106-preview','attributes',struct('contextwindow',128000,'cutoff','Apr 2023'),'legacy',false), ...
                struct('name','gpt-4-vision-preview','attributes',struct('contextwindow',128000,'cutoff','Apr 2023'),'legacy',false), ...
                struct('name','gpt-4-turbo-preview','attributes',struct('contextwindow',128000,'cutoff','Apr 2023'),'legacy',false) ...
                ];
            contextwindow = models(arrayfun(@(x) string(x.name), models) == modelName).attributes.contextwindow;
            cutoff = models(arrayfun(@(x) string(x.name), models) == modelName).attributes.cutoff;
        end

        function s = startupMessages()
            % add startup messages
            s = struct('role',"MagGPT",'content',[]);
            s.content = "This app provides access to the ChatGPT API " + ...
                "from OpenAI. To use this app, you need to obtain " + ...
                "your own API key via <a href='https://platform.openai.com/account/api-keys' target='_blank'>" + ...
                "https://platform.openai.com/account/api-keys</a>. " + ...
                "By obtaining and using the API key in this app, " + ...
                "you agree to OpenAI's <a href='https://openai.com/policies' target='_blank'>" + ...
                "terms and policies</a>.";
            s.content = [s.content,"<p style='font-size: 1.1em; font-weight: bold'>To get started, click ""+ New Chat"" or the name of a previous chat.</p>"];
            s.content = [s.content,"<strong>What's New</strong>: " + ... 
                "<ul><li>Runs on the <a href='https://github.com/matlab-deep-learning/llms-with-matlab' target='_blank'>LLMs with MATLAB</a> framework, which requires MATLAB R2023a or later</li>" + ...
                "<li>Detects a URL included in a prompt, and retrieve its content into the chat.</<li>" + ...
                "<li>Lets you import a .m, .mlx, .csv, or .txt file into the chat</li>" + ...
                "<li>Supports GPT-4 Turbo with Vision with .jpg, .png or .gif images</li>" + ...
                "<li>Supports image generation via DALLe-3 API when streaming is disabled</li></ul>" + ...
                "<strong>Notes</strong>:" + ...
                "<ul><li>Imported content will be truncated if it exceeds the context window limit.</li>" + ...
                "<li>PDF file is supported if Text Analytics Toolbox is available.</li></ul>"];
        end

        function processed = processRelatedQuestions(response)
            % check if related questions are contained in the response
            % extract answer
            answer = extractBefore(response,"Three related questions:");
            % extract the related questions
            questions = extractAfter(response,"Three related questions:");
            questions = split(questions,newline);
            questions = questions(strlength(questions)>0 & questions ~= " ");
            questions = erase(questions, digitsPattern(1)+". ");
            htmlwrapper = "<button class=""relquestion"">";
            htmlwrapper = htmlwrapper + questions + "</button>";
            processed = answer + join(htmlwrapper);
        end

        function messages = addFunctionMessage(messages,content)
            % add assistant message with tool calls
            id = "call_" + string(datetime('now',Format="yyyyMMddHHmmss"));
            functionName = "MATLAB";
            args = "{""arg1"": 1 }";
            funCall = struct("name", functionName, "arguments", args);
            toolCall = struct("id", id, "type", "function", "function", funCall);
            toolCallPrompt = struct("role", "assistant", "content", "", "tool_calls", toolCall);
            messages = addResponseMessage(messages, toolCallPrompt);
            % add content as the function result
            messages = addToolMessage(messages,id,functionName,content);
        end

        function messages = removeTestReports(messages)
            % remove test reports before sending user prompt    

            % extract content from messages
            contents = strings(size(messages.Messages));
            isText = ~cellfun(@(x) isempty(x.content), messages.Messages);
            contents(isText) = cellfun(@(x) x.content, messages.Messages(isText));
            isTestReport = startsWith(contents,'<div class="test-report">');
            if any(isTestReport)
                idx1 = find(isTestReport);
                for ii = numel(idx1):-1:1
                    % get the tool call id
                    id1 = messages.Messages{idx1(ii)}.tool_call_id;
                    messages = removeMessage(messages,idx1(ii));
                    % must also remove the matching tool call
                    isToolCall = strlength(contents) == 0;
                    idx2 = find(isToolCall);
                    for jj = numel(idx2):-1:1
                        % get the tool call id
                        id2 = messages.Messages{idx2(jj)}.tool_calls{1}.id;
                        % if tool call ids match
                        if id1 == id2
                            messages = removeMessage(messages,idx2(jj));
                        end
                    end
                end
            end
        end

        function fitted = fitContextWindow(model,content,max_tokens)
            % FITCONTEXTWINDOW - makes sure content fits the context window
            % update the context window value
            [cw,~] = MsgHelper.getModelDetails(model);
            % subtract the max tokens to derive the available window
            max_length = cw - max_tokens;
            % 1 token ~= 4 chars in English
            max_length = max_length * 2; % be conservative
            % if the content fits within the context window
            if strlength(content) < max_length
                % do nothing
                fitted = content;
            else
                % truncate
                truncated = char(content);
                truncated = string(truncated(1:max_length));
                % drop the last word
                splitted = split(truncated,whitespacePattern);
                fitted = erase(truncated,splitted(end) + textBoundary("end"));
            end
        end

        function url = extractURL(content)
            % check if the prompt contains any url
            urlPat = ("http://" | "https://") + ...
                asManyOfPattern(alphanumericsPattern(1) | ...
                    characterListPattern("./_-:;%&?#"), 1);
            url = extract(content,urlPat);
        end

        % generate base64 encoded img tag
        function imgTag = getHTMLImgTag(filepath)
            [~,~,ext] = fileparts(filepath);
            MIMEType = "data:image/" + erase(ext,".") + ";base64,";
            fid = fopen(filepath);
            byteArray = fread(fid,'*uint8');
            fclose(fid);
            b64char = matlab.net.base64encode(byteArray);
            urlEncoded = MIMEType + b64char;
            imgTag = "<img width=512 src=" + urlEncoded + ">";
        end

        % function call to generate image
        function [image, url, response] = generateImage(prompt)
            mdl = openAIImages(ModelName="dall-e-3");
            [images, response] = generate(mdl,string(prompt));
            image = images{1};
            url = response.Body.Data.data.url;
        end

        % function call to understand image
        function [txt,message,response] = understandImage(prompt,image,max_tokens)
            chat = openAIChat("You are an AI assistant","ModelName","gpt-4-vision-preview");
            messages = openAIMessages;
            messages = addUserMessageWithImages(messages,prompt,image);
            [txt,message,response] = generate(chat,messages,MaxNumTokens=max_tokens);
        end
 
    end
end