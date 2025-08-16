import { configureStore } from '@reduxjs/toolkit';
import { currentPageReducer } from './pagesSlice';
import { selectedNftReducer } from './selectedNftSlice';

export default configureStore({
    reducer: {
        currentPage: currentPageReducer,
        selectedNft: selectedNftReducer,
    },
});
