# Ethereum Virtual Machine (EVM) Challenges

Solution to selected challenges implemented focusing on EVM Bytecode optimizations.

## Challenges

### 1. ERC-20 Token

Implement the [ERC-20 Token](https://eips.ethereum.org/EIPS/eip-20) in Solidity.

### 2. Circle Area

Calculate the integer approximation for area the of a circle of radius $0 \leq r < 2^{16}$ using EVM bytecode.

### 3. EVM SQRT

Caulculate the integer square root of a number using EVM bytecode.

### 4. Gas-Burner Challenge

Create a smart contract the consumes 100% of the provided gas.

## Development

### Build

```shell
$ forge build
```

#### Build with Model Checker

```shell
$ FOUNDRY_PROFILE=checker forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```
