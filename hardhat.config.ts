import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-abi-exporter';

const config: HardhatUserConfig = {
  solidity: '0.8.18',
  abiExporter: {
    runOnCompile: true,
    clear: true,
    rename: (sourceName: string, contractName: string) => contractName + '.abi',
  },
};

export default config;
