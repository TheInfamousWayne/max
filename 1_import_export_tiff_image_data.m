% Load a TIFF image file named 'peppers_RGB_tiled.tif' for reading
t = Tiff('peppers_RGB_tiled.tif', 'r');

% Read the image data from the TIFF file into the variable imageDataTiff
imageDataTiff = read(t);

% Create a new figure window with the title 'tif' to display the TIFF image
figure('Name', 'tif');

% Display the TIFF image data using imshow function
imshow(imageDataTiff);

% Set the title of the current figure to 'Image tif'
title('Image tif');

% Write the TIFF image data to a new file named 'sample.tiff' in TIFF format
imwrite(imageDataTiff, 'sample.tiff', 'tiff');

% Write the same image data to another file named 'sample.jpg' in JPEG format
imwrite(imageDataTiff, 'sample.jpg', 'jpg');

% Create a datastore object for the 'sample.jpg' file to manage large data
t = datastore('sample.jpg');

% Read the image data from the JPEG file into the variable imageDataJPG
imageDataJPG = read(t);

% Create a new figure window with the title 'jpg' to display the JPEG image
figure('Name', 'jpg');

% Display the JPEG image data using imshow function
imshow(imageDataJPG);

% Set the title of the current figure to 'Image jpg'
title('Image jpg');

% Create a new figure window with the title 'Diff' to display the difference image
figure('Name', 'Diff');

% Calculate the squared difference between the TIFF and JPEG image data,
% and display it using imshow function to visualize the difference
imshow((imageDataTiff - imageDataJPG).^2);

% Set the title of the current figure to 'Image Diff'
title('Image Diff');
