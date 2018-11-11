function initWriter(name, inputStruct)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
i = inputStruct;
fid = fopen([pwd '\temp\' name '.init'], 'w');
    fprintf(fid, '%g %g\n', i.MTOW, i.ZFW);
    fprintf(fid, '%g \n', i.n_max);
    fprintf(fid, '%g %g %g %g \n', i.A, i.b, i.N_sections, i.N_airfoils);
    
    % Creating Airfoil Location Fields
    for field = fieldnames(i.airfoils)'
      air = i.airfoils.(field{:});
      fprintf(fid, '%g %s \n', air.loc, air.name);
    end
    
    % Creating Planform Sections
    for field = fieldnames(i.sections)'
      sec = i.sections.(field{:});
      disp(sec);
      fprintf(fid, '%g %g %g %g %g %g \n',...
          sec.chord,...
          sec.x,...
          sec.y,...
          sec.z,...
          sec.fs,...
          sec.rs);
    end
    
    % Creating 
    fprintf(fid, '%g %g \n', i.fuel_start, i.fuel_end);
    fprintf(fid, '%d \n', i.N_engines);
    fprintf(fid, '%g %g \n', i.engine_spec); % Another problem area
    
    % Always 4 entries (Upper, Lower, Front, Rear)
    for field = fieldnames(i.box)'
        box = i.box.(field{:});
        fprintf(fid, '%g %g %g %g \n',...
            box.young,...
            box.rho,...
            box.tens,...
            box.comp);
    end
    
    fprintf(fid, '%g %g \n', i.eta_panel, i.rib_pitch);
    fprintf(fid, '%d', i.display_option);
end

