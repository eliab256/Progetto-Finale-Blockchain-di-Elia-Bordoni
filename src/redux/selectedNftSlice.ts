import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

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
