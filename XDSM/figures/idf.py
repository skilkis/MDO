from pyXDSM.pyxdsm.XDSM import XDSM

#
opt = 'Optimization'
solver = 'MDA'
comp = 'Analysis'
group = 'Metamodel'
func = 'Function'

x = XDSM()

# TODO make proper colors for the optimizer (one in slides looks nice)

x.add_system('opt', opt, (r'0, 2, 5 $\rightarrow$ 1:', 'Optimizer'))
x.add_system('A', comp, ('3:', 'Aero.'))
x.add_system('S', comp, ('3:', 'Struct.'))
x.add_system('P', comp, ('3:', 'Perf.'))
x.add_system('F', func, ('4:', r'$f(\mathbf{X})$'))
x.add_system('H', func, ('2:', r'$h(\mathbf{X})$'))
x.add_system('G', func, ('2:', r'$g(\mathbf{X})$'))

x.add_process(['opt', 'A'], arrow=True)
x.add_process(['opt', 'S'], arrow=True)
x.add_process(['opt', 'P', 'F', 'opt'], arrow=True)
x.add_process(['opt', 'H', 'opt'], arrow=True)
x.add_process(['opt', 'G', 'opt'], arrow=True)

# Feedforward
x.connect('opt', 'A', (r'$\hat{W_f}$, $\hat{W_s}$,', r'$S$, $A$'))
x.connect('opt', 'H', (r'$\hat{W_f}$, $\hat{W_s}$,', r'$\hat{L}$, $\hat{D}$'))
x.connect('opt', 'S', (r'$\hat{W_f}$, $\hat{L}$', r'$S$, $A$'))
x.connect('A', 'H', r'$L$, $D$')
x.connect('S', 'H', r'$W_s$')
x.connect('P', 'F', r'$W_f$')
x.connect('P', 'H', r'$W_f$')
x.connect('opt', 'P', (r'$W_s$, $\hat{L}$', r'$\hat{D}$'))
x.connect('opt', 'G', (r'$\hat{W_f}$, $\hat{W_s}$,', r'$S$'))

# Feedback
x.connect('F', 'opt', r'$f$')
x.connect('G', 'opt', r'$g$')
x.connect('H', 'opt', r'$h$')
# x.connect('S', 'solver', r'$W_s$')
# x.connect('P', 'solver', r'$W_f$')
# x.connect('P', 'F', r'$W_f$')
# x.connect('P', 'G', r'$W_f$')
# x.connect('S', 'G', r'$W_s$')
# x.connect('opt', 'G', r'$S$')
#
# x.add_input('opt', r'$S^{\left(0\right)}$, $A^{\left(0\right)}$')
# x.add_input('solver', r'$\frac{W}{S}_{ref}^{\left(0\right)}$')
x.add_input('G', r'$\frac{W}{S}_{ref}$')
#
x.add_output('opt', r'$S^*$, $A^*$', side='left')
x.add_output('G', r'$g^*$', side='left')
x.add_output('F', r'$f^*$', side='left')
x.add_output('H', r'$h^*$', side='left')
x.write('idf', build=True)
