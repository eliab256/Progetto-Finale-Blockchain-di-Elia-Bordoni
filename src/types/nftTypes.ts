export interface NftMetadata {
    name: string;
    description: string;
    image: string; // CID of video MP4 "ipfs://..."
    attributes: Array<{
        trait_type: string;
        value: string | number;
    }>;
    properties: {
        category: string;
        course_type: string;
        accessibility_level: string;
        redeemable: boolean;
        instructor_certified: boolean;
        style: string;
    };
}

export interface NftData {
    tokenId: number;
    tokenURI: string;
    metadata: NftMetadata;
    videoUrl: string;
    owner?: string;
}

export interface NftMetadataWithVideo {
    nftMetadata: NftMetadata;
    videoUrl: string;
}
