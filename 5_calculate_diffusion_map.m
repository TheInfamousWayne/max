% Prompt the user to select a folder and store the selected folder path
folder = uigetdir;

% Load DICOM images and their headers from the selected directory
[img, hdr] = loadDicom(fullfile(folder, 'pdata\1\dicom'));

% Load b-values from the Bruker method file
methodData = readBrukerParamFile(fullfile(folder, 'method'));
bValues = methodData.PVM_DwEffBval;

% Calculate diffusion, ignoring direction
% Calculate ADC, multiply by 1000 to convert to x10^-3 mm^2/s, and cast to int16
ADC = int16(calculateDiffusion(img(:,:,:,bValues > 50), bValues(bValues > 50)) * 1000.0);

% Initialize a variable to control when saving is finished
finished = false;

% Loop until the user has successfully saved the file or cancels
while ~finished
    % Open a dialog to select file name and path for saving the DICOM file
    [fileName, pathName] = uiputfile({'*.dcm;*.ima', 'DICOM files (*.dcm,*.ima)'}, ...
                                     'Select output folder and filename', fullfile(folder, 'output.dcm'));
    % Initialize variables to control overwriting and starting over
    startover = false;
    overwrite = false;
    
    % If a path has been selected, proceed with saving
    if pathName
        % Extract file extension and file name
        ext = fileName(end-2:end);
        fileName = fileName(1:end-4);
        
        % Generate a unique DICOM UID for the series
        DcmID = dicomuid;
        
        % Loop through each slice to save
        for N = 1:size(hdr,1)
            if startover
                continue % Skip the rest of the loop if starting over
            end
            
            % Get header for the current slice
            HDR = hdr{N,1};
            
            % Update DICOM header information for ADC map
            HDR.SeriesInstanceUID = DcmID;
            HDR.ImageType = 'DERIVED\PRIMARY\M\ND\ADC';
            HDR.ProtocolName = 'ADC';
            
            % Generate output file name with slice number
            outFile = fullfile(pathName, sprintf('%s_%03.0f.%s', fileName, N, ext));
            
            % Check if file exists and handle overwriting
            if exist(outFile, 'file') && ~overwrite
                choice = questdlg(sprintf('%s already exists. Overwrite?', outFile), ...
                                  'File exists', 'Yes', 'All', 'No', 'No');
                switch choice
                    case 'No'
                        startover = true; % Start over by selecting a new file name
                        continue
                    case 'All' % All existing files should be overwritten
                        overwrite = true;
                end
            end
            
            % Write the slice as a DICOM file
            dicomwrite(ADC(:,:,N), outFile, HDR);
        end
        
        % If we're not starting over, we're finished
        if ~startover
            finished = true;
        end
    end
end

% Print a message indicating the completion of the process
fprintf('DONE!\n');
