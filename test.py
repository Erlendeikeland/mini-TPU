import numpy as np





def matrix_multiplication(matrix1, matrix2):
    result = [[0 for _ in range(len(matrix2[0]))] for _ in range(len(matrix1))]
    for i in range(len(matrix1)):
        for j in range(len(matrix2[0])):
            for k in range(len(matrix2)):
                result[i][j] += matrix1[i][k] * matrix2[k][j]
    return result

import random


SIZE = 8
matrix_a = np.array([[0 for _ in range(SIZE)] for _ in range(SIZE)])

for i in range(SIZE):
    for j in range(SIZE):
        matrix_a[i][j] = i + j

matrix_b = np.array([[1 for _ in range(SIZE)] for _ in range(SIZE)])

for row in matrix_multiplication(matrix_a, matrix_b):
    print([int(x) for x in row])





"""
IP_BASE_ADDRESS = 0x40000000
ADDRESS_RANGE = 0x10000
ADDRESS_OFFSET = 0x0

from pynq import MMIO
mmio = MMIO(IP_BASE_ADDRESS, ADDRESS_RANGE)

SIZE = 8

for i in range(SIZE):
    for j in range(2):
        write_address = create_write_address(i, 0)
        write_data = 0x01020304
        mmio.write(write_address, write_data)
        
for i in range(SIZE):
    for j in range(2):
        rea_address = create_read_address(i, 0)
        print(mmio.read(write_address))

"""

def create_write_address(op, offset, address):
    op_bits = op << 20
    offset_bits = offset << 18
    address_bits = address
    write_address = op_bits | offset_bits | address_bits
    return write_address

def create_read_address(offset, address):
    offset_bits = offset << 18
    address_bits = address
    read_address = offset_bits | address_bits
    return read_address