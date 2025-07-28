def msb_position(n: int) -> int:
    return (n.bit_length() - 1) if n else 0

def generate_lookup_table() -> str:
    table = [msb_position(i << 2) & 0x0E for i in range(64)]

    # Convert to a single 64-byte value
    lookup_value = 0
    for i, value in enumerate(table):
        lookup_value |= value << (8 * (63 - i))

    return f"0x{lookup_value:0128x}"

print(generate_lookup_table())
