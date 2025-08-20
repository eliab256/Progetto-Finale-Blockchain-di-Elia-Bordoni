export const IPFS_GATEWAYS = [
    'https://ipfs.io/ipfs/', // main Gateway
    'https://cloudflare-ipfs.com/ipfs/', // backup 1
    'https://gateway.pinata.cloud/ipfs/', // backup 2
];

export const getIpfsUrl = (cid: string, gatewayIndex = 0): string => {
    return `${IPFS_GATEWAYS[gatewayIndex]}${cid}`;
};

export const extractCidFromUri = (uri: string): string => {
    return uri.replace('ipfs://', '');
};

export const buildVideoUrl = (videoCid: string): string => {
    const cleanCid = extractCidFromUri(videoCid);
    return getIpfsUrl(cleanCid);
};

// Utility to get the file format from the URL
export const getFileExtension = (url: string): string => {
    return url.split('.').pop()?.toLowerCase() || '';
};

// Check if it's a video
export const isVideoFile = (url: string): boolean => {
    const videoExtensions = ['mp4', 'webm', 'ogg', 'mov', 'avi'];
    return videoExtensions.includes(getFileExtension(url));
};
