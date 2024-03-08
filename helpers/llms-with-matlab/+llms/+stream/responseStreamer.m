classdef responseStreamer < matlab.net.http.io.StringConsumer
%responseStreamer Responsible for obtaining the streaming results from the
%API

%   Copyright 2023 The MathWorks, Inc.

    properties
        ResponseText
        StreamFun
    end

    methods
        function this = responseStreamer(streamFun)
            this.StreamFun = streamFun;
        end
    end

    methods (Access=protected)
        function length = start(this)
            if this.Response.StatusCode ~= matlab.net.http.StatusCode.OK
                length = 0;
            else
                length = this.start@matlab.net.http.io.StringConsumer;
            end
        end
    end
    
    methods
        function [len,stop] = putData(this, data)
            [len,stop] = this.putData@matlab.net.http.io.StringConsumer(data);
            
            % Extract out the response text from the message
            str = native2unicode(data','UTF-8');
            str = split(str,newline);
            str = str(strlength(str)>0);
            str = erase(str,"data: ");

            for i = 1:length(str)
                if strcmp(str{i},'[DONE]')
                    stop = true;
                    return
                else
                    try
                        json = jsondecode(str{i});
                    catch ME
                        errID = 'llms:stream:responseStreamer:InvalidInput';
                        msg = "Input does not have the expected json format. " + str{i};
                        ME = MException(errID,msg);
                        throw(ME)
                    end
                    if ischar(json.choices.finish_reason) && ismember(json.choices.finish_reason,["stop","tool_calls"])
                        stop = true;
                        return
                    else
                        if isfield(json.choices.delta,"tool_calls")
                            if isfield(json.choices.delta.tool_calls,"id")
                                id = json.choices.delta.tool_calls.id;
                                type = json.choices.delta.tool_calls.type;
                                fcn = json.choices.delta.tool_calls.function;
                                s = struct('id',id,'type',type,'function',fcn);
                                txt = jsonencode(s);
                            else
                                s = jsondecode(this.ResponseText);
                                args = json.choices.delta.tool_calls.function.arguments;
                                s.function.arguments = [s.function.arguments args];
                                txt = jsonencode(s);
                            end
                            this.StreamFun('');
                            this.ResponseText = txt;
                        else
                            txt = json.choices.delta.content;
                            this.StreamFun(txt);
                            this.ResponseText = [this.ResponseText txt];
                        end
                    end
                end
            end
        end
    end
end