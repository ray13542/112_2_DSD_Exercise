import numpy as np
import matplotlib.pyplot as plt
import sys
import util

def gauss_seidel(A, b, x, iteration, limit):
    n = len(b)
    error = 1
    x_new = np.zeros(n)
    # util.write_xnew(x, iteration, 'x_new.txt')
    for i in range(n):
        sum1 = np.dot(A[i, :i], x_new[:i])
        sum2 = np.dot(A[i, i + 1:], x[i + 1:])
        x_new[i] = util.fixed_point((b[i] - sum1 - sum2) / A[i, i], 15, limit-15)
    #error = (sumation of sumation of Aij * xi - bi)^2
    error = np.linalg.norm(np.dot(A, x_new) - b)
    
    iteration += 1
    return x_new, iteration, error