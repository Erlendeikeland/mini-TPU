import numpy as np





def matrix_multiplication(matrix1, matrix2):
    result = [[0 for _ in range(len(matrix2[0]))] for _ in range(len(matrix1))]
    for i in range(len(matrix1)):
        for j in range(len(matrix2[0])):
            for k in range(len(matrix2)):
                result[i][j] += matrix1[i][k] * matrix2[k][j]
    return result




def get_test_matrix(matrix, SIZE):    
    height = (SIZE * 2) - 1
    result = [["0" for _ in range(SIZE)] for _ in range(height)]
    for i in range(SIZE):
        for j in range(SIZE):
            row = i + j
            col = j
            result[row][col] = str(matrix[i][j])
    return result




SIZE = 4
matrix = np.array([[0 for _ in range(SIZE)] for _ in range(SIZE)])

for i in range(SIZE):
    for j in range(SIZE):
        matrix[i][j] = i + j

for row in matrix_multiplication(matrix, matrix):
    print(row)
