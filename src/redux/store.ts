import { configureStore } from '@reduxjs/toolkit';
import { currentPageReducer } from './pagesSlice';

export default configureStore({
    reducer: {
        currentPage: currentPageReducer,
    },
});
