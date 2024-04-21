import numpy as np
import matplotlib.pyplot as plt
import sys
import gaussian_seidel as gs
import jocobi as jb

# global variable to check if it is the first call of write_xnew function
is_first_call = True 

def twos_complement(hexstr,bits):
    value = int(hexstr, 16)
    if value & (1 << (bits-1)):
        value -= 1 << bits
    return value

def read_input(filename1, filename2):
    with open(filename1, 'r') as f:
        lines = f.readlines()  # read all lines
    n = len(lines)  # number of lines
    # A would be initialize as a 16 * 16 matrix
    A = np.zeros((n, n))
    for i in range(n):
        line = lines[i].split()
        for j in range(n):
            A[i, j] = int(line[j], 10)
            #turn A in to int32
    A = A.astype(np.int32)

    with open(filename2, 'r') as f:
        lines = f.readlines()
    b = np.zeros(n)
    for i in range(n):
        #b is input in hexadecimal format with 2's complement representation
        b[i] = twos_complement(lines[i], 16)
        # b[i] = int(lines[i], 16)
    return A, b

def write_xnew(x, iteration, output):
    global is_first_call  # 使用 global 關鍵字來指示我們要使用全局變數
    filename = './output/' + output
    if is_first_call:
        with open(filename, 'w') as f:
            f.write('Initial x:\n')
            f.write('\n'.join('{:5.4f}'.format(val) for val in x))
            f.write('\n')
        is_first_call = False  # 更新全局變數的值
    else:
        with open(filename, 'a') as f:
            f.write('iteration = ' + str(iteration+1) + ':\n')
            f.write('\n'.join('{:5.4f}'.format(val) for val in x))
            f.write('\n')

def plot_error_vs_iteration(A, b, x0, max_iter = 50, argu = '-g'):
    n = len(b)
    x = x0
    x_new = np.zeros(n)
    iteration = 0
    error = 1
    error_list = []
    iteration_list = []
    #call gauss_seidel function to get the error and iteration number
    for limit in range(28, 32):
        while iteration < max_iter:
            if argu == '-g':
                x_new, iteration, error = gs.gauss_seidel(A, b, x, iteration, limit)
            elif argu == '-j':
                x_new, iteration, error = jb.jocobi(A, b, x, iteration)
            if error < 1e-6:
                break
            error_list.append(error)
            iteration_list.append(iteration)
            x = x_new
            #plot the error vs iteration graph
            #change error_list in to log scale
        plt.plot(iteration_list, np.log(error_list), label=f'{limit} bits')
    # show a label in the graph
    plt.legend()
    # show a horizontal line at y = -6
    plt.axhline(y=np.log(1e-6), color='r', linestyle='--')
    plt.xlabel('Iteration')
    plt.ylabel('Error')
    plt.title('Error vs Iteration')
    plt.savefig('output/error_vs_iteration.png')  # save the figure to the output folder
    plt.close()  # close the figure
    return x, iteration, error

def write_result(filename, final_x, final_iter, final_error):
    with open(filename, 'w') as f:
        f.write('Final x:\n')
        f.write('\n'.join('{:5.4f}'.format(val) for val in final_x))
        f.write('\n'+ '#'*20)
        f.write('\nFinal iteration:\n')
        f.write(str(final_iter))
        f.write('\n'+ '#'*20)
        f.write('\nFinal error:\n')
        f.write(str(final_error))

def fixed_point(value, int_bits=16, frac_bits=16):
    scale = 2 ** frac_bits
    max_val = 2 ** (int_bits - 1) - 1 / scale
    min_val = -1 * 2 ** (int_bits - 1)
    value = np.clip(value, min_val, max_val)
    return np.round(value * scale) / scale