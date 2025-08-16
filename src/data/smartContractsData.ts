import { type Address } from 'viem';

interface ContractsConfig {
    [chainId: number]: {
        nftContractAddress: Address;
        auctionContractAddress: Address;
    };
}

export const chainsToContractAddress: ContractsConfig = {
    11155111: {
        //Sepolia
        nftContractAddress: '',
        auctionContractAddress: '',
    },
};
