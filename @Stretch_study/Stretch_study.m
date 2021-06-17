% #############    Creates mr_study object v. 1.0     ###################||
% mode input:
%   - 'manual' - Manual selection of files
%   - 'plot' - Manual selection of files; Plots output, fits etc.
%   - 'test' - Evaluates test dataset under 'Testdatensatz/stretch'
%   - a cell array of files to include

% MR_study_data is designed to provide a convenient way to work with processed data from a whole Microrheology study
% - One-file-storage avoids file and path chaos
% - Raw and processed data stored together; Raw is immutable and processing happens in multiple steps. 
%   If basic data changed, subsequent Data get deleted
% - Data is stored in tables with metadata like Calibration constants or processing options (e.g. MSD corrections)
% - Data can be accessed via methods that yield particle oriented data; When data structure gets changed only access methods 
%   need to be changed
% - Changes in code -> Data can easily be compared by isequal(obj1, obj2)

classdef Stretch_study
   properties (SetAccess = immutable)
       time_min double
       spot_nr double
       MPT cell
   end
   properties
       cal table
       stretch table
       MSD_prestretch table
       tracked table
       meta (1,1) struct
       custom_parms table
   end
   methods
       
       % ################# Constructor -- collects all MPT-files from a study and combines them into one MR_study_data object array ############## %
       % selection_mode: 1st option: <variable contining cell array of MPT paths>; Consider using mr_study_print_filelist(mr_study_data) 
       %                 2nd option: 'manual'; 
       %                 3rd option: 'pattern', recursive regex search; 
       function obj = Stretch_study(mode)
           % This enables to initialize an object array
           if nargin~=0
               
            % ==================== Get file names ========================%
            addpath('C:\Users\Alexander\Desktop\Programmieren\allg_Skripte');
            addpath('C:\Users\Alexander\Desktop\Programmieren\MR_Evaluation\Skripte_Jonas');
            bool_test = 0;
            % Manual selection of all measurements of a dataset
            if strcmp(mode, 'manual') || strcmp(mode, 'plot')
                folder_list = MPT_lib.select_filenames_return_cell(uigetdir('C:\CAOS_Data\raw_data', 'Select path containing measurements'), '*.*', 'multiple');
                if strcmp(mode, 'plot')
                    bool_test = 1; 
                end
            elseif strcmp(mode, 'test')
                % One reference dataset to compare script changes
                folder_list = {}; for i = 1:10, folder_list{i} = fullfile('Testdatensatz', sprintf('stretch%.0f', i)); end
                globalcalxy = 11.64; ramp = [1.5 0.6]; review_info = {'>= 1 bead above or apparently in contact with nucleus'};
                bool_test = 1;
            else
                folder_list = mode;
            end
            
            % ====================== Measurement Parameter input ==========================%
            if ~strcmp(mode, 'test')
                review_info = inputdlg('Comment on cell / bead celection');            
                if strcmp(questdlg('Same calibration constant for all measurements?'), 'Yes')
                    globalcalxy = str2double(inputdlg('Enter cal const [px/µm] for all measurements'));
                else
                    globalcalxy = [];
                end
                if strcmp(questdlg('Same z ramp for all measurements?'), 'Yes')
                    ramp = str2double(inputdlg({'Enter z ramp frequency', 'Enter Delta z'}));
                else
                    ramp = [];
                end
            end
            
            % Preallocation of object array with last element. One element represents one measurement.
            obj(size(folder_list, 2), 1) = obj;
            
            % =============   Iterate over measurements included =============== %
            for i = 1:length(obj)
               % Metadata
               obj(i).meta.manual_review = review_info{1};
               obj(i).meta.filename = folder_list{1,i};
               % Raw data
               obj(i).MPT = velomir_to_MPT(folder_list{1, i}, 'calibrationxy', globalcalxy, 'ramp', ramp);
               % Contains only unphysical or lost particles
               tracked = cellfun(@(x) ~isempty(x), obj(i).MPT);
               obj(i).tracked = array2table(tracked, 'VariableNames', MPT_lib.get_particle_names(1:size(obj(i).MPT, 2)));
               obj(i).tracked.Properties.Description = 'Bool of whether particles have been successfully tracked and no MSD jumps > factor of 2';
            end
            % First 3 s before stretching used for MSD calculation; Also creates 'tracked' boolean table with meaningful particles and removes oscillating particles (MSD x2),           
            obj = obj.arbitrary_calibration(bool_test);
            
            % !!! Kriterium beim Fitkurven auswählen: Startintensität
            % deutlich < Kurve -> raus
            
            % Removes particles with no linear r over Deltaz relationship
            % obj(i).tracked{1,:} = obj(i).tracked{1,:} & (obj(i).cal{1,:}~=0);
            disp('Included files:');
            obj.print_filelist();
            end
       end
       % ===========================  METHODEN ===========================%
        % TO BE ADDED: SET PROPERTY METHODS -> GET EXECUTET WHEN PROPERT IS ACCESSED; IF MSD ACCESSED -> G ETC DELETED
        % Adding content to stretch_study
        obj = calc_MSD(obj, varargin);
        obj = linear_calibration(obj);
        obj = arbitrary_calibration(obj, bool_test);
        obj = brightness_z_calibration(obj);
        obj = fit_stretching(obj);
        obj = add_custom_parms(obj);
        %obj = fit_stretching(obj);
        
%         imean = mean_greylevel(obj);
%         obj = add_custom_parms(obj, excel_file);
%         obj = add_particle_parms(obj, parm_name);
%         obj = MSD_statcorr(obj, a, b, noise);
%         
%         % Retrieve data for each particle
%         radii = mean_radii(obj, warn);
%         J = mean_Js(obj, warn, frames_to_avg);
%         brightnesses = mean_brightnesses(obj, warn);
%         meas_nrs = retrieve_measurement_nrs(obj);
%         meas_names = retrieve_measurement_names(obj);
%         custom_parm_5 = retrieve_custom_parms(obj, parm_nr);
%         parm = retrieve_particle_parms(mr_study, parm_name);
%         timevecs = retrieve_timevecs(obj, varargin);
%         MSDs = retrieve_MSDs(obj, varargin);
%         meas_times = retrieve_times(obj);
%         MSDs = retrieve_MSDs_statcorr(obj);
        
        obj = plot_MSDs(obj, NameValueArgs);
        
        % Prints list of MPT-files in the order of the elements in mr_study_data
        filelist = print_filelist(obj)
        
   end
   % Used by the constructor to create object
   methods(Static)
       
   end
end