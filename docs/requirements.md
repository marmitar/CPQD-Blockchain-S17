# Practical Work - Smart Contracts and OPCODES

## 1. ERC20 Token - 5 points

1. Implement a smart contract in Solidity that implements the [Token ERC20](https://eips.ethereum.org/EIPS/eip-20).
2. In the contract's constructor create 1000 units of this token and send them to
   `0x14dC79964da2C08b23698B3D3cc7Ca32193d9955`.
3. Make sure the `Transfer` and `Approval` events are being emitted correctly.
4. The submission must contain a *single file* named `TrabalhoERC20.sol`.
5. If you make use of interfaces or third-party libraries, make sure everything is in the SAME `.sol` file.
6. The assignment will be graded by the professor through unit tests for each implemented method. Every method that
   passes is worth 1 point, totaling 5 points.

Tips:

- ERC-20 interface:
  <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol>
- If you don't want to keep testing the contract manually, use Foundry tests:
  <https://getfoundry.sh/introduction/getting-started/>
- Test example: <https://github.com/transmissions11/solmate/blob/main/src/test/ERC20.t.sol>

## 2. Circle Area - 2 points

Given an integer radius of a circle, implement an EVM smart contract using *only OPCODES* that calculates the
approximate integer area of the circle.

1. If the result is not an integer, round to the nearest value, for example:
   - `radius = 4`, then `area = 50` (~50.27)
   - `radius = 2`, then `area = 13` (~12.57)
2. The input value is a 256-bit integer **between 0 and 65535**, provided in `calldata` position 0 and readable with
   `PUSH0` followed by `CALLDATALOAD`.
3. The result must be returned by the program.
4. Solidity submissions *will not be accepted!* The delivery can be in two formats:
   - **OPCODES**: the code must run in the [evm.codes/playground](https://www.evm.codes/playground) with `Mnemonic`
     selected.
   - **Hexadecimal**: the code must run in the [evm.codes/playground](https://www.evm.codes/playground) with `Bytecode`
     selected.
5. The maximum gas your program may use is 100 thousand (which is A LOT, you'll barely spend a thousand).
6. If the program fails for any input, points will be deducted at the professor's discretion.

Tips:

- The EVM has no decimal numbers... if only there were a way to represent decimals with integers... (think).
- The formula for the area of a circle is $\pi r^2$, use a $\pi$ value precise enough given radii between 0 and 65535.
- The input space is small enough that you can test every single value.
- All OPCODES available in the EVM: <https://www.evm.codes/>

## 3. EVM SQRT - 2 points

Implement an EVM smart contract using *only OPCODES* that computes the integer square root of a number.

1. If the result is not an integer, round it down, e.g., square root of 5 must return 2.
2. The input value is a 256-bit integer, provided in `calldata` position 0 and readable with `PUSH0` followed by
   `CALLDATALOAD`.
3. The result must be returned by the program.
4. Solidity submissions *will not be accepted!* The delivery can be in two formats:
   - **OPCODES**: the code must run in the [evm.codes/playground](https://www.evm.codes/playground) with `Mnemonic`
     selected.
   - **Hexadecimal**: the code must run in the [evm.codes/playground](https://www.evm.codes/playground) with `Bytecode`
     selected.
5. The maximum gas your program may use is 100 thousand (which is A LOT, you'll barely spend a thousand).
6. If the program fails in some cases, points will be deducted at the professor's discretion.

Tips:

- How to compute square roots with Newton's method: <https://www.youtube.com/watch?v=_-lteSa91PU>
- All OPCODES available in the EVM: <https://www.evm.codes/>
- No need to overcomplicate things. You'll only need simple arithmetic OPCODES... plus `MSTORE` and `RETURN` at the end
  to return the value.

## 4. CHALLENGE - 1 point

> Note: hardest task.

Create a Solidity smart contract that consumes 100% of the gas provided and finishes successfully WITHOUT REVERTING.

The minimum gas considered is 1000 units (base cost excluded). For any value above 1000 units the contract must never
revert.

1. The submission may use either OPCODES or Solidity:
   - If using OPCODES, use the [`GAS` OPCODE](https://www.evm.codes/?fork=cancun#5a) to push the remaining gas onto the
     stack.
   - If using Solidity, call `gasleft()` to check the remaining gas.
2. The EVM version must be **CANCUN**, as some opcodes have rare gas-cost differences in other versions.
3. If Solidity is used, also provide the bytecode and specify the compiler version and settings used to build the
   contract.

Tips:

- You may prefer pure OPCODES or inline assembly for finer gas control.
- You'll have trouble using the playground to test this contract, since it doesn't let you tweak the gas supplied.
- This tool might help: <https://getfoundry.sh/forge/debugger/>
