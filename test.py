def create_read_address(address, offset):
    address_bits = address << 6
    offset_bits = offset << 2
    read_address = address_bits | offset_bits
    return read_address

def create_write_address(address, op, offset):
    address_bits = address << 6
    op_bits = op << 4
    offset_bits = offset << 2
    write_address = address_bits | op_bits | offset_bits
    return write_address

def concatenate_data(data):
    result = 0
    for i in range(4):
        result = result | (data[i] << (i * 8))
    return result

def split_data(data):
    result = np.zeros(4, dtype=np.uint8)
    for i in range(4):
        result[i] = (data >> (i * 8)) & 0xFF
    return result

def write_unified_buffer(address, matrix):
    for i in range(SIZE):
        for j in range(BLOCKS):
            addr = create_write_address(address + i, 0, j)
            data = concatenate_data(matrix[i][j * 4: (j + 1) * 4])
            mmio.write(addr, int(data))

def write_weight_buffer(address, matrix):
    for i in range(SIZE):
        for j in range(BLOCKS):
            addr = create_write_address(address + i, 1, j)
            data = concatenate_data(matrix[i][j * 4: (j + 1) * 4])
            mmio.write(addr, int(data))

def read_unified_buffer(address):
    result = np.zeros((SIZE, SIZE), dtype=np.uint8)
    for i in range(SIZE):
        for j in range(BLOCKS):
            addr = create_read_address(address + i, j)
            data = mmio.read(addr)
            result[i][j * 4: (j + 1) * 4] = split_data(data)
    return result

def load_weights(address):
    addr = 0x20
    data = (address << 2) | 0x2
    mmio.write(addr, data)
    
def matrix_multiply(src, dest):
    addr = 0x20
    data = ((src << 17) | (dest << 2)) | 0x1
    mmio.write(addr, data)
    
def random_matrix(size):
    matrix = np.zeros((size, size), dtype=np.uint8)
    for i in range(size):
        for j in range(size):
            matrix[i][j] = random.randint(0, 4)
    return matrix





import numpy as np
import random
import time

from pynq import Overlay

overlay = Overlay("miniTPU_soc.bit")
mmio = overlay.S00_AXI_0.mmio

SIZE = 16
DATA_WIDTH = 8
AXI_DATA_WIDTH = 32
BLOCKS = (SIZE * DATA_WIDTH) // AXI_DATA_WIDTH

mmio.write(0x40, 0xFFFFFFFF)

unified_matrices = [random_matrix(SIZE) for i in range(32)]
weight_matrices = [random_matrix(SIZE) for i in range(32)]

hw_results = []
sw_results = []

start = time.time()
for i in range(32):
    #write_weight_buffer(i * SIZE, weight_matrices[i])
    write_unified_buffer(i * SIZE, unified_matrices[i])
    #load_weights(i * SIZE)
    #matrix_multiply(i * SIZE, (32 * SIZE) + (i * SIZE))
    #hw_results.append(read_unified_buffer((32 * SIZE) + (i * SIZE)))
end = time.time()
print("Hardware execution time: ", end - start)
    
start = time.time()
for i in range(32):
    sw_results.append(np.matmul(unified_matrices[i], weight_matrices[i]))
end = time.time()
print("Software execution time: ", end - start)

for i in range(32):
    if not np.array_equal(hw_results[i], sw_results[i]):
        print(hw_results[i])
        print(sw_results[i])
        print("Mismatch at index: ", i)
        break