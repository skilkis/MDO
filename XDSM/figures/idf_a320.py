from XDSM.pyXDSM.pyxdsm.XDSM import XDSM


#
opt = 'Optimization'
solver = 'MDA'
comp = 'Analysis'
group = 'Metamodel'
func = 'Function'

x = XDSM()
math = XDSM.math


def zero(tex):
    """ Convenience function to format initial values """
    return r'{}^{{\left(0\right)}}'.format(tex)


# Main System Blocks:
x.add_system('opt', opt, (r'0, 3 $\rightarrow$ 1:', 'Optimization'))
x.add_system('A', comp, ('1:', 'Aerodynamics'))
x.add_system('S', comp, ('1:', 'Structures'))
x.add_system('L', comp, ('1:', 'Loads'))
x.add_system('P', comp, ('1:', 'Performance'))

# Objective Function:
x.add_system('obj', func, ('2: Objective', r'$f(W_f) = - W_f$'))

# Constraints:
x.add_system('fuel', func, ('2: Ineq. Constraint', r'$\frac{W_f}{\rho_f} - V_t \leq 0$'))
x.add_system('wing', func, ('2: Ineq. Constraint', r'$\frac{W_\text{TO}\left(\overline{x}\right)}'
                                                   r'{S\left(\overline{x}\right)} - \left(\frac{W_\text{TO}}{S}\right)^'
                                                   r'{\left(0\right)} \leq 0$'))
x.add_system('spar', func, ('2: Ineq. Constraint', r'$FS_\text{fus,min} - FS_\text{fus} \leq 0$'))
x.add_system('G_load', func, ('2: Consistency', r'$\sum_{i=1}^{N}\sum_{y=0}^{b/2}\left('
                                                r'\zeta_i\left(\frac{2y}{b} \right ) - '
                                                r'\Psi_i\left(y\right )\right )^2 = 0$'))
x.add_system('G', func, ('2: Consistency', r'$\hat{x}_i - x_i = 0$'), stack=True)

# Inputs from Reference Data:
x.add_input('opt', (r'$\zero{\Lambda_1}, \zero{\Lambda_2}, \zero{b}, \zero{c_r}, \zero{\tau},$',
                    r'$\zero{A_\text{root}}, \zero{A_\text{tip}}, \zero{\beta_\text{root}},$',
                    r'$\zero{\beta_\text{kink}}, \zero{\beta_\text{tip}}, \zero{\hat{A}_L}, \zero{\hat{A}_M},$',
                    r'$\zero{\hat{N_L}}, \zero{\hat{N_M}}, \zero{\hat{W}_w}, \zero{\hat{W}_f}, \zero{\hat{C}_{D_w}}$'))
x.add_input('A', (r'$W_{A\text{-}W}, h_c, M_c, d_\text{TE}$', r'$a_c, \rho_c, \mu_c, N_1, N_2, g$'))
x.add_input('S', (r'$W_{A\text{-}W}, W_e, \eta_\text{max}, FS, RS,$', r'$\rho_c, N_1, N_2, D_\text{fus}, d_\text{rib},'
                                                                      r' d_\text{TE}$',
                  r'$E_\text{al}, \sigma_\text{y,c}, \sigma_\text{y,t}, \rho_\text{al} $'))
x.add_input('L', (r'$W_{A\text{-}W}, \eta_\text{max}, h_c,$', r'$M_c, a_c, \rho_c, \mu_c$', r'$N_1, N_2, g, '
                                                                                            r'd_\text{TE}$'))
x.add_input('P', (r'$W_{A\text{-}W}, d_\text{TE}, R_c,$', r'$\rho_c, V_c, C_T$'))
x.add_input('fuel', r'$\rho_f$')
x.add_input('wing', (r'$W_{A\text{-}W}, d_\text{TE},$', r'$\left(\frac{W_\text{TO}}{S}\right)^{\left(0\right)}$'))
x.add_input('spar', r'$FS_\text{fus,min}, d_\text{TE}$')

# Optimizer Connections
x.connect('opt', 'A', (r'1: $\Lambda_1, \Lambda_2, b, c_r, \tau,$',
                       r'$A_\text{root}, A_\text{tip}, \beta_\text{root},$',
                       r'$\beta_\text{kink}, \beta_\text{tip}, \hat{W}_w, \hat{W}_f$'))
x.connect('opt', 'S', (r'1: $\Lambda_1, \Lambda_2, b, c_r, \tau,$',
                       r'$A_\text{root}, A_\text{tip}, \hat{W}_w, \hat{W}_f$',
                       r'$\hat{A}_L, \hat{A}_M, \hat{N}_L, \hat{N}_M$'))
x.connect('opt', 'L', (r'1: $\Lambda_1, \Lambda_2, b, c_r, \tau,$',
                       r'$A_\text{root}, A_\text{tip}, \beta_\text{root},$',
                       r'$\beta_\text{kink}, \beta_\text{tip}, \hat{W}_w, \hat{W}_f$'))
x.connect('opt', 'P', (r'1: $\Lambda_1, \Lambda_2, b, c_r, \tau,$',
                       r'$\hat{W}_w, \hat{W}_f, \hat{C}_{D_w}$'))

# Function Connections
x.connect('opt', 'G', r'2: $\hat{W}_w, \hat{W}_f, \hat{C}_{D_w}$')
x.connect('opt', 'wing', (r'2: $\Lambda_1, \Lambda_2,$', r'$b, c_r, \tau$'))
x.connect('opt', 'spar', (r'2: $\Lambda_1, \Lambda_2,$', r'$b, c_r, \tau$'))
x.connect('opt', 'G_load', (r'$\hat{A}_L, \hat{A}_M,$', r'$\hat{N}_L, \hat{N}_M$'))
x.connect('A', 'G', r'2: $C_{D_w}$')

x.connect('S', 'fuel', r'2: $V_t$')
x.connect('S', 'G', r'2: $W_w$')
x.connect('S', 'wing', r'2: $W_w$')
x.connect('L', 'G_load', (r'$L\left(y\right)$', r'$M\left(y\right)$'))
x.connect('P', 'fuel', r'2: $W_f$')
x.connect('P', 'wing', r'2: $W_f$')
x.connect('P', 'obj', r'2: $W_f$')
x.connect('P', 'G', r'2: $W_f$')

# Feedback
x.connect('obj', 'opt', r'3: $f$')
x.connect('G_load', 'opt', r'3: $h_\text{load}$')
x.connect('G', 'opt', r'3: $h_{i\ldots N}$')
x.connect('fuel', 'opt', r'3: $g_\text{fuel}$')
x.connect('wing', 'opt', r'3: $g_\text{wing}$')
x.connect('spar', 'opt', r'3: $g_\text{spar}$')

# Outputs of Solver
x.add_output('A', r'$C_{D_W}^*$', side='left')
x.add_output('S', r'$V_t^*, W_w^*$', side='left')
x.add_output('L', (r'$L\left(y\right)^*$', r'$M\left(y\right)^*$'), side='left')
x.add_output('P', r'$W_f^*$', side='left')
x.add_output('opt', (r'$\Lambda_1^*, \Lambda_2^*, b^*, c_r^*, \tau^*,$',
                     r'$A_\text{root}^*, A_\text{tip}^*, \beta_\text{root}^*,$',
                     r'$\beta_\text{kink}^*, \beta_\text{tip}^*$'))
x.connect('opt', 'S', (r'1: $\Lambda_1, \Lambda_2, b, c_r, \tau,$',))

# Process Lines
x.add_process(['opt', 'A', 'G', 'opt'], arrow=False)
x.add_process(['opt', 'S', 'fuel', 'opt'], arrow=False)
x.add_process(['opt', 'S', 'wing', 'opt'], arrow=False)
x.add_process(['opt', 'S', 'G', 'opt'], arrow=False)
x.add_process(['opt', 'S', 'G', 'opt'], arrow=False)
x.add_process(['opt', 'L', 'G_load', 'opt'], arrow=False)
x.add_process(['opt', 'P', 'obj', 'opt'], arrow=False)
x.add_process(['opt', 'P', 'fuel', 'opt'], arrow=False)
x.add_process(['opt', 'P', 'wing', 'opt'], arrow=False)
x.add_process(['opt', 'P', 'G', 'opt'], arrow=False)
x.add_process(['opt', 'spar', 'opt'], arrow=False)


x.write('idf_a320', build=True, cleanup=True, auto_launch=True)
