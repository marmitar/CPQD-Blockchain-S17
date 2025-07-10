# Trabalho Prático - Smart-Contracts e OPCODES

## \#1 Token ERC20 - 5 pontos

1. Implemente um smart-contract em Solidty que implemente a interface [Token ERC20,](https://eips.ethereum.org/EIPS/eip-20)
2. No construtor do contrato crie **1000** unidades desse token e envie para a conta **0x14dC79964da2C08b23698B3D3cc7Ca32193d9955**.
3. Garanta que os eventos **Transfer** e **Approval** estão sendo emitidos corretamente.
4. A entrega deve conter um **único arquivo** com o nome **TrabalhoERC20.sol**.
5. Se for utilizar interfaces ou usar bibliotecas de terceiros, garanta que tudo esta no MESMO arquivo sol.
6. O trabalho sera corrigido pelo professor usando testes unitários para cada método implementado, cada método que passar nos testes vale 1 ponto, totalizando 5 pontos.

Dicas:

- Interface do ERC20: <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol>
- Se não quiser ficar testando o contrato manualmente, utilize os testes do Foundry: <https://getfoundry.sh/introduction/getting-started/>
- Exemplo de testes: <https://github.com/transmissions11/solmate/blob/main/src/test/ERC20.t.sol>

## \#2 Area Circulo - 2 pontos

Dado um raio inteiro de um circulo, implemente um smart-contract EVM utilizando *apenas OPCODES* que calcule a area inteira aproximada do circulo.

1. Se o resultado não for um número inteiro, então o resultado deve ser arredondado para o valor mais próxima, exemplo:
    - **raio = 4 então area = 50 (~50.27)**
    - **raio = 2 então area = 13 (~12.57)**
2. O valor de entrada é um número inteiro de 256bit **entre 0 e 65535**, que será fornecido no calldata na posição 0 e pode ser lido com **PUSH0** seguido de **CALLDATALOAD**.
3. O resultado **deve ser retornado** pelo programa.
4. Entregas em solidity *não serão aceitas!!* a entrega deve pode ser em dois formatos:
    - **OPCODES**, nesse caso o código deve funcionar no [evm.codes/playground](https://www.evm.codes/playground), com a opção **Mnemonic** selecionada.
    - **Hexadecimal**, nesse caso o código deve funcionar no [evm.codes/playground](https://www.evm.codes/playground) com a opção **Bytecode** selecionada
5. A quantidade máxima de gas que seu programa pode utilizar e 100mil. (que é MUITO, dificilmente será gasto mais que mil).
6. Se o programa falhar para alguma entrada, será descontado pontos a critério do professor.

Dicas:

- A EVM não possui número decimais... se ao menos houvesse uma forma de representar decimais usando inteiros... (pense)
- A formula para área do circulo é \`**π * r * r**\`, utilize um valor de PI com precisão suficiente levando em consideração que a entrada é entre 0 e 65535.
- As possibilidades de valores de entrada é suficientemente pequena para você testar todas elas.
- Todos os OPCODES disponíveis na EVM: <https://www.evm.codes/>

## \#3 EVM SQRT - 2 pontos

implemente um smart-contract EVM utilizando *apenas OPCODES* que calcule a **raiz quadrada** inteira de um número.

1. Se o resultado não for um número inteiro, então o resultado deve ser arredondado para baixo, ex: **raiz 5 deve retornar 2**
2. O valor de entrada é um número inteiro de 256bit, que será fornecido no calldata na posição 0 e pode ser lido com **PUSH0** seguido de **CALLDATALOAD**.
3. O resultado **deve ser retornado** pelo programa.
4. Entregas em solidity *não serão aceitas!!* a entrega deve pode ser em dois formatos:
    - **OPCODES**, nesse caso o código deve funcionar no [evm.codes/playground](https://www.evm.codes/playground), com a opção **Mnemonic** selecionada.
    - **Hexadecimal**, nesse caso o código deve funcionar no [evm.codes/playground](https://www.evm.codes/playground) com a opção **Bytecode** selecionada
5. A quantidade máxima de gas que seu programa pode utilizar e 100mil. (que é MUITO, dificilmente será gasto mais que mil).
6. Se o programa falhar em alguns casos, será descontado pontos a critério do professor.

Dicas:

- Como calcular a raiz quadrada utilizando o método de newton: <https://www.youtube.com/watch?v=_-lteSa91PU>

    [![external youtubed](https://img.youtube.com/vi/_-lteSa91PU/2.jpg)](https://www.youtube.com/watch?v=_-lteSa91PU)

- Todos os OPCODES disponíveis na EVM: <https://www.evm.codes/>
- Não precisa complicar, você só vai precisar usar OPCODES de operações arithméticas simples.. e MSTORE e RETURN no final para retornar o resultado

## \#4 DESAFIO - 1 ponto

OBS: desafio com maior dificuldade.

Crie um smart-contract em solidity que consuma 100% do gas fornecido e execute com sucesso SEM REVERTER.

A quantidade minima de gas considerada é 1000 unidades (descontando o custo base), qualquer valor acima de 1000 unidades o contrato nunca deve reverter.

1. A entrega pode ser tanto usando OPCODES quanto em solidity
    - Se for utilizar OPCODES, utilize o OPCODE [**GAS**](https://www.evm.codes/?fork=cancun#5a) para jogar na stack a quantidade de gas restante no contrato.
    - Se for utilizar solidity, utilize **gasleft()** para verificar a quantidade de gas restante no contrato.
2. A versão da EVM utilizada deve ser **CANCUN**, pois existe raras diferenças no consumo de gas em alguns opcodes em versões diferentes.
3. Se solidity for utilizado, envie também o bytecode e especifique a versão do compilador e configuração utilizada para compilar o contrato.

Dicas:

- Talvez você prefira utilizar  OPCODES ou assembly inline para ter maior controle do gas utilizado.
- Você tera dificuldade em utilizar o playground para testar esse contrato, uma vez que ele não deixa você alterar o gas fornecido ao contrato.
- Talvez essa ferramenta ti ajude nesse desafio: <https://getfoundry.sh/forge/debugger/>
