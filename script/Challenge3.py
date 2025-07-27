def msb_position(n):
    return (n.bit_length() - 1) if n else 0

def generate_lookup_table():
    table = [msb_position(i) for i in range(16)]

    # Pad the table to 32 bytes
    padded_table = table + [0] * 16

    # Convert to a single 32-byte value
    lookup_value = 0
    for i, value in enumerate(padded_table):
        lookup_value |= value << (8 * (31 - i))

    return f"0x{lookup_value:064x}"

print(generate_lookup_table())
