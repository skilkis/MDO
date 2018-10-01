from pyXDSM.pyxdsm.XDSM import XDSM

#
opt = 'Optimization'
solver = 'MDA'
comp = 'Analysis'
group = 'Metamodel'
func = 'Function'

x = XDSM()

# TODO make proper colors for the optimizer (one in slides looks nice)

x.add_system('opt', opt, (r'0, 8 $\rightarrow$ 1:', 'Optimizer'))
x.add_system('solver', solver, (r'1, 5 $\rightarrow$ 2:', r'Coodinator'))
x.add_system('A', comp, ('3:', 'Aero.'))
x.add_system('S', comp, ('4:', 'Struct.'))
x.add_system('P', comp, ('5:', 'Perf.'))
x.add_system('F', func, ('6:', r'$f(\mathbf{X})$'))
x.add_system('G', func, ('7:', r'$g(\mathbf{X})$'))

x.add_process(['opt', 'solver', 'A', 'S', 'P', 'solver', 'F', 'G', 'opt'], arrow=True)

# Feedforward
x.connect('solver', 'A', r'$\hat{W_f}$, $\hat{W_s}$')
x.connect('solver', 'S', r'$\hat{W_f}$')
x.connect('opt', 'A', r'$S$, $A$')
x.connect('opt', 'S', r'$S$, $A$')
x.connect('solver', 'G', r'$\frac{W}{S}_{ref}$')
x.connect('A', 'S', r'$L$')
x.connect('S', 'P', r'$W_s$')
x.connect('A', 'P', r'$L$, $D$')

# # Feedback
x.connect('F', 'opt', r'$f$')
x.connect('G', 'opt', r'$g$')
x.connect('S', 'solver', r'$W_s$')
x.connect('P', 'solver', r'$W_f$')
x.connect('P', 'F', r'$W_f$')
x.connect('P', 'G', r'$W_f$')
x.connect('S', 'G', r'$W_s$')
x.connect('opt', 'G', r'$S$')

x.add_input('opt', r'$S^{\left(0\right)}$, $A^{\left(0\right)}$')
x.add_input('solver', r'$\frac{W}{S}_{ref}^{\left(0\right)}$')

x.add_output('opt', r'$S^*$, $A^*$', side='left')
x.add_output('G', r'$g^*$', side='left')
x.add_output('F', r'$f^*$', side='left')
x.write('mdf', build=True)
