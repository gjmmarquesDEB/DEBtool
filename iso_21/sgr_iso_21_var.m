%% sgr_iso_21_var
% specific growth rate for isomorph with 2 reserves 

%%
function [r, j_E1_S, j_E2_S, j_E1C, j_E2C, j_E1P, j_E2P, mode] = ...
    sgr_iso_21_var (m_E1, m_E2, j_E1S, j_E2S, mu_E1, mu_E2, mu_V, k_E, kap)
  % created: 2012/03/07 by Bas Kooijman, modified 2023/07/17
  
  %% Syntax
  % [r, j_E1_S, j_E2_S, j_E1C, j_E2C, j_E1P, j_E2P, mode] = <../sgr_iso_21_var.m *sgr_iso_21_var*> (m_E1, m_E2, j_E1S, j_E2S, mu_E1, mu_E2, mu_V, k_E, kap_G, kap) 

  %% Description
  % specific growth rate for isomorph with 2 reserves, allowing for shrinking and variable stoichiometry
  % Growth investment has a fixed stoichiometry for the anabolic part, but a variable one for the catabolic part (= overheads)
  %
  % Input:
  %
  % * m_E1, m_E2:   mol/mol,   scalars with reserve density
  % * j_E1S, j_E2S: mol/d.mol, scalars with spec maintenance flux if from reserve
  % * mu_E1, mu_E2, mu_V:  -,  scalars with chem potential for reserve 1, 2, structure
  % * k_E:  1/d,               scalar with reserve turnover rate v/ L
  % * kap: -,                  scalar with allocation fraction to soma
  %
  % Output:
  %
  % * r: 1/d,                  scalar with spec growth rate
  % * j_E1_S, j_E2_S: mol/d.mol, scalars with  spec som maintenance flux
  % * j_E1C, j_E2C: mol/d.mol, scalars with mobilised flux of reserves
  % * j_E1P, j_E2P: mol/d.mol, scalars with rejected flux of reserves
  % * mode: -,                 scalar for case indicator (1,2,3,4)
  
  %% remarks
  % spec growth rate r = j_VG and kap_G = mu_V*j_VG/ (\sum_i mu_Ei*(kap j_EiC-j_EiS)))
  % at max size, where r = 0 (and kap_G = 0):
  %  mode 1 can only occur if m_E1 = 0 and L_m is not well defined
  %  mode 2 L_m = kap * v * (mu_E1 * m_E1 + mu_E2 * m_E2)/ (mu_E2 * j_E2S);
  %  mode 3 L_m = kap * v * (m_E1/ j_E1S + m_E2/ j_E2S);
  %  mode 4 only applies when shrinking
  %  if mu_E1 = mu_E2 = mu_E and m_E1 = m_E2 = m_E: L_m = kap * v * 2 * m_E / j_ES
  
  % identify mode
  j_E1C = k_E * m_E1; j_E2C = k_E * m_E2; % mol/d.mol mobilisation rates if r = 0
  if kap * j_E2C < j_E2S && kap * j_E1C < j_E1S * (1 - kap * j_E2C/ j_E2S)
    mode = 4;
  else
    r = mu_E1 * kap * m_E1 * k_E/ (mu_V + mu_E1 * kap * m_E1);  % 1/d, specific growth rate if mode = 1
    j_E1C = (k_E - r) * m_E1; j_E2C = (k_E - r) * m_E2; % mol/d.mol mobilisation rates if mode = 1
    j_E1G = kap * j_E1C; j_E2G = kap * j_E2C - j_E2S;   % mol/d.mol growth allocations if mode = 1
    kap_G = mu_V * r/ (mu_E1 * (kap * j_E1C - j_E1S) + mu_E2 * (kap * j_E2C - j_E2S)); % -, growth efficiency
    if kap_G * mu_E2 * j_E2G > (1 - kap_G) * mu_E1 * j_E1G && kap * j_E2C > j_E2S
      mode = 1;
    else 
      mm = mu_E1 * m_E1 + mu_E2 * m_E2;
      r = (kap * mm * k_E - mu_E2 * j_E2S)/ (kap * mm + mu_V/ kap_G); % 1/d, specific growth rate if mode = 2
      j_E2C =  (k_E - r) * m_E2;       % mol/d.mol, specific mobilisation rates
      if kap * j_E2C > j_E2S
        mode = 2;
      else
        mode = 3;
      end
    end
  end

  % compute fluxes, given mode
  switch mode
    case 1 % reserve 2 fuels all maintenance and growth overheads
      r = mu_E1 * kap * m_E1 * k_E/ (mu_V + mu_E1 * kap * m_E1);   % 1/d, specific growth rate
      j_E1C =  (k_E - r) * m_E1; j_E2C =  (k_E - r) * m_E2;        % mol/d.mol, specific mobilisation rates
      j_E2_S = min(kap * j_E2C, j_E2S); j_E1_S = min(kap * j_E1C, j_E1S * (1 - j_E2_S/ j_E2S)); % mol/d.mol specific som maint rates
      j_E2G = kap * j_E2C - j_E2_S;                                % mol/d.mol, specific growth rate
      j_E1P = 0; j_E2P = j_E2G - r * (1/ kap_G - 1) * mu_V/ mu_E2; % mol/d.mol, specific rejection flux

    case 2 % reserve 2 can fuel all somatic maintenance, but reserve 1 pays part of growth overhead
      j_E1_S = 0; % mol/d.mol, spec som maintenance paid by res 1
      j_E2_S = j_E2S; % mol/d.mol, spec som maintenance paid by res 2
      mu_E12 = mu_E1 * m_E1 + mu_E2 * m_E2; % J/mol, total reserve energy per mol structure
      r = (kap * mu_E12 * k_E - mu_E2 * j_E2S)/ (kap * mu_E12 + mu_V/ kap_G); % 1/d, specific growth rate
      j_E1C = (k_E - r) * m_E1; j_E2C = (k_E - r) * m_E2;         % mol/d.mol, specific mobilisation rates
      j_E1P = 0; j_E2P = 0;                                       % mol/d.mol, specific rejection flux
          
    case 3 % reserve 1 can fuel all somatic maintenance and pays all growth overhead
      m_E12 = m_E1 + m_E2 * j_E1S/ j_E2S;                         % mol/mol, total mol of reserve density
      r = (m_E12 * kap * k_E - j_E1S)/ (m_E12 * kap + mu_V/ kap_G/ mu_E1); % 1/d, specific growth rate
      j_E1C =  (k_E - r) * m_E1; j_E2C =  (k_E - r) * m_E2;       % mol/d.mol, specific mobilisation rates
      j_E2_S = kap * j_E2C;
      j_E1_S = j_E1S * (1 - j_E2_S/ j_E2S);
      j_E1P = 0; j_E2P = 0;
    
    case 4 % structure pays part of somatic maintenance
      mm = m_E1/ j_E1S + m_E2/ j_E2S; jmu = j_E1S * mu_E1/ mu_V;
      r = - jmu * (1 - kap * k_E * mm)/ (1 + kap * jmu * mm); % 1/d, specific growth rate
      j_E1C =  (k_E - r) * m_E1; j_E2C =  (k_E - r) * m_E2;   % mol/d.mol, specific mobilisation rates
      j_E2_S = kap * j_E2C;
      j_E1_S = kap * j_E1C;
      j_E1P = 0; j_E2P = 0;                                   % mol/d.mol, specific rejection flux    
  end
 
end
