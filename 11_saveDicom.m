function saveDicom(imageMatrix, header, outputFolder, fileName, extraHeader, createUID)
%SAVEDICOM Writes DICOM files
% USAGE:
%    SAVEDICOM(imageMatrix, header, outputFolder, fileName, extraHeader, createUID)
%
% REQUIRED INPUTS:
%    imageMatrix:  Image data.
%    header:       Header information for each slice. Generally obtained through loadDicom.
%
% OPTIONAL INPUTS:
%    outputFolder: Path where the files will be saved.
%    fileName:     Filename where the files will be saved.
%    extraHeader:  Additional header information that will be included in
%                  the final DICOM. Example: ImageType, ProtocolName, etc.
%                  Provide the extra header as a structure.
%    createUID:    Create a unique DICOM ID for the series. Default: 1.
%
% OUTPUT:
%    None
%
% EXAMPLE:
%    [img,hdr] = loadDicom; % select a folder containing DICOM files
%    extraHDR  = struct();  % initialize additional header information
%    extraHDR.ImageType='DERIVED\PRIMARY\M\ND\JD';
%    extraHDR.ProtocolName='JD';
%    saveDicom(img, hdr, [], [], extraHDR);
%
% NOTES:
%    Images will be written as 16 bit signed integers. Please be aware of
%    potential clipping and round-off errors.
%
% Version 2016.02.15
% JA Disselhorst
%
% DISCLAIMER:
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK

warning('DISSELHORST:Disclaimer','THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED AND IS TO BE USED AT YOUR OWN RISK.');

% Check input parameters
if nargin < 2
    error('Incorrect number of input parameters');
elseif nargin < 4 || isempty(fileName)
    fileName = 'output.dcm';
end

% Prompt for output folder and filename if not provided
if nargin==2 || isempty(outputFolder)
    [fileName,outputFolder] = uiputfile({'*.dcm;*.ima','DICOM files (*.dcm,*.ima)'},'Select a save location',fileName);
end

% Default value for createUID
if nargin<6
    createUID = 1;
end

% Initialize extraHeader if not provided
if nargin<5 || isempty(extraHeader)
    extraHeader = struct();
end

[~,~,z1] = size(imageMatrix);
z2 = numel(header);
if z1~=z2
    error('Number of slices should be equal to the number of headers!');
end

% Create a unique DICOM ID for the series if specified
if createUID
    extraHeader.SeriesInstanceUID = dicomuid;
end

% Convert imageMatrix to 16-bit signed integers if not already
if ~isa(imageMatrix,'integer')
    if any(abs(imageMatrix)>32767)
        warning('Pixels larger than 32767 detected, clipping will occur!');
    end
    imageMatrix = int16(imageMatrix);
end

% Pause to prevent weird MATLAB behavior
pause(.01);

finished = 0;
while ~finished
    ext = fileName(end-2:end);
    file = fileName(1:end-4);
    existing = zeros(1,z2);
    for N = 1:z2
        outFile = fullfile(outputFolder,sprintf('%s_%03.0f.%s',file,N,ext));
        existing(N) = exist(outFile,'file');
    end
    if any(existing)
        choice = questdlg(sprintf('%s already exists. Overwrite?',outFile),'File exists','Yes','No','No');
        switch choice
            case 'No'
                [fileName,outputFolder] = uiputfile({'*.dcm;*.ima','DICOM files (*.dcm,*.ima)'},'Select output folder and filename',fullfile(outputFolder,fileName));
                continue
            case 'Yes'          % All existing files should be overwritten
                finished = 1;
        end
    else
        finished = 1;
    end
end

ext = fileName(end-2:end);
file = fileName(1:end-4);
fnames = fieldnames(extraHeader);
for N = 1:z2
    HDR = header{N};
    if ~isempty(fnames)
        for ii = 1:length(fnames)
            HDR.(fnames{ii}) = extraHeader.(fnames{ii});
        end
    end
    try
        % Just in case; MATLAB may remove the slope and intercept automatically.
        HDR.RescaleSlope = 1;
        HDR.RescaleIntercept = 0;
    end

    outFile = fullfile(outputFolder,sprintf('%s_%03.0f.%s',file,N,ext));
    dicomwrite(imageMatrix(:,:,N),outFile,HDR);
end
end
