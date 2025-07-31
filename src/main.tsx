import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './assets/styles/index.css';
import Providers from './providers.tsx';
import App from './App.tsx';

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <Providers>
            <App />
        </Providers>
    </StrictMode>
);
