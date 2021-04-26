%% prt_predict
% writes file predict_my_pet.m 

%%
function [auxParFld, info] = prt_predict(par, metaPar, data, auxData, metaData)
% created 2020/06/02 by  Bas Kooijman

%% Syntax
% [auxParFld, info] = <../prt_predict.m *prt_predict*> (par, metaPar, data, auxData) 

%% Description
% Writes file predict_my_pet.m from pars, data, auxData and metaData. Uses code as specified in predict.mat
%
% Input:
%
% * par: structure with parameters (from pars_init)
% * metaPar: structure with meta parameters (from pars_init)
% * data: structure with data (from mydata)
% * auxData: structure with auxiliary data (from mydata)
% * metaData: structure with meta data (from mydata)
%
% Output:
%
% * auxParFld: cell string with names of auxiliary parameters that are used
% * info: boolean for success of filling all code (1), or failure (0)

%% Remarks
% The file will be saved in your local directory; 
% use the cd command to the dir of your choice BEFORE running this function to save files in the desired place.
%
% Structure prdCode has model name as first field names
%
% * Field res has the name of output variable for zero-variate field names or header text for uni-variate data
% * Field aux has the cell string with auxPar for that code.
% * Other fields under the model field are names of variables with a cell string of code, each cell containg one code line
% * The name of a univariate data set is called fldi in the code; it will be back-substituded before printing
% * Remove fields with: prdCode.std = rmfield(prdCode.std, 'Li');
% * Rename fields with: prdCode.std = renameStructField(prdCode.std, 'l_i', 'L_i'); 
% * Reorder fields with: prdCode = orderfields(prdCode, cell string with ordered fld names)
% * Modify code-line i of variable tWw with: prdCode.std.tWw{i} = 'something';
% * Save: WD = cdPet; save('prdCode.mat','prdCode'); cd(WD) 
% * Save: WD = cdPet; save('auxPar.mat','auxPar'); cd(WD)
%
% The intended use of this function in the context of AmPeps
%  
% * first compose a mydata-file
% * copy-paste-modify a pars_init file of a related AmP species
% * use the outputs of the pars_init and mydata files as inputs of this function to write a predict-file
% * modify the aux parameters of pars_init file to the needs of this predict-file using mat2pars_init
% * use prt_run_my_pet to write a run-file
% * finally: you are ready to start the estimation procedure

auxParFld = {}; model = metaPar.model; my_pet = metaData.species; 
load prdCode

fid = fopen(['predict_', metaData.species, '.m'], 'w+'); % open file for reading and writing, delete existing content
fprintf(fid, 'function [prdData, info] = predict_%s(par, data, auxData)\n', my_pet);
fprintf(fid, '%% file generated by prt_predict\n\n');

%% unpack par, data, auxData
fprintf(fid, '%% unpack par, data, auxData\n');
fprintf(fid, 'cPar = parscomp_st(par); vars_pull(par);\n'); 
fprintf(fid, 'v2struct(par); v2struct(cPar); v2struct(data); v2struct(auxData);\n\n'); 
    
cPar = parscomp_st(par); vars_pull(par);
v2struct(par); v2struct(cPar); v2struct(data); v2struct(auxData);

% filters
% if exist('E_Hh','var')
%   fprintf(fid, 'if E_Hh < 0 || E_Hh > E_Hb\n');
%   fprintf(fid, '  prdData = []; info = 0; return\n');
%   fprintf(fid, 'end\n\n');
% end
%
% if exist('E_Hx','var') && ~strcmp(metaPar.model, 'stx')
%   fprintf(fid, 'if E_Hx < E_Hb || E_Hx > E_Hp\n');
%   fprintf(fid, '  prdData = []; info = 0; return\n');
%   fprintf(fid, 'end\n\n');
% end

% split zero- from uni-variate data
fld = fieldnames(data); fld = fld(~strcmp(fld, 'psd')); n_fld = length(fld); sel = false(n_fld,1);
for i = 1:n_fld
  sel(i) = size(data.(fld{i}),1) > 1;
end
fld0 = fld(~sel); fld1 = fld(sel); n_0 = length(fld0); n_1 = length(fld1);

%% compute temperature correction factors
fprintf(fid, '%% compute temperature correction factors\n');
if exist('T_L','var') && exist('T_H','var')
  fprintf(fid, 'pars_T = [T_A, T_L, T_H, T_AL, T_AH];\n');
elseif exist('T_AH','var') 
  fprintf(fid, 'pars_T = [T_A, T_H, T_AH];\n');
elseif exist('T_AL','var') 
  fprintf(fid, 'pars_T = [T_A, T_L, T_AL];\n');
else
  fprintf(fid, 'pars_T = T_A;\n');
end
for i = 1:n_fld
  if isfield(temp, fld{i})
    fprintf(fid, 'TC_%s = tempcorr(temp.%s, T_ref, pars_T);\n', fld{i}, fld{i});
  end
end
fprintf(fid, '\n');

%% zero-variate data

% life cycle
fprintf(fid, '%% life cycle\n');
if strcmp(model,'std') && isfield(data, 'tR')
  fprintf(fid, '%s', cell2str(prdCode.(model).lcR));
  auxParFld = [auxParFld, 't_N'];
else
  fprintf(fid, '%s', cell2str(prdCode.(model).lc));
end
fprintf(fid, '\n');

fprintf(fid, 'if info == 0\n');
fprintf(fid, '  prdData = []; return;\n');
fprintf(fid, 'end\n\n');

% initial
fld_0 = {'E0', 'Ww0', 'Wd0', 'Wwh', 'Wdh', 'Lh'}; % fields for section initial
sel_0 = ismember(fld0,fld_0);
if any(sel_0)
  fprintf(fid, '%% initial\n');
  fld_0 = fld_0(ismember(fld_0,fld0)); n_fld0 = length(fld_0);
  if any(ismember(fld_0, {'E0', 'Ww0', 'Wd0'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).U_E0));
  end
  for i = 1:n_fld0
    if isfield(prdCode.(model), fld_0{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_0{i})));
    end
  end
  fprintf(fid, '\n');
end

% hatch
fld_h = {'ah', 'Lh', 'Wwh', 'Wdh'}; % fields for section hatch
sel_h = ismember(fld0,fld_h);
if any(sel_h)
  fprintf(fid, '%% hatch\n');
  fld_h = fld_h(ismember(fld_h,fld0)); n_fldh = length(fld_h);
  if any(ismember(fld_0, {'ah', 'Lh', 'Wwh', 'Wdh'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).U_E0));
    fprintf(fid, '%s', cell2str(prdCode.(model).aUL_h));
  end
  for i = 1:n_fldh
    if isfield(prdCode.(model), fld_h{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_h{i})));
    end
  end
  fprintf(fid, '\n');
end

% birth
fld_b = {'ab', 'Lb', 'Wwb', 'Wdb'}; % fields for section birth
sel_b = ismember(fld0,fld_b);
if any(sel_b)
  fprintf(fid, '%% birth\n');
  fld_b = fld_b(ismember(fld_b,fld0)); n_fldb = length(fld_b);
  if any(ismember(fld_b, {'Lb', 'Wwb', 'Wdb'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_b));
  end
  for i = 1:n_fldb
    if isfield(prdCode.(model), fld_b{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_b{i})));
    end
  end
  fprintf(fid, '\n');
end

% Leptocephalus stage
fld_s = {'ts', 'Ls', 'Wws', 'Wds'}; % fields for section S1/S2 transition
sel_s = ismember(fld0,fld_s);
if any(sel_s) && strcmp(model, 'ssj')
  fprintf(fid, '%% S1/S2 transition\n');
  fprintf(fid, '%s', cell2str(prdCode.ssj.tl_s));
  fld_s = fld_s(ismember(fld_s,fld0)); n_flds = length(fld_s);
  if any(ismember(fld_s, {'Ls', 'Wws', 'Wds'}))
    fprintf(fid, '%s', cell2str(prdCode.ssj.L_s));
  end
  for i = 1:n_flds
    if isfield(prdCode.(model), fld_s{i})
      fprintf(fid, '%s', cell2str(prdCode.ssj.(fld_s{i})));
    end
  end
  fprintf(fid, '\n');
end

% fledging/weaning 
fld_x = {'tx', 'Lx', 'Wwx', 'Wdx'}; % fields for section fledging/weaning
sel_x = ismember(fld0,fld_x);
if any(sel_x)
  fprintf(fid, '%% fledging/weaning\n');
  fld_x = fld_x(ismember(fld_x,fld0)); n_fldx = length(fld_x);
  if any(ismember(fld_x, {'Lx', 'Wwx', 'Wdx'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_x));
  end
  for i = 1:n_fldx
    if isfield(prdCode.(model), fld_x{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_x{i})));
    end
  end
  fprintf(fid, '\n');
end

% instars (for ecdysozoans)
fld_in = {'t1','t2','t3','t4','t5','t6','L1','L2','L3','L4','L5','L6','Ww1','Ww2','Ww3','Ww4','Ww5','Ww5','Wd1','Wd2','Wd3','Wd4','Wd5','Wd6',}; % fields for section instars
sel_in = ismember(fld0,fld_in);
if any(sel_in)
  fprintf(fid, '%% instars\n');
  fld_in = fld_in(ismember(fld_in,fld0)); n_fldin = length(fld_in);
  for i = 1:n_fldin
    if isfield(prdCode.(model), fld_in{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_in{i})));
    end
  end
  fprintf(fid, '\n');
end

% metamorphosis/pupation 
fld_j = {'tj', 'Lj', 'Wwj', 'Wdj'}; % fields for section metamorphosis
sel_j = ismember(fld0,fld_j);
if any(sel_j)
  if strcmp(metaPar.model,'hex')
    fprintf(fid, '%% pupation\n');
  else
    fprintf(fid, '%% end of acceleration\n');
  end
  fld_j = fld_j(ismember(fld_j,fld0)); n_fldj = length(fld_j);
  if any(ismember(fld_j, {'Lj', 'Wwj', 'Wdj'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_j));
  end
  for i = 1:n_fldj
    if isfield(prdCode.(model), fld_j{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_j{i})));
    end
  end
  fprintf(fid, '\n');
end

% puberty
fld_p = {'tp', 'Lp', 'Wwp', 'Wdp'}; % fields for section puberty
sel_p = ismember(fld0,fld_p);
if any(sel_p)
  fprintf(fid, '%% puberty\n');
  fld_p = fld_p(ismember(fld_p,fld0)); n_fldp = length(fld_p);
  if any(ismember(fld_p, {'Lp', 'Wwp', 'Wdp'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_p));
  end
  for i = 1:n_fldp
    if isfield(prdCode.(model), fld_p{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_p{i})));
    end
  end
  fprintf(fid, '\n');
end

% emergence
fld_e = {'te', 'Le', 'Wwe', 'Wde'}; % fields for section emergence
sel_e = ismember(fld0,fld_e);
if any(sel_e)
  fprintf(fid, '%% emergence\n');
  fld_e = fld_e(ismember(fld_e,fld0)); n_flde = length(fld_e);
  if any(ismember(fld_e, {'Le', 'Wwe', 'Wde'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_e));
  end
  for i = 1:n_flde
    if isfield(prdCode.(model), fld_e{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_e{i})));
    end
  end
  fprintf(fid, '\n');
end

% ultimate
fld_i = {'Li', 'Wwi', 'Wdi', 'am'}; % fields for section ultimate
sel_i = ismember(fld0,fld_i);
if any(sel_i)
  fprintf(fid, '%% ultimate\n');
  fld_i = fld_i(ismember(fld_i,fld0)); n_fldi = length(fld_i);
  if any(ismember(fld_i, {'Li', 'Wwi', 'Wdi'}))
    if isfield(prdCode.(model), 'L_i')
      fprintf(fid, '%s', cell2str(prdCode.(model).L_i));
    elseif strcmp(model, 'hex')
      fprintf('Warning from AmPeps: field L_i encountered in model hex; this should have been L_e \n');
    end
  end
  for i = 1:n_fldi
    if isfield(prdCode.(model), fld_i{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_i{i})));
    end
  end
  fprintf(fid, '\n');
end

% reproduction
fld_R = {'Ri', 'tR', 'GSI'}; % fields for section reproduction
sel_R = ismember(fld0,fld_R);
if any(sel_R)
  fprintf(fid, '%% reproduction\n');
  fld_R = fld_R(ismember(fld_R,fld0)); n_fldR = length(fld_R);
  for i = 1:n_fldR
    if isfield(prdCode.(model), fld_R{i})
      fprintf(fid, '%s', cell2str(prdCode.(model).(fld_R{i})));
    end
  end
  fprintf(fid, '\n');
end

% males
fld_m = {'tpm', 'Lpm', 'Lim', 'Wwpm', 'Wdpm', 'Wwim', 'Wdim', 'tWw_m', 'tWd_m', 'tL_m', 'LdL_m'}; % fields for section males
sel_m = ismember(fld0,fld_m);
if any(sel_m) || any(ismember(fld1,fld_m))
  fprintf(fid, '%% males\n');
  fprintf(fid, '%s', cell2str(prdCode.(model).L_mm));
  fld_m = fld_m(ismember(fld_m,fld0)); n_fldm = length(fld_m);
  if any(ismember(fld_m, {'tpm', 'Lpm', 'Wwpm', 'Wdpm'}))
    fprintf(fid, '%s', cell2str(prdCode.(model).L_pm));
  end
  for i = 1:n_fldm
    fprintf(fid, '%s', cell2str(prdCode.(model).(fld_m{i})));
  end
  fprintf(fid, '\n');
end

% remaining zero-variate fields
sel_0 = any([sel_0, sel_h, sel_b, sel_x, sel_j, sel_in, sel_p, sel_i, sel_R, sel_m, sel_e], 2); 
rfld0 = fld0(~sel_0); n_rfld0 = length(rfld0);
if n_rfld0 > 0
  fprintf(fid, '%% Warning: The following zero-variate data fields were not recognized\n');
  for i = 1:n_rfld0
    fprintf(fid, '%s = ;\n', rfld0{i});
  end
  fprintf(fid, '\n');
end

%% pack to output
fprintf(fid, '%% pack to output\n');
for i = 1:n_0
   if ismember(fld0{i}, rfld0)
     fprintf(fid, 'prdData.%s = ;\n', fld0{i});
   else
     if isfield(prdCode.res, fld0{i})
       fprintf(fid, 'prdData.%s = %s;\n', fld0{i}, prdCode.res.(fld0{i}));
     end
   end
end
fprintf(fid, '\n');

%% uni-variate data
sel_1 = true(n_1,1);
for i = 1:n_1
  try
    fldi = fld1{i}; sep = strfind(fldi, '_'); 
    if isempty(sep)
      fld = fldi; fld_index = []; % data-type 
    else
      sep1 = sep(1); sep = sep(end);
      fld = fldi(1:sep1-1); % data-type
      fld_index = fldi(sep+1:end); % data index
    end
    if strcmp(fld_index,'m')
      fld = [fld, '_m'];
    end
    code = cell2str(prdCode.(model).(fld));
    code = strrep(code, 'fldi', fldi); % replace data index
    if isempty(fld_index)
      code = strrep(code, [fld, '_'], fld); % remove underscore of fld
    end
    fprintf(fid, '%% %s\n', prdCode.res.(fld));
    fprintf(fid, '%s', code);
  catch
    sel_1(i) = false;
  end
  fprintf(fid, '\n');
end

% remaining uni-variate fields
rfld1 = fld1(~sel_1); n_rfld1 = length(rfld1);
if n_rfld1 > 0
  fprintf(fid, '%% Warning: The following uni-variate data fields were not recognized\n');
  for i = 1:n_rfld1
    fprintf(fid, '%s = ;\n', rfld1{i});
  end
  fprintf(fid, '\n');
end

%% pack to output
fprintf(fid, '%% pack to output\n');
for i = 1:n_1
   if ismember(fld1{i}, rfld1)
     fprintf(fid, 'prdData.%s = ;\n', fld1{i});
   else
     fprintf(fid, 'prdData.%s = %s;\n', fld1{i}, fld1{i});
   end
end
fprintf(fid, '\n');

fclose(fid);

% auxParFld
fld = [fld0(sel_0); fld1(sel_1)]; n_fld = length(fld); 
for i =1:n_fld
  if isfield(prdCode.aux, fld{i})
    auxParFldi = prdCode.aux.(fld{i});
    auxParFld = [auxParFld; auxParFldi(:)];
  end
end
auxParFld = unique(auxParFld);
info = n_rfld0 == 0 && n_rfld1 == 0;

end

function strOut = cell2str(cellIn)
  n = length(cellIn); strOut = '';
  for i=1:n
    x = cellIn{i};
    if iscell(x)
      x = x{1};
    end
    strOut = [strOut, x, char(10)];
  end
end
