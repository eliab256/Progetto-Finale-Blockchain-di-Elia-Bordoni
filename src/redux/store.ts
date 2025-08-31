import { configureStore } from '@reduxjs/toolkit';
import { currentPageReducer } from './pagesSlice';
import { selectedNftReducer } from './selectedNftSlice';
import { nftLoadingDataReducer } from './nftLoadingDataSlice';

const store = configureStore({
    reducer: {
        currentPage: currentPageReducer,
        selectedNft: selectedNftReducer,
        nftLoadingData: nftLoadingDataReducer,
    },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export default store;
