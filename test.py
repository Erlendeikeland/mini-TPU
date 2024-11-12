



import numpy as np

SIZE = 8

matrix_a = np.zeros((SIZE, SIZE), dtype=int)
matrix_b = np.zeros((SIZE, SIZE), dtype=int)

for i in range(SIZE):
    for j in range(SIZE):
        matrix_a[i][j] = i % (j + 1)
        matrix_b[i][j] = i % (j + 1)

matrix_c = np.dot(matrix_a, matrix_b)








def create_write_address(address, op, offset):
    address_bits = address << 6
    op_bits = op << 4
    offset_bits = offset << 2
    write_address = address_bits | op_bits | offset_bits
    return write_address

def create_read_address(address, offset):
    address_bits = address << 6
    offset_bits = offset << 2
    read_address = address_bits | offset_bits
    return read_address

IP_BASE_ADDRESS = 0x4000000
ADDRESS_RANGE = 0x000FFFFF


from pynq import MMIO
mmio = MMIO(IP_BASE_ADDRESS, ADDRESS_RANGE)

SIZE = 16


for i in range(SIZE):
    for j in range(4):
        write_data = (i % 4) + j
        write_address = create_write_address(i, 0, j)
        mmio.write(write_address, write_data)

for i in range(SIZE):
    for j in range(4):
        read_address = create_read_address(i, j)
        assert mmio.read(read_address) == (i % 4) + j