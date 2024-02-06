% Prompt the user to select a folder, and store the selected folder path
folder = uigetdir;

% Load DICOM images and headers from the selected directory
[img, hdr] = loadDicom(fullfile(folder, 'pdata\1\dicom'));

% Calculate T1 and M0 Map
% Determine the number of DICOM headers
N = size(hdr, 2);
% Initialize TR (Repetition Time) array based on the number of images
TR = zeros(N, 1);
% Extract the Repetition Time from each DICOM header
for ii = 1:N
    TR(ii) = hdr{1, ii}.RepetitionTime;
end

% Get the size of the image volume
[x, y, z, t] = size(img);

% Test for clipping / saturation
% Count the number of saturated pixels in the image data
numClip = sum(img(:) >= 4095);
if numClip
    % Display a warning if any saturated pixels are found
    warning('Clipping', 'A value of 4095 has been found %1.0f times.', numClip);
end

% Print a message indicating the start of the map calculation
fprintf('\n\nCalculating map....\n\n');
% Set a threshold for the pixel values
threshold = 50;
% Display a warning about the threshold used
warning('Threshold of 50 is used.');

% Define the fit-function for the curve fitting process
F = @(p, x) (1 - exp(-x / p(1))) * p(2);

% Set the lower and upper bounds for the fit parameters
LB = [0, 0]; % Lower bound for all parameters
UB = [10000, 4096]; % Upper bound

% Set the starting point for the fit
SP = [1500, 800]; % Startpoint for fit

% Configure options for the lsqcurvefit function
options = optimset('lsqcurvefit');
options.Display = 'off';
options.FunValCheck = 'on';
options.UseParallel = 'Always';
options.TolFun = 1E-8;
options.TolX = 1E-8;
options.MaxFunEvals = 5000;
options.MaxIter = 5000;
options.Algorithm = 'trust-region-reflective';

% Initialize the T1 and M0 matrices
T1 = zeros(x * y * z, 1); 
M0 = T1;

% Flatten the image data for processing
N = (x * y * z);
img = reshape(img, [x * y * z, t]);

% Create a mask to ignore pixels below the threshold
mask = mean(img, 2) > threshold;

% Create a waitbar to monitor the progress of the parallel loop
WaitMessage = parfor_wait(N, 'Waitbar', true); 

% Start a parallel loop to process each voxel
parfor ii = 1:length(T1)
    if mask(ii) ~= 0
        voxelValue = img(ii, :)';
        % Fit the model to the voxel data
        fitResult = lsqcurvefit(F, SP, TR, voxelValue, LB, UB, options);
        % Store the fitted T1 and M0 values
        T1(ii) = fitResult(1);
        M0(ii) = fitResult(2);
    end
    % Update the wait message
    WaitMessage.Send;
end

% Reshape the T1 and M0 matrices back to the original image dimensions
T1 = reshape(T1, [x, y, z]);
M0 = reshape(M0, [x, y, z]);

% Destroy the wait message
WaitMessage.Destroy;

% Print a message indicating the completion of the process
fprintf('\n\n: Done.\n');
