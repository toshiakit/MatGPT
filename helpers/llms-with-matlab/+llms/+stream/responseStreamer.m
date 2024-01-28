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
                json = jsondecode(str{i});
                if strcmp(json.choices.finish_reason,'stop')
                    stop = true;
                    return
                else
                    txt = json.choices.delta.content;
                    this.StreamFun(txt);
                    this.ResponseText = [this.ResponseText txt];
                end
            end
        end
    end
end