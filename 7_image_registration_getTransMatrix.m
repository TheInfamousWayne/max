function [M, R] = getTransMatrix(info)
    % This function calculates the 4x4 transform matrix from the image
    % coordinates to patient coordinates.

    % Extract image position and convert to double precision
    ip = double(info.ImagePosition(1,:));
    
    % Extract image orientation and convert to double precision
    io = double(info.ImageOrientation);
    
    % Calculate pixel spacing by dividing the field of view by the number of pixels in each dimension
    ps = double(info.FieldOfView) ./ [double(info.Width), double(info.Height)];
    
    % Create a translation matrix using the image position
    Tip = [1.0 0.0 0.0 ip(1); ...
           0.0 1.0 0.0 ip(2); ...
           0.0 0.0 1.0 ip(3); ...
           0.0 0.0 0.0 1.0];
    
    % Extract the first three and the last three elements of the image orientation
    io123 = io(1:3);
    io456 = io(4:6);
    
    % Calculate the cross product of the orientation vectors to get the normal vector
    ioc = cross(io123', io456');
    
    % Create a rotation matrix using the image orientation vectors
    R = [io123(1) io456(1) ioc(1) 0.0; ...
         io123(2) io456(2) ioc(2) 0.0; ...
         io123(3) io456(3) ioc(3) 0.0; ...
         0.0       0.0       0.0      1.0];
    
    % Check the acquisition type to determine the slice thickness or spacing
    if strcmp(info.MRAcquisitionType, '3D') || strcmp(info.MRAcquisitionType, '<3D>')
        % Create a scaling matrix for 3D acquisition using slice thickness
        S = [ps(1) 0.0 0.0 0.0; ...
             0.0 ps(2) 0.0 0.0; ...
             0.0 0.0 info.SliceThickness 0.0 ; ...
             0.0 0.0 0.0 1.0];
    else
        % Create a scaling matrix for other types of acquisition using spacing between slices
        S = [ps(1) 0.0 0.0 0.0; ...
             0.0 ps(2) 0.0 0.0; ...
             0.0 0.0 info.SpacingBetweenSlices 0.0; ...
             0.0 0.0 0.0 1.0];
    end
    
    % Combine the translation, rotation, and scaling matrices to get the final transformation matrix
    M = Tip * R * S;
end
