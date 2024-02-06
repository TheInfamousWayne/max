function [M, Rot] = getTransformMatrix(info1, info2)
    % This function calculates the 4x4 transform and rotation matrix 
    % between two image coordinate systems. 
    % M = Tipp * R * S * T0;
    % Tipp: translation
    % R: rotation
    % S: pixel spacing
    % T0: translate to center (0,0,0) if necessary
    % info1: dicominfo of 1st coordinate system
    % info2: dicominfo of 2nd coordinate system
    % Rot: rotation matrix between coordinate systems

    % Calculate the transformation and rotation matrix for the first image
    [Mdti, Rdti] = getTransMatrix(info1);

    % Calculate the transformation and rotation matrix for the second image
    [Mtf, Rtf] = getTransMatrix(info2);

    % Convert coordinates from the first image space to patient coordinates
    % and then to the coordinate space of the second image
    % This is done by multiplying with the inverse of Mtf to convert patient
    % coordinates back into the image coordinates of the second image.
    M = (Mtf \ Mdti)';

    % Calculate the rotation matrix needed to rotate from the coordinate space 
    % of the first image to the coordinate space of the second image
    Rot = (Rtf \ Rdti)';
end
