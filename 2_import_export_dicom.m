% Open a dialog to select a directory, then create a collection of DICOM files from the directory
collection = dicomCollection(uigetdir);

% Read the volume data and spatial information from the DICOM collection
[V, spatial] = dicomreadVolume(collection);

% Remove singleton dimensions from the volume data
V = squeeze(V);

% Display the 3D volume using volume viewer
volshow(V);

% Initialize the threshold level to 10.0
level = 10.0;

% Start an infinite loop for threshold adjustment
while true
    Vnew = V; % Copy the original volume data to a new variable for modification

    % Find the maximum and minimum values in the volume data
    maxData = max(V, [], 'all');
    minData = min(V, [], 'all');

    % Apply thresholding: Set values below a certain threshold to 0
    Vnew(Vnew < (maxData - minData) * level / 100.0) = 0;

    % Display the thresholded 3D volume
    volshow(Vnew);

    % Open a dialog box asking if the threshold level is good
    if strcmp('Yes', questdlg('Is the threshold now good?', ...
        'threshold', 'Yes', 'No', 'Yes'))
        break % Exit the loop if the user is satisfied with the threshold
    else
        % If the user is not satisfied, prompt for a new threshold level
        level = str2double(inputdlg(...
            'Please enter the new threshold level', 'Input', ...
            [1 32], {num2str(level)}));
    end
end
