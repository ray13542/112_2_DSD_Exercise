
import numpy as np
import matplotlib.pyplot as plt
import sys
import util
import argparse

if __name__ == '__main__':
    # create a parser object
    parser = argparse.ArgumentParser(description='Process some integers.')

    # add arguments to the parser object
    parser.add_argument('-method', type=str, help='The iteration method, "g" for gauss seidel or "j" for jocobi')
    parser.add_argument('-output', type=str, help='The name of the output file')
    parser.add_argument('-max_iteration', type=int, help='The maximum number of iterations')
    parser.add_argument('-bit', type=int, help='The number of bits used in fixed point')

    # parse the arguments
    args = parser.parse_args()

    # get the values of the arguments
    method = args.method
    output = args.output
    max_iter = args.max_iteration
    bit = args.bit
    
    # read input from A.dat and B.dat
    A, b = util.read_input('./inputs/A.dat', './inputs/B.dat')
    x0 = np.zeros(len(b))
    #x0 = b/dialgonal of A
    for i in range(len(b)):
        x0[i] = b[i] / A[i, i]
    final_x, final_iter, final_error = util.plot_error_vs_iteration(A, b, x0, max_iter, method, bit)
    #write the final solution x, iteration number, and error to output file
    util.write_result(output, final_x, final_iter, final_error)
