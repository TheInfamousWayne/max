% Prompt the user to select a folder and store the selected folder path
folder = uigetdir;

% Load DICOM images and their headers from the selected directory
[img, hdr] = loadDicom(fullfile(folder, 'pdata\1\dicom'));

% Calculate T2 Map
% Determine the number of DICOM headers
N = size(hdr, 2);
% Initialize TE (Echo Time) array based on the number of images
TE = zeros(N, 1);
% Extract the Echo Time from each DICOM header
for ii = 1:N
    TE(ii) = hdr{1, ii}.EchoTime;
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

% Preallocate arrays for the fitted parameters 'a' and 'b'
As = zeros(x * y * z, 1); % Preallocation for the fitted 'a'
Bs = As; % Preallocation for the fitted 'b'

% Prepare the design matrix 'X' for linear regression
X = [ones(t, 1) TE];

% Flatten the image data for processing
N = (x * y * z);

% Create a waitbar to monitor the progress of the parallel loop
WaitMessage = parfor_wait(N, 'Waitbar', true);

% Start a parallel loop to process each voxel
parfor i = 1:N
    % Extract the log of the signal intensity for each voxel over time
    Y = logMatrix(i, :);
    % Perform the linear fit to find 'a' and 'b'
    A = X \ Y;
    As(i) = A(2);
    Bs(i) = A(1);
    % Update the wait message
    WaitMessage.Send;
end

% Reshape the fitted parameters back to the original image dimensions
As = reshape(As, [x, y, z]);
Bs = reshape(Bs, [x, y, z]);

% Calculate T2 from the fitted parameter 'a'
T2 = -1 ./ As;
% Set any negative T2 values to zero
T2(T2 < 0) = 0;

% Destroy the wait message
WaitMessage.Destroy;

% Prompt the user to save the T2 map as a DICOM file
[FileName, PathName] = uiputfile('*.dcm', 'Save T2 map as (filename = dicom description)...', fullfile(folder, 'MAPS', 'T2Map.dcm'));

% Set additional header information for the DICOM file
extraHDR.ImageType = 'DERIVED\PRIMARY\M\ND\T2';
extraHDR.ProtocolName = 'T2 Map';
extraHDR.SeriesDescription = FileName;

% Save the T2 map as a DICOM file with the extra header information
saveDicom(T2, hdr(:, 1), PathName, FileName, extraHDR);

% Print a message indicating the completion of the process
fprintf('\n\n: Done.\n');
