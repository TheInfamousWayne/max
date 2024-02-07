classdef parfor_wait < handle
    % This class creates a waitbar or message when using for or parfor loops.
    % It allows the user to keep track of the loop's progress, which is especially useful
    % for long-running loops.

    % Properties that cannot be changed after object creation (private set access)
    properties (SetAccess = private)
        NumMessage; % Number of messages received from the workers.
        TotalMessage; % Total number of messages expected.
        Waitbar; % Flag indicating whether a waitbar is used.
        FileName; % Name of the file where messages are saved, or 'screen' to display.
        StartTime; % Time when the process started.
        UsedTime_1; % Time at the previous update step.
        WaitbarHandle; % Handle to the waitbar GUI.
        ReportInterval; % Interval between progress updates.
        FileID; % File identifier for writing messages to a file.
        DataQueueHandle; % Handle for the parallel pool DataQueue.
    end

    methods
        function Obj = parfor_wait(TotalMessage, varargin)
            % Constructor for the class.
            % Initializes the DataQueue, sets the start time, and configures settings based on inputs.

            Obj.DataQueueHandle = parallel.pool.DataQueue;
            Obj.StartTime = tic;
            Obj.NumMessage = 0;
            Obj.UsedTime_1 = Obj.StartTime;
            Obj.TotalMessage = TotalMessage;
            InParser = inputParser;
            addParameter(InParser,'Waitbar',false,@islogical);
            addParameter(InParser,'FileName', 'screen', @ischar);
            addParameter(InParser,'ReportInterval', ceil(TotalMessage/100), @isnumeric);
            parse(InParser, varargin{:});
            Obj.Waitbar = InParser.Results.Waitbar;
            Obj.FileName = InParser.Results.FileName;
            Obj.ReportInterval = InParser.Results.ReportInterval;
            if Obj.Waitbar
                Obj.WaitbarHandle = waitbar(0, [num2str(0), '%'], 'Resize', true);
            end
            switch Obj.FileName
                case 'screen'
                otherwise
                    Obj.FileID = fopen(Obj.FileName, 'w');
            end
            afterEach(Obj.DataQueueHandle, @Obj.Update);
        end

        function Send(Obj)
            % Method to be called inside the loop to send a progress update.
            send(Obj.DataQueueHandle, 0);
        end

        function Destroy(Obj)
            % Method to clean up once the loop is finished. Closes the waitbar/file and deletes the object.
            if Obj.Waitbar
                delete(Obj.WaitbarHandle);
            end
            delete(Obj.DataQueueHandle);
            delete(Obj);
        end
    end

    methods (Access = private)
        function Obj = Update(Obj, ~)
            % Private method called by the DataQueue to update the progress.
            Obj.AddOne; % Increment the message count.
            if mod(Obj.NumMessage, Obj.ReportInterval) % Check if it's time to report.
                return
            end
            if Obj.Waitbar
                Obj.WaitbarUpdate; % Update the waitbar if enabled.
            else
                Obj.FileUpdate; % Update the file or screen message if waitbar is not used.
            end
        end

        function WaitbarUpdate(Obj)
            % Private method to update the waitbar with the current progress and time estimate.
            UsedTime_now = toc(Obj.StartTime);
            EstimatedTimeNeeded = (UsedTime_now-Obj.UsedTime_1)/Obj.ReportInterval*(Obj.TotalMessage-Obj.NumMessage);
            waitbar(Obj.NumMessage/Obj.TotalMessage, Obj.WaitbarHandle, [num2str(Obj.NumMessage/Obj.TotalMessage*100, '%.2f'), '%; ', num2str(UsedTime_now, '%.2f'), 's used and ', num2str(EstimatedTimeNeeded, '%.2f'), 's needed.']);
            Obj.UsedTime_1 = UsedTime_now;
        end

        function FileUpdate(Obj)
            % Private method to write the current progress and time estimate to a file or the screen.
            UsedTime_now = toc(Obj.StartTime);
            EstimatedTimeNeeded = (UsedTime_now-Obj.UsedTime_1)/Obj.ReportInterval*(Obj.TotalMessage-Obj.NumMessage);
            switch Obj.FileName
                case 'screen'
                    fprintf('%.2f%%; %.2fs used and %.2fs needed...\n', Obj.NumMessage/Obj.TotalMessage*100, UsedTime_now, EstimatedTimeNeeded);
                otherwise
                    fprintf(Obj.FileID, '%.2f%%; %.2fs used and %.2fs needed...\n', Obj.NumMessage/Obj.TotalMessage*100, UsedTime_now, EstimatedTimeNeeded);
            end
            Obj.UsedTime_1 = UsedTime_now;
        end

        function AddOne(Obj)
            % Private method to increment the message count.
            Obj.NumMessage = Obj.NumMessage + 1;
        end
    end
end
