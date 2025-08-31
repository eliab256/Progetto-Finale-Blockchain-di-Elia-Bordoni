import React, { useState } from 'react';
import { fetchMetadataById } from '../services/ipfsService';
import { yoyoNftAbi, chainsToContractAddress } from '../data/smartContractsData';
import { useChainId, useAccount, useReadContract } from 'wagmi';

interface NftCardProps {
    tokenId: number;
}

export const NftCard: React.FC<NftCardProps> = ({ tokenId }) => {
    const [videoLoading, setVideoLoading] = useState(true);
    const [videoError, setVideoError] = useState(false);
    const { address } = useAccount();
    const chainId = useChainId();
    const nftContractAddress = chainsToContractAddress[chainId].yoyoNftContractAddress;

    const baseURI = useReadContract({
        address: nftContractAddress,
        abi: yoyoNftAbi,
        functionName: 'getBaseURI',
        account: address,
    }).data as string;

    const handleVideoLoad = () => {
        setVideoLoading(false);
    };

    const handleVideoError = () => {
        setVideoLoading(false);
        setVideoError(true);
    };

    return (
        <div className={`bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300`}>
            {/* Video Preview */}
            <div className="aspect-video relative bg-gray-900 group">
                {videoLoading && (
                    <div className="absolute inset-0 flex items-center justify-center bg-gray-100 z-10">
                        <div className="text-center">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mb-2 mx-auto"></div>
                            <span className="text-sm text-gray-500">Loading video...</span>
                        </div>
                    </div>
                )}

                {videoError ? (
                    <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-100 to-gray-200">
                        <div className="text-center">
                            <div className="text-4xl mb-2">🧘‍♀️</div>
                            <span className="text-gray-500 text-sm">Video not available</span>
                        </div>
                    </div>
                ) : (
                    <div className="relative h-full">
                        <video
                            src={nft.videoUrl}
                            className={`w-full h-full object-cover transition-opacity duration-300 ${
                                videoLoading ? 'opacity-0' : 'opacity-100'
                            }`}
                            onLoadedData={handleVideoLoad}
                            onError={handleVideoError}
                            muted
                            preload="metadata"
                            poster="" // Rimuovi poster di default
                        />

                        {/* Token ID Badge */}
                        <div className="absolute top-3 right-3 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded-full">
                            #{nft.tokenId}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};
