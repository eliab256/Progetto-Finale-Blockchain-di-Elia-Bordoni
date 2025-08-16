import type { Attribute, Properties, YogaCourseMetadata } from '../types/NftMetadataTypes';

const IPFS_GATEWAYS = [
    'https://ipfs.io/ipfs/', // main Gateway
    'https://cloudflare-ipfs.com/ipfs/', // backup 1
    'https://gateway.pinata.cloud/ipfs/', // backup 2
];

const metadataCache = new Map<string, YogaCourseMetadata>();

// ==================== UTILITY FUNCTIONS ====================

const ipfsToHttp = (ipfsUri: string, gatewayIndex = 0): string => {
    const hash = ipfsUri.replace('ipfs://', '');
    return `${IPFS_GATEWAYS[gatewayIndex]}${hash}`;
};

const validateMetadata = (data: unknown): YogaCourseMetadata => {
    const metadata = data as Record<string, unknown>;

    if (
        !metadata.name ||
        typeof metadata.name !== 'string' ||
        !metadata.description ||
        typeof metadata.description !== 'string' ||
        !metadata.image ||
        typeof metadata.image !== 'string'
    ) {
        throw new Error('Missing or invalid required fields: name, description, and image must be strings');
    }

    let attributes: Attribute[] = [];
    if (Array.isArray(metadata.attributes)) {
        attributes = metadata.attributes.map((attr: unknown, index: number) => {
            if (attr && typeof attr === 'object') {
                const typedAttr = attr as Record<string, unknown>;
                return {
                    trait_type: String(typedAttr.trait_type || `attribute_${index}`),
                    value: (typedAttr.value as string | number) || '',
                };
            }
            // Fallback
            return { trait_type: `attribute_${index}`, value: '' };
        });
    }

    let properties: Properties = {
        category: '',
        course_type: '',
        accessibility_level: '',
        redeemable: false,
        instructor_certified: false,
        style: '',
    };

    if (metadata.properties && typeof metadata.properties === 'object') {
        const props = metadata.properties as Record<string, unknown>;
        properties = {
            category: String(props.category || ''),
            course_type: String(props.course_type || ''),
            accessibility_level: String(props.accessibility_level || ''),
            redeemable: Boolean(props.redeemable),
            instructor_certified: Boolean(props.instructor_certified),
            style: String(props.style || ''),
        };
    }

    return {
        name: metadata.name as string,
        description: metadata.description as string,
        image: metadata.image as string,
        attributes,
        properties,
    };
};

const getErrorMessage = (error: unknown): string => {
    if (error instanceof Error) {
        return error.message;
    }
    if (typeof error === 'string') {
        return error;
    }
    return 'Unknown error occurred';
};

// ==================== CORE FUNCTIONS ====================

export const fetchMetadata = async (ipfsUri: string, useCache = true, timeout = 10000): Promise<YogaCourseMetadata> => {
    // === STEP 1: Check Cache ===
    if (useCache && metadataCache.has(ipfsUri)) {
        console.log(`Cache hit for: ${ipfsUri}`);
        return metadataCache.get(ipfsUri)!;
    }

    // === STEP 2: Preliminary validations ===
    if (IPFS_GATEWAYS.length === 0) {
        throw new Error('No IPFS gateways configured');
    }

    if (!ipfsUri || !ipfsUri.startsWith('ipfs://')) {
        throw new Error('Invalid IPFS URI: must start with ipfs://');
    }

    let lastError: Error | null = null;

    // === STEP 3: Retry Logic with Multiple Gateways ===
    for (let i = 0; i < IPFS_GATEWAYS.length; i++) {
        try {
            console.log(`Trying gateway ${i + 1}/${IPFS_GATEWAYS.length}: ${IPFS_GATEWAYS[i]}`);

            const url = ipfsToHttp(ipfsUri, i);

            // === STEP 4: Fetch with Timeout ===
            const controller = new AbortController();
            const timeoutId = setTimeout(() => {
                console.log(`Timeout reached for gateway ${i + 1}`);
                controller.abort();
            }, timeout);

            const response = await fetch(url, {
                signal: controller.signal,
                headers: {
                    Accept: 'application/json',
                    'Cache-Control': 'no-cache', // Avoid browser caching
                },
            });

            clearTimeout(timeoutId);

            // === STEP 5: Response Validation ===
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            // === STEP 6: Parse and Validate JSON ===
            const rawData = await response.json();
            const validatedData = validateMetadata(rawData);

            // === STEP 7: Success - Cache and Return ===
            if (useCache) {
                metadataCache.set(ipfsUri, validatedData);
                console.log(`Metadata cached successfully from gateway ${i + 1}`);
            }

            console.log(`Successfully fetched metadata: ${validatedData.name}`);
            return validatedData;
        } catch (error) {
            const errorMessage = getErrorMessage(error);
            lastError = new Error(`Gateway ${i + 1} failed: ${errorMessage}`);
            console.warn(` Gateway ${i + 1}/${IPFS_GATEWAYS.length} failed:`, errorMessage);
        }
    }

    // === STEP 8: All gateways failed ===
    const finalError = `Failed to fetch metadata from all ${IPFS_GATEWAYS.length} gateways. Last error: ${
        lastError?.message || 'Unknown error'
    }`;
    console.error(finalError);
    throw new Error(finalError);
};

export const fetchMetadataById = async (ipfsBaseUri: string, tokenId: number): Promise<YogaCourseMetadata> => {
    if (tokenId < 0 || !Number.isInteger(tokenId)) {
        throw new Error('Token ID must be a non-negative integer');
    }

    const ipfsUri = `${ipfsBaseUri}${tokenId}.json`;
    console.log(`Fetching metadata for token #${tokenId}`);
    return fetchMetadata(ipfsUri);
};

// ==================== OPTIMIZATION FUNCTIONS ====================
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
            const errorMessage = getErrorMessage(error);
            console.warn(`Failed to preload token #${id}:`, errorMessage);
        }
    });

    // Wait for all requests to complete (success or failure)
    await Promise.allSettled(promises);
    console.log(`Preload completed. Cache size: ${metadataCache.size}`);
};

// ==================== CACHE MANAGEMENT ====================
export const clearMetadataCache = (): void => {
    const oldSize = metadataCache.size;
    metadataCache.clear();
    console.log(`Cache cleared. Removed ${oldSize} entries`);
};

/**
 * Removes a single item from the cache
 */
export const removeFromCache = (ipfsUri: string): boolean => {
    const wasPresent = metadataCache.has(ipfsUri);
    metadataCache.delete(ipfsUri);
    if (wasPresent) {
        console.log(`Removed from cache: ${ipfsUri}`);
    }
    return wasPresent;
};

/**
 * Checks if metadata is present in cache
 */
export const isMetadataCached = (ipfsUri: string): boolean => {
    return metadataCache.has(ipfsUri);
};

/**
 * Checks if a token ID is present in cache
 */
export const isTokenCached = (ipfsBaseUri: string, tokenId: number): boolean => {
    const ipfsUri = `${ipfsBaseUri}${tokenId}.json`;
    return metadataCache.has(ipfsUri);
};

/**
 * Gets detailed cache statistics
 */
export const getCacheStats = (): {
    size: number;
    keys: string[];
    memoryUsage: string;
    hitRate?: number;
} => {
    const keys = Array.from(metadataCache.keys());

    // Approximate memory usage estimate
    const estimatedSize = JSON.stringify(Array.from(metadataCache.values())).length;
    const memoryUsage = `~${(estimatedSize / 1024).toFixed(2)} KB`;

    return {
        size: metadataCache.size,
        keys,
        memoryUsage,
    };
};

export const fetchMultipleMetadata = async (
    ipfsBaseUri: string,
    tokenIds: number[],
    maxConcurrent = 5
): Promise<Array<{ tokenId: number; metadata?: YogaCourseMetadata; error?: string }>> => {
    const results: Array<{ tokenId: number; metadata?: YogaCourseMetadata; error?: string }> = [];

    // Process in batches to avoid overload
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

        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);
    }

    return results;
};

// ==================== EXPORTS ====================

export default {
    // Core functions
    fetchMetadata,
    fetchMetadataById,

    // Optimization
    preloadMetadata,
    fetchMultipleMetadata,

    // Cache management
    clearMetadataCache,
    removeFromCache,
    isMetadataCached,
    isTokenCached,
    getCacheStats,

    // Utilities
    IPFS_GATEWAYS,
};
