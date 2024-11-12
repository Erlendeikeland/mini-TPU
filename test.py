



import numpy as np

SIZE = 8

matrix_a = np.zeros((SIZE, SIZE), dtype=int)
matrix_b = np.zeros((SIZE, SIZE), dtype=int)

for i in range(SIZE):
    for j in range(SIZE):
        matrix_a[i][j] = i % (j + 1)
        matrix_b[i][j] = i % (j + 1)

matrix_c = np.dot(matrix_a, matrix_b)

for i in range(SIZE):
    print(f"        ({", ".join([str(x) for x in matrix_c[i]])}),")