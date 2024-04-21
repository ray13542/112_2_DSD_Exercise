
import numpy as np
import matplotlib.pyplot as plt
import sys
import util

if __name__ == '__main__':
    # argument would ask the iteration is using gauss seidel or jocobian with "-g" or "-j"
    argu = sys.argv[1]
    # argument would also define the name of the output file
    output = sys.argv[2]
    # read input from A.dat and B.dat
    A, b = util.read_input('./inputs/A.dat', './inputs/B.dat')
    x0 = np.zeros(len(b))
    #x0 = b/dialgonal of A
    for i in range(len(b)):
        x0[i] = b[i] / A[i, i]
    final_x, final_iter, final_error = util.plot_error_vs_iteration(A, b, x0, max_iter=1000, argu=argu)
    #write the final solution x, iteration number, and error to output file
    util.write_result(output, final_x, final_iter, final_error)