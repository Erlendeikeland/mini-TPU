import numpy as np





def matrix_multiplication(matrix1, matrix2):
    result = [[0 for _ in range(len(matrix2[0]))] for _ in range(len(matrix1))]
    for i in range(len(matrix1)):
        for j in range(len(matrix2[0])):
            for k in range(len(matrix2)):
                result[i][j] += matrix1[i][k] * matrix2[k][j]
    return result

import random


SIZE = 16
matrix_a = np.array([[0 for _ in range(SIZE)] for _ in range(SIZE)])

for i in range(SIZE):
    for j in range(SIZE):
        matrix_a[i][j] = i % 4 + 2

matrix_b = np.array([[2 for _ in range(SIZE)] for _ in range(SIZE)])

for row in matrix_multiplication(matrix_a, matrix_b):
    print([int(x) for x in row])


print(hex(0x400FFFFF - 0x40000000))