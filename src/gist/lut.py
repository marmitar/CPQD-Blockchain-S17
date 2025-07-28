from math import sqrt

def generate_lookup_table() -> str:
    roots = [list[int]() for _ in range(32)]
    for i in range(256):
        roots[i >> 3].append(sqrt(i))
    table = [sum(roots[i]) / len(roots[i]) for i in range(32)]

    # Convert to a single 32-byte value
    lookup_value = 0
    for i, value in enumerate(table):
        lookup_value |= round(value) << (8 * (31 - i))

    return f"0x{lookup_value:064x}"

print(generate_lookup_table())
