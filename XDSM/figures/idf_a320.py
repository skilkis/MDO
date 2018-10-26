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
    return r'{}^{{\left(0\right)}}'.format(tex)


# Main System Blocks:
x.add_system('opt', opt, (r'0, 3 $\rightarrow$ 1:', 'Optimization'))
x.add_system('A', comp, ('1:', 'Aerodynamics'))
x.add_system('S', comp, ('1:', 'Structures'))
x.add_system('L', comp, ('1:', 'Loads'))
x.add_system('P', comp, ('1:', 'Performance'))

# Objective Function:
x.add_system('O', func, ('2: Objective', r'$f(W_f) = - W_F$'))

# Constraints:
x.add_system('fuel', func, ('2: Ineq. Constraint', r'$\frac{W_f}{\rho_f} - V_t \leq 0$'))
x.add_system('wing', func, ('2: Ineq. Constraint', r'$\frac{W_\text{TO}\left(\mathbf{x}\right)}'
                                                   r'{S\left(\mathbf{x}\right)} - \left(\frac{W_\text{TO}}{S}\right)^'
                                                   r'{\left(0\right)} \leq 0$'))
x.add_system('G', func, ('2: Consistency', r'$\hat{x}_i - x_i = 0$'), stack=True)

# Inputs from Reference Data:
x.add_input('opt', (r'$\zero{\Lambda_1}, \zero{\Lambda_2}, \zero{b}, \zero{c_r}, \zero{\tau},$',
                    r'$\zero{A_\text{root}}, \zero{A_\text{tip}}, \zero{\beta_\text{root}},$',
                    r'$\zero{\beta_\text{kink}}, \zero{\beta_\text{tip}}, \zero{\hat{A}_L}, \zero{\hat{A}_M},$',
                    r'$\zero{\hat{N_L}}, \zero{\hat{N_M}}, \zero{\hat{W}_w}, \zero{\hat{W}_f}, \zero{\hat{C}_{D_w}}$'))
x.add_input('A', (r'$W_{A\text{-}W}, h_c, M_c,$', r'$a_c, \rho_c, v_c, N_1, N_2$'))
x.add_input('S', (r'$W_{A\text{-}W}, W_e, \eta_\text{max}, \rho_c,$', r'$N_1, N_2, D_\text{fus}, d_\text{rib},$',
                  r'$E_\text{al}, \sigma_\text{y,c}, \sigma_\text{y,t}, \rho_\text{al} $'))
x.add_input('L', (r'$W_{A\text{-}W}, \eta_\text{max}, h_c, M_c,$', r'$a_c, \rho_c, v_c, N_1, N_2$'))
x.add_input('P', r'$W_{A\text{-}W}, R_c, \rho_c, V_c, C_T$')
x.add_input('fuel', r'$\rho_f$')
x.add_input('wing', r'$W_{A\text{-}W}, \left(\frac{W_\text{TO}}{S}\right)^{\left(0\right)}$')

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
x.connect('opt', 'G', (r'2: $\hat{W}_w, \hat{W}_f, \hat{A}_L,$',
                       r'$\hat{A}_M, \hat{N}_L, \hat{N}_M, C_{D_w}$'))
x.connect('opt', 'wing', (r'2: $\Lambda_1, \Lambda_2,$', r'$b, c_r, \tau$'))
x.connect('A', 'G', r'2: $C_{D_w}$')

x.connect('S', 'fuel', r'2: $V_t$')
x.connect('S', 'G', r'2: $W_w$')
x.connect('S', 'wing', r'2: $W_w$')
x.connect('L', 'G', (r'2: $A_L, A_M,$', r'$N_L, N_M$'))
x.connect('P', 'fuel', r'2: $W_f$')
x.connect('P', 'wing', r'2: $W_f$')
x.connect('P', 'O', r'2: $W_f$')
x.connect('P', 'G', r'2: $W_f$')
# x.connect('opt', 'H', r'$\hat{W}_f,$ $\mathcal{G}$')
# x.connect('opt', 'G', r'$\mathcal{G}$')

# Feedback
x.connect('O', 'opt', r'3: $f$')
x.connect('G', 'opt', r'3: $h_i$')
# x.connect('G', 'opt', r'$g$')
# x.connect('H', 'opt', r'$h$')
# x.connect('S', 'solver', r'$W_s$')
# x.connect('P', 'solver', r'$W_f$')
# x.connect('P', 'F', r'$W_f$')
# x.connect('P', 'G', r'$W_f$')
# x.connect('S', 'G', r'$W_s$')
# x.connect('opt', 'G', r'$S$')
#
# x.add_input('opt', r'$S^{\left(0\right)}$, $A^{\left(0\right)}$')
# x.add_input('solver', r'$\frac{W}{S}_{ref}^{\left(0\right)}$')
# x.add_input('G', r'$\frac{W}{S}_{ref}$')
# #
x.add_output('A', r'$C_{D_W}^*$', side='left')
x.add_output('opt', r'$W_f^*$', side='left')
x.add_output('S', r'$V_t^*, W_w^*$', side='left')
x.add_output('L', (r'$A_L^*, A_M^*,$', r'$N_L^*, N_M^*$'), side='left')
# x.add_output('G', r'$g^*$', side='left')
# x.add_output('F', r'$f^*$', side='left')
# x.add_output('H', r'$h^*$', side='left')
x.write('idf_a320', build=True, cleanup=True, auto_launch=True)
