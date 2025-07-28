from math import sqrt

def generate_lookup_table() -> str:
    roots = { i: list[int]() for i in range(32) }
    for i in range(256):
        roots[i >> 3].append(sqrt(i))

    table = [sum(roots[i]) / len(roots[i]) for i in range(32)]
    print(table)

    # Convert to a single 32-byte value
    lookup_value = 0
    for i, value in enumerate(table, start=1):
        lookup_value |= round(value) << (8 * (32 - i))

    return f"0x{lookup_value:064x}"

print(generate_lookup_table())
