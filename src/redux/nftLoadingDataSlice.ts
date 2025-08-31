import { createSlice, createAsyncThunk, type PayloadAction } from '@reduxjs/toolkit';
import { fetchMetadataById } from '../services/ipfsService';
import type { RootState } from './store';
import type { NftMetadataWithVideo } from '../types/nftTypes';

interface NftState {
    data: Record<string, NftMetadataWithVideo>; // key: `${baseURI}-${tokenId}`
    loading: Record<string, boolean>;
    errors: Record<string, string>;
}

const initialState: NftState = {
    data: {},
    loading: {},
    errors: {},
};

const makeKey = (baseURI: string, tokenId: number) => `${baseURI}-${tokenId}`;

// ==================== ASYNC THUNK ====================
export const fetchNftMetadata = createAsyncThunk(
    'nft/fetchMetadata',
    async ({ baseURI, tokenId }: { baseURI: string; tokenId: number }, { rejectWithValue }) => {
        try {
            const result = await fetchMetadataById(baseURI, tokenId);
            return { key: makeKey(baseURI, tokenId), data: result };
        } catch (error) {
            const msg = error instanceof Error ? error.message : 'Unknown error';
            return rejectWithValue({ key: makeKey(baseURI, tokenId), error: msg });
        }
    }
);

// ==================== SLICE ====================
export const nftLoadingDataSlice = createSlice({
    name: 'nftLoadingData',
    initialState,
    reducers: {
        clearError: (state, action: PayloadAction<string>) => {
            delete state.errors[action.payload];
        },
        clearNftData: (state, action: PayloadAction<string>) => {
            delete state.data[action.payload];
            delete state.loading[action.payload];
            delete state.errors[action.payload];
        },
    },
    extraReducers: builder => {
        builder
            .addCase(fetchNftMetadata.pending, (state, action) => {
                const key = `${action.meta.arg.baseURI}-${action.meta.arg.tokenId}`;
                state.loading[key] = true;
                delete state.errors[key];
            })
            .addCase(fetchNftMetadata.fulfilled, (state, action) => {
                const { key, data } = action.payload;
                state.data[key] = data;
                state.loading[key] = false;
            })
            .addCase(fetchNftMetadata.rejected, (state, action) => {
                const { key, error } = action.payload as { key: string; error: string };
                state.loading[key] = false;
                state.errors[key] = error;
            });
    },
});

export const { clearError, clearNftData } = nftLoadingDataSlice.actions;
export const nftLoadingDataReducer = nftLoadingDataSlice.reducer;

// ==================== SELECTORS ====================
export const selectNftData = (state: RootState, baseURI: string, tokenId: number) => {
    const key = `${baseURI}-${tokenId}`;
    return state.nftLoadingData.data[key];
};

export const selectNftLoading = (state: RootState, baseURI: string, tokenId: number) => {
    const key = `${baseURI}-${tokenId}`;
    return state.nftLoadingData.loading[key] || false;
};

export const selectNftError = (state: RootState, baseURI: string, tokenId: number) => {
    const key = `${baseURI}-${tokenId}`;
    return state.nftLoadingData.errors[key];
};
