import { useState, useEffect } from 'react';

// Global Cache
const cache = {
    price: null as number | null,
    timestamp: 0,
    error: null as string | null,
};

const CACHE_DURATION = 600000; // 10 minutes in milliseconds

export const useEthereumPrice = () => {
    const [price, setPrice] = useState<number>(cache.price || 0);
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(cache.error);

    useEffect(() => {
        const fetchPrice = async () => {
            const now = Date.now();

            // Check if we have a valid cached price
            if (cache.price && cache.error === null && now - cache.timestamp < CACHE_DURATION) {
                setPrice(cache.price);
                setError(null);
                setLoading(false);
                return;
            }

            try {
                setLoading(true);
                const response = await fetch(
                    'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd'
                );

                if (!response.ok) throw new Error('Failed to fetch');

                const data = await response.json();

                // Update cache
                cache.price = data.ethereum.usd;
                cache.timestamp = now;
                cache.error = null;

                // Update state
                setPrice(data.ethereum.usd);
                setError(null);
            } catch (err) {
                const errorMessage = 'Failed to fetch ETH price';

                // If we have a cached price, use it as a fallback
                if (cache.price) {
                    console.log('API error, used cached price');
                    setPrice(cache.price);
                    setError(`${errorMessage} (usando dato cached)`);
                } else {
                    cache.error = errorMessage;
                    setError(errorMessage);
                }

                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        fetchPrice();
    }, []);

    return {
        price,
        loading,
        error,
        isCached: cache.price !== null && Date.now() - cache.timestamp < CACHE_DURATION,
    };
};
