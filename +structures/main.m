% Defining Input Struct
i.MTOW = 20820; % % Maximum Take-Off Weight
i.ZFW = 18600; % Zero Fuel Weight
i.n_max = 2.5; % Load Factor
i.b = 28;  % Wing Span
i.N_sections = 2; % Number of Planform Sections
i.N_airfoils = 2; % Number of Airfoil Sections
i.airfoils.root.loc = 0; i.airfoils.root.name = 'root';
i.airfoils.tip.loc = 1; i.airfoils.tip.name = 'tip';

i.sections.root.chord = 3.5;
i.sections.root.x = 0;
i.sections.root.y = 0;
i.sections.root.z = 0;
i.sections.root.fs = 0.2;
i.sections.root.rs = 0.8;

i.sections.tip.chord = 0.25 * i.sections.root.chord;
i.sections.tip.x = i.b/2 * sind(5);
i.sections.tip.y = i.b/2;
i.sections.tip.z = 0;
i.sections.tip.fs = 0.2;
i.sections.tip.rs = 0.8;

i.A = (i.sections.root.chord + i.sections.tip.chord) * i.b / 2; % Wing Area


i.fuel_start = 0.1; i.fuel_end = 0.7; % Fuel Tank Start End 2y/b
i.engine_spec = [0.25, 3000];
i.N_engines = 1; % Number of engines on each wing

%% Material Properties
young = 10e10;
rho = 1.225;
tens = 10e8;
comp = 10e8;

fields = {'top', 'bot', 'front', 'rear'};
for field = fields
    i.box.(field{:}).young = young;
    i.box.(field{:}).rho  = rho;
    i.box.(field{:}).tens = tens;
    i.box.(field{:}).comp = comp;
end

i.eta_panel = 0.97;
i.rib_pitch  = 0.5;

%% Display Option
i.display_option = 0;

structures.initWriter('test', i);
