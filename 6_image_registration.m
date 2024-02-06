% Initialize variables
baseImage = Image{1}; % Assuming Image is a cell array with the base image in the first cell
sizeBaseImage = size(baseImage); % Get the size of the base image
volumeLive = size(baseImage, 4); % Get the number of volumes (4th dimension) in the base image
VolumeNr = 0; % Initialize the variable for the total number of volumes

% Calculate the reference space for 3D image
space = imref3d(sizeBaseImage(1:3)); % Create a spatial reference object for the base image size

% Loop through all images to calculate the total volume
for liveImg = 1:NrOfImg % Assuming NrOfImg is the number of images to be registered
    VolumeNr = VolumeNr + size(Image{liveImg}, 4); % Accumulate the total volume
end

% Prompt the user to specify the type of interpolation for the image registration
paraA = inputdlg({'Specify the type of interpolation: (nearest, linear, cubic)'}, ...
                 'Image fusion input dialog', [1 64], {'nearest'});

% Check if the user input is empty and set default interpolation method if so
if isempty(paraA)
    uiwait(errordlg('Undefined parameter A!', 'Error')); 
    Interp = 'nearest';
else
    Interp = paraA{1}; % Use the user-specified interpolation method
end

% Preallocate a 4D array for storing all the registered images
data = zeros(sizeBaseImage(1), sizeBaseImage(2), sizeBaseImage(3), VolumeNr);
data(:,:,:,1:size(baseImage, 4)) = baseImage; % Insert the base image into the dataset

% Process the subsequent images for registration
for liveImg = 2:NrOfImg
    % Get the transformation matrix for the current image to be registered
    M = getTransformMatrix(MetaData{liveImg}, MetaData{1}); % Assuming MetaData is a cell array of meta information for the images
    
    % A workaround for coordinate system adjustment (seems to be a hack, should be refined)
    M(4, 1:3) = M(4, 1:3) + (M(1:3, 1:3) * [-0.5 -0.5 -1.5]')';
    
    % Calculate a 3-D affine geometric transformation object with the matrix 'M'
    tform = affine3d(M);
    
    % Warp each volume of the current image using the transformation object
    for live = 1:size(Image{liveImg}, 4)
        volumeLive = volumeLive + 1;
        % Apply the transformation to the current volume with specified interpolation
        data(:,:,:,volumeLive) = imwarp(squeeze(Image{liveImg}(:,:,:,live)), ...
                                         tform, 'Interp', Interp, 'FillValues', 0, 'OutputView', space);
    end
end
