import numpy as np
import matplotlib.pyplot as plt
import sys
import util

def jocobian(A, b, x, iteration):
    n = len(b)
    error = 1
    x_new = np.zeros(n)
    for i in range(n):
        sum1 = np.dot(A[i, :i], x[:i])
        sum2 = np.dot(A[i, i + 1:], x[i + 1:])
        x_new[i] = (b[i]- sum1 - sum2) / A[i, i]
    #error = sumation of sumation of (Aij * xi - bi)^2
    error = np.linalg.norm(np.dot(A, x_new) - b)
    util.write_xnew(x_new, iteration, 'x_new.txt')
    iteration += 1
    return x_new, iteration, error