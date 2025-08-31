import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from './store';

export type PageState = 'gallery' | 'myNfts' | 'currentAuction' | 'aboutUs';

interface CurrentPageState {
    currentPage: PageState;
}

const initialState: CurrentPageState = {
    currentPage: 'gallery',
};

export const currentPageSlice = createSlice({
    name: 'currentPage',
    initialState,
    reducers: {
        setCurrentPage: (state, action: PayloadAction<PageState>) => {
            state.currentPage = action.payload;
        },
    },
});

export const { setCurrentPage } = currentPageSlice.actions;

export const currentPageReducer = currentPageSlice.reducer;

export const selectCurrentPage = (state: RootState) => state.currentPage.currentPage;
