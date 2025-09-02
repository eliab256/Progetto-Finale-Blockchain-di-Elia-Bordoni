import { useState, useEffect } from 'react';
import type { NftMetadata } from '../types/nftTypes';
import { fetchMetadata } from '../services/ipfsService';

export const useNftMetadata = (tokenURI: string | undefined) => {
    const [metadata, setMetadata] = useState<NftMetadata | null>(null);
    const [videoUrl, setVideoUrl] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (!tokenURI) {
            setMetadata(null);
            setVideoUrl(null);
            return;
        }

        const loadMetadata = async () => {
            try {
                setLoading(true);
                setError(null);
                const result = await fetchMetadata(tokenURI);
                setMetadata(result.nftMetadata);
                setVideoUrl(result.videoUrl);
            } catch (err) {
                setError(err instanceof Error ? err.message : 'Failed to fetch metadata');
            } finally {
                setLoading(false);
            }
        };

        loadMetadata();
    }, [tokenURI]);

    return { metadata, videoUrl, loading, error };
};
