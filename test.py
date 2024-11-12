



# RAM 128 bits line
# axi lite transfer 32 bits

def is_4byte_aligned(addr):
    return addr % 4 == 0



print(is_4byte_aligned(0x0))
print(is_4byte_aligned(0x4))
print(is_4byte_aligned(0x8))
print(is_4byte_aligned(0xC))

