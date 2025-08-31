import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from './store';

export type NftTokenId = number | null;

interface SelectedNftState {
    id: NftTokenId;
}

const initialState: SelectedNftState = {
    id: null,
};

export const selectedNftSlice = createSlice({
    name: 'selectedNftSlice',
    initialState,
    reducers: {
        setSelectedNft: (state, action: PayloadAction<NftTokenId>) => {
            state.id = action.payload;
        },
        clearSelectedNft: state => {
            state.id = null;
        },
    },
});

export const { setSelectedNft, clearSelectedNft } = selectedNftSlice.actions;

export const selectedNftReducer = selectedNftSlice.reducer;

export const selectSelectedNftId = (state: RootState) => state.selectedNft.id;
