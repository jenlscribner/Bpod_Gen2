function UpdateBpodSoftware
warning off
% Check for compatible system
if verLessThan('MATLAB', '8.4')
    error(['Error: The automatic updater requires MATLAB r2014b or newer. ' char(10)...
        'Update your software manually, following the instructions <a href="matlab:web(''https://sites.google.com/site/bpoddocumentation/software-update'',''-browser'')">here</a>.'])
end
if ~ispc
    error(['Error: The automatic updater does not yet work on OSX or Linux. ' char(10)...
        'Update your software manually, following the instructions <a href="matlab:web(''https://sites.google.com/site/bpoddocumentation/software-update'',''-browser'')">here</a>.'])
end

% Check for open Bpod
try
    evalin('base', 'BpodSystem;'); % BpodSystem is a global variable in the base workspace, representing the hardware
    isEmpty = evalin('base', 'isempty(BpodSystem);');
    if isEmpty
        evalin('base', 'clear global BpodSystem;')
    else
        error('Cannot update while Bpod is open. Please close the Bpod console and try again.');
    end
catch
end

% Create paths        
BpodPath = fileparts(which('Bpod'));
Path = struct;
Path.BpodRoot = BpodPath;
Path.ParentDir = fileparts(BpodPath);
Path.LocalDir = fullfile(Path.ParentDir, 'Bpod Local');
Path.Functions = fullfile(Path.BpodRoot, 'Functions');
addpath(genpath(Path.Functions));
% Check for latest version
Ver = BpodSoftwareVersion;
latestVersion = [];
[reply, status] = urlread(['https://raw.githubusercontent.com/sanworks/Bpod_Gen2/master/Functions/Internal%20Functions/BpodSoftwareVersion.m']);
verPos = find(reply == '=');
if ~isempty(verPos)
    verString = strtrim(reply(verPos(end)+1:end-1));
    latestVersion = str2double(verString);
end
if ~isempty(latestVersion)
    if Ver == latestVersion 
        error(['No update required - you already have the latest stable version of Bpod: v' verString]);
    end
end
BackupDir = fullfile(Path.LocalDir, 'Temp', 'Backup');
disp('----Bpod Software Updater Beta----')
disp(['This app will update your Bpod software from v' num2str(Ver) ' to v' num2str(latestVersion)]);
disp('A backup copy of your current Bpod_Gen2 folder will be made in: ');
disp(BackupDir);
disp(' ');
disp('*IMPORTANT* This update software is a BETA release.')
disp('Please manually back up your Bpod_Gen2 folder and data')
disp('before you try it for the first time! If you prefer to update')
disp('manually, please follow the instructions <a href="matlab:web(''https://sites.google.com/site/bpoddocumentation/software-update'',''-browser'')">here</a>.')
disp(' ');
reply = input('Do you want to proceed with automatic update? (y/n) ', 's');
if lower(reply) == 'y'
    TempDir = fullfile(Path.LocalDir, 'Temp');
    mkdir(TempDir); % Fails silently if it exists
    % Back up current Bpod software
    disp('Backing up current software...')
    BackupDir = fullfile(TempDir, 'Backup');
    mkdir(BackupDir);
    DateInfo = datestr(now, 30); 
    DateInfo(DateInfo == 'T') = '_';
    ThisBackupDir = fullfile(BackupDir, ['Bpod_Backup_' DateInfo]);
    copyfile(Path.BpodRoot, ThisBackupDir);
    disp('Downloading new software...')

    % Download latest master branch
    DownloadDir = fullfile(TempDir, 'Download');
    ZipFilePath = fullfile(DownloadDir, 'Bpod_Gen2.zip');
    mkdir(DownloadDir);
    websave(ZipFilePath, 'http://github.com/sanworks/Bpod_Gen2/archive/master.zip');
    disp('Extracting new software...')
    unzip(ZipFilePath, DownloadDir);
    delete(ZipFilePath);

    % Remove old files from path
    rmpath(genpath(Path.BpodRoot));
    % Delete old files (backed up previously)
    dos_cmd = sprintf( 'rmdir /S /Q "%s"', Path.BpodRoot );
    [st, msg] = system(dos_cmd);
    movefile(fullfile(DownloadDir, 'Bpod_Gen2-master'), fullfile(Path.ParentDir, 'Bpod_Gen2'), 'f');
    SystemPath = fullfile(Path.BpodRoot, 'Functions');
    % Add files back to MATLAB path
    addpath(Path.BpodRoot);
    addpath(genpath(SystemPath));
    disp('Update complete!')
else
    disp('Update canceled. Bpod Software NOT updated.')
end