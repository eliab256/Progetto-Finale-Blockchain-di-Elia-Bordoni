import { useAccount } from 'wagmi';

const MyNfts: React.FC = () => {
    const { isConnected } = useAccount();
    return (
        <div>
            <div>
                <h1>My Nfts</h1>
            </div>
            <div>
                {/* wallet is not connected */}
                {!isConnected && (
                    <div>
                        <div>
                            <h2>Wallet not connected</h2>
                            <p>Please connect your wallet to view your products.</p>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default MyNfts;
