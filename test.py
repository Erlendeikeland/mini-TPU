


import numpy as np

matrix_a = [[0 for _ in range(4)] for _ in range(4)]
matrix_b = [[0 for _ in range(4)] for _ in range(4)]


for i in range(4):
    for j in range(4):
        matrix_a[i][j] = i

for i in range(4):
    for j in range(4):
        matrix_b[i][j] = i


print(np.matmul(matrix_a, matrix_b))



def mult(a, b):
    c = [[0 for _ in range(len(b[0]))] for _ in range(len(a))]

    temp = 0

    for i in range(len(a)):
        for j in range(len(b[0])):
            for k in range(len(b)):
                temp = a[i][k] * b[k][j]
                c[i][j] += temp
            print(c[i][j])

    return c

for row in mult(matrix_a, matrix_b):
    print(int(row[0]), int(row[1]), int(row[2]), int(row[3]))