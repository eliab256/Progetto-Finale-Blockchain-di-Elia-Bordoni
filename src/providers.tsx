import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { type ReactNode } from 'react';
import config from './rainbowkitConfig';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import { useState } from 'react';
import { Provider } from 'react-redux';
import store from './redux/store';
import '@rainbow-me/rainbowkit/styles.css';

const Providers = (props: { children: ReactNode }) => {
    const [queryClient] = useState(() => new QueryClient());

    return (
        <Provider store={store}>
            <QueryClientProvider client={queryClient}>
                <WagmiProvider config={config}>
                    <RainbowKitProvider
                        theme={darkTheme({
                            accentColor: '#825FAA',
                        })}
                    >
                        {props.children}
                    </RainbowKitProvider>
                </WagmiProvider>
            </QueryClientProvider>
        </Provider>
    );
};

export default Providers;
