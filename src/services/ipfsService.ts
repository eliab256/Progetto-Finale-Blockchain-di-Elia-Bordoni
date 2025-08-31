import type { NftMetadata } from '../types/nftTypes';
import { IPFS_GATEWAYS, getIpfsUrl, extractCidFromUri } from '../utils/ipfsUtils';
import type { NftMetadataWithVideo } from '../types/nftTypes';

const metadataCache = new Map<string, NftMetadata>();

const getErrorMessage = (error: unknown): string => {
    if (error instanceof Error) return error.message;
    if (typeof error === 'string') return error;
    return 'Unknown error occurred';
};

// ==================== FETCH METADATA ====================
export const fetchMetadata = async (
    ipfsUri: string,
    useCache = true,
    timeout = 10000
): Promise<NftMetadataWithVideo> => {
    // === STEP 1: Check Cache ===
    if (useCache && metadataCache.has(ipfsUri)) {
        const cached = metadataCache.get(ipfsUri)!;
        return { nftMetadata: cached, videoUrl: cached.image };
    }

    // === STEP 2: Preliminary validations ===
    if (!ipfsUri || !ipfsUri.startsWith('ipfs://')) {
        throw new Error('Invalid IPFS URI: must start with ipfs://');
    }

    let lastError: Error | null = null;

    // === STEP 3: Retry Logic with Multiple Gateways ===
    for (let i = 0; i < IPFS_GATEWAYS.length; i++) {
        try {
            console.log(`Trying gateway ${i + 1}/${IPFS_GATEWAYS.length}`);

            const cid = extractCidFromUri(ipfsUri);
            const url = getIpfsUrl(cid, i);

            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), timeout);

            const response = await fetch(url, {
                signal: controller.signal,
                headers: { Accept: 'application/json', 'Cache-Control': 'no-cache' },
            });

            clearTimeout(timeoutId);

            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const jsonData: NftMetadata = await response.json();

            if (useCache) metadataCache.set(ipfsUri, jsonData);

            // === VIDEO URL ===
            const videoCid = extractCidFromUri(jsonData.image);
            const videoUrl = getIpfsUrl(videoCid, i);

            const videoController = new AbortController();
            const videoTimeoutId = setTimeout(() => videoController.abort(), timeout);

            const videoResponse = await fetch(videoUrl, { signal: videoController.signal });
            clearTimeout(videoTimeoutId);

            if (!videoResponse.ok) throw new Error(`Video HTTP ${videoResponse.status}`);

            return { nftMetadata: jsonData, videoUrl: videoResponse.url };
        } catch (error) {
            lastError = new Error(`Gateway ${i + 1} failed: ${getErrorMessage(error)}`);
            console.warn(lastError.message);
        }
    }

    throw new Error(`Failed to fetch metadata/video from all gateways. Last error: ${lastError?.message}`);
};

// ==================== FETCH BY TOKEN ID ====================
export const fetchMetadataById = async (ipfsBaseUri: string, tokenId: number): Promise<NftMetadataWithVideo> => {
    if (tokenId < 0 || !Number.isInteger(tokenId)) {
        throw new Error('Token ID must be a non-negative integer');
    }

    const ipfsUri = `${ipfsBaseUri}/${tokenId}.json`;
    console.log(`Fetching metadata for token #${tokenId}`);
    return fetchMetadata(ipfsUri);
};

// ==================== PRELOAD ====================
export const preloadMetadata = async (ipfsBaseUri: string, tokenIds: number[]): Promise<void> => {
    if (tokenIds.length === 0) {
        console.warn('No token IDs provided for preloading');
        return;
    }

    console.log(`Starting preload for ${tokenIds.length} tokens`);

    const promises = tokenIds.map(async id => {
        try {
            await fetchMetadataById(ipfsBaseUri, id);
            console.log(`Preloaded token #${id}`);
        } catch (error) {
            console.warn(`Failed to preload token #${id}:`, getErrorMessage(error));
        }
    });

    await Promise.allSettled(promises);
    console.log(`Preload completed. Cache size: ${metadataCache.size}`);
};

// ==================== CACHE MANAGEMENT ====================
export const clearMetadataCache = (): void => {
    const oldSize = metadataCache.size;
    metadataCache.clear();
    console.log(`Cache cleared. Removed ${oldSize} entries`);
};

export const removeFromCache = (ipfsUri: string): boolean => {
    const wasPresent = metadataCache.has(ipfsUri);
    metadataCache.delete(ipfsUri);
    if (wasPresent) console.log(`Removed from cache: ${ipfsUri}`);
    return wasPresent;
};

export const isMetadataCached = (ipfsUri: string): boolean => metadataCache.has(ipfsUri);

export const isTokenCached = (ipfsBaseUri: string, tokenId: number): boolean => {
    const ipfsUri = `${ipfsBaseUri}${tokenId}.json`;
    return metadataCache.has(ipfsUri);
};

export const getCacheStats = (): {
    size: number;
    keys: string[];
    memoryUsage: string;
} => {
    const keys = Array.from(metadataCache.keys());
    const estimatedSize = JSON.stringify(Array.from(metadataCache.values())).length;
    const memoryUsage = `~${(estimatedSize / 1024).toFixed(2)} KB`;

    return { size: metadataCache.size, keys, memoryUsage };
};

// ==================== FETCH MULTIPLE ====================
export const fetchMultipleMetadata = async (
    ipfsBaseUri: string,
    tokenIds: number[],
    maxConcurrent = 5
): Promise<Array<{ tokenId: number; metadata?: NftMetadataWithVideo; error?: string }>> => {
    const results: Array<{ tokenId: number; metadata?: NftMetadataWithVideo; error?: string }> = [];

    for (let i = 0; i < tokenIds.length; i += maxConcurrent) {
        const batch = tokenIds.slice(i, i + maxConcurrent);

        const batchPromises = batch.map(async tokenId => {
            try {
                const metadata = await fetchMetadataById(ipfsBaseUri, tokenId);
                return { tokenId, metadata };
            } catch (error) {
                return { tokenId, error: getErrorMessage(error) };
            }
        });

        results.push(...(await Promise.all(batchPromises)));
    }

    return results;
};

// ==================== EXPORT DEFAULT ====================
export default {
    fetchMetadata,
    fetchMetadataById,
    preloadMetadata,
    fetchMultipleMetadata,
    clearMetadataCache,
    removeFromCache,
    isMetadataCached,
    isTokenCached,
    getCacheStats,
};
