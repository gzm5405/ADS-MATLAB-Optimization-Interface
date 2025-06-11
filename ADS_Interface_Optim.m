%This script uses the TADS interface, which is licensed under the GNU GPL v3.
%The TADSInterface is called as an external program and does not include or modify it.
%
% TADSInterface: (ADS-MATLAB-Interface) https://github.com/korvin011/ADS-Matlab-Interface
% GNU General Public License v3.0: https://github.com/korvin011/ADS-Matlab-Interface/blob/master/LICENSE
%
% This script itself is licensed under the GNU General Public License v3.0.
% See LICENSE.txt for full details.
% The script helps to call the netlist of the component using Keysight ADS.
% The components can be updated using parametric/ optimization and logs,
% saves and plots results.

function cost = CostFunc(vars,E, area_mode)

    persistent S11_all p_all freq_v log_p first_call

    if isempty(first_call)
    S11_all = [];
    p_all = [];
    log_p = [];
    first_call = true;
    end
    
    %area_limit=2;

    try
        %% 'AnyCompfromADS' parameters
        A  = vars(1);
        B  = vars(2);
        C = vars(3);
        D  = vars(4);
        %E = round(vars(5));  
    
        p = struct('A', A, 'B', B, 'C', C, 'D', D);% 'E', E);
    
        %% ADS
        %
        addpath('C:\******\*************\*************');
        ads = TADSInterface();
        ads.NetlistFile = 'C:\******\********\***********\netlist.log';
        ads.DatasetFile = 'C:\*******\********\***********\*************\************.ds';
        compName = 'AnyCompfromADS';
    
        %% Remove old ds if found
        if exist(ads.DatasetFile, 'file')
            delete(ads.DatasetFile);
            disp('Old dataset deleted.');
        end
    
        %% Read 'AnyCompfromADS' and check design rules (DRC)
        % net = ads.ReadNetlistFile();
        % 'AnyCompfromADS' = net{ads.FindLineWithComponentName(net, 'AnyCompfromADS', '')};
        % F = str2double(regexp('AnyCompfromADS', 'F\s*=\s*([\d\.eE+-]+)', 'tokens', 'once'));
        % G = str2double(regexp('AnyCompfromADS', 'G\s*=\s*([\d\.eE+-]+)', 'tokens', 'once'));
        % H = str2double(regexp('AnyCompfromADS'L, 'H\s*=\s*([\d\.eE+-]+)', 'tokens', 'once'));
        % I = ********;
    
        %% Design Rule Check (Incase of 'AnyCompfromADS') from Topics and Index
        % if I > (***** / H) || E < ****** || ...
        %    G > *** || F > **** * H || ...
        %     cost = 1e6;
        %     return;
        % end
    
        %% Area check  ('AnyCompfromADS' dimensions)
        %'AnyCompfromADSX'  = *****;   
        % 'AnyCompfromADSY' = ******;   
        pW  = E^2 * A * B - C;
        pL = D;
        
        switch area_mode
            case 1
                pW_max = 75;
                pL_max = 75;
            case 2
                '************';
                '************';
            case 3
                '*************';
                '*************';
        end


        if pW > pW_max || pL > pL_max
            warning('****** exceeds 90% of ********* dimensions.');
            cost = 1e6;
            return;
        end
    
        %% Update component parameters
        % fields = fieldnames(param);
        % for i = 1:numel(fields)
        %     value = param.(fields{i});
        %     if strcmp(fields{i}, 'E')
        %         value = round(value);
        %     else
        %         value = round(value * 100) / 100;
        %     end
        %     ads.ChangeComponentParameter(componentName, fields{i}, value, 'double');
        % end

        % Update W, G, Ge, L
        f = fieldnames(p);
        for i = 1:numel(f)
            v = p.(f{i});
            v = round(v * 10) / 10;
            ads.ChangeComponentParameter(componentName, f{i}, v, 'double');
        end

        % update Nd (manual)
        ads.ChangeComponentParameter(componentName, 'E', E, 'double');

        net = ads.ReadNetlistFile();
        ads.WriteNetlistFile(net);
        ads.ReadNetlistFile();
    
        %% Run ADS
        ads.RunSimulation();
        % dumpFilePath = strrep(ads.DatasetFile, '.ds', '_dump.txt');
    
        if exist(ads.DatasetFile, 'file')
            ads.ReadDataset();
            [Z11_sim, freq_sim] = ads.GetVariableAsFunction('Z[1,1]', 'freq');
        else
            warning('File not found');
            cost=1e6;
            return;
        end

        % elseif exist(dumpFilePath, 'file')
        %     [Z11_sim, freq_sim] = extractZ11FromDump(dumpFilePath);
        % else
        %     error('No dataset or dump found');
        % end
    
        %% Load Target and Convert to S11
        target = readmatrix('Target2.dat');
        f_target = target(:, 1);
        Z_target = target(:, 2) + 1i * target(:, 3);
        [~, idx_target_ref] = min(abs(f_target - ************)); % Center frequency
        Zo_target = real(Z_target(idx_target_ref));
    
        S11_target = 20 * log10(abs((Z_target - Zo_target) ./ (Z_target + Zo_target)));
        S11_sim = 20 * log10(abs((Z11_sim - Zo_target) ./ (Z11_sim + Zo_target)));
    
        
        %% 3 Cost calculation over Target (Cost Function Section)
        
        threshold_dB = -10;
        f_center = '**********';
        % you can fill your own cost function
    
    
        %% Logging (after each run)
       
          fprintf(['Nd=%d, L=%.1f, W=%.1f, G=%.1f, Ge=%.1f, ' ...
           '  sim=%.4f, target=%.4f, Cost=%.4f\n'], ...
            E, D, A, B, C, sim, target, cost);
        % 
        log_p = [log_p; E, D, A, B, C, sim, target, cost];
        assignin('base', 'log_params', log_p);
    
    
        %% Store results
        S11_all = [S11_all; S11_sim(:).'];  
        p_all   = [p_all; A, B, C, D, E]; 
    
        if isempty(freq_v)
            freq_v = freq_sim;
        end
    
        assignin('base', 'S11_s_all', S11_all);
        assignin('base', 'p_all', p_all);
        assignin('base', 'freq_v', freq_v);
    
        %% Plot
        figure(); 
        clf;
        set(gcf,'Color','w');
        plot(freq_sim / ****, S11_sim, 'b-', 'LineWidth', 2); hold on;
        plot(f_target / ****, S11_target, 'r--', 'LineWidth', 2);
        grid on;
        xlabel('Frequency');
        ylabel('S_{11} (dB)');
     
         title(sprintf(['Run #%d | AreaMode=%d | E=%d, B=%.1f, A=%.1f, C=%.1f, D=%.1f\n' ...
                       '{sim}=%.4f, {target}=%.4f\n' ...
                       'Cost=%.4f'], ...
                       size(p_all,1), area_mode, E, D, A, B, C, ...
                       sim, target, cost));

        legend('Simulated', 'Target', 'Location', 'best');
        xlim([]);
        xticks();
        ylim([]);
        drawnow;           % realtime updating the plot
        pause(0.5);       
    
        if ~exist('plot', 'dir')
            mkdir('plot');
        end

        filename = sprintf('plot/S11_Run%d_Mode%d_E%d_A%.1f_B%.1f_C%.1f_De%.4f_C%.2f.png', ...
            size(p_all,1), area_mode, E, D, A, B, C, cost);
        saveas(gcf, filename);
    
        saveas(gcf, filename);

    catch ME
        warning('Error in cost function: %s', ME.message);
        cost = 1e6;
    end

end


