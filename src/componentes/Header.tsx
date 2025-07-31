import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useDispatch } from 'react-redux';
import { setCurrentPage } from '../redux/pagesSlice';

const Header: React.FC = () => {
    const dispatch = useDispatch();
    return (
        <header className="p-2 md:p-4 flex items-center justify-between fixed top-0 left-0 w-full bg-white shadow-md z-50 h-12 sm:h-14 md:h-14 lg:h-16 xl:h-18">
            <div onClick={() => dispatch(setCurrentPage('gallery'))} role="button">
                <img></img>
            </div>
            <div>
                <button
                    className="bg-green-500 text-black px-3 md:px-4 py-2 rounded-xl hover:bg-green-300 cursor-pointer text-sm sm:text-base md:text-lg lg:text-xl"
                    onClick={() => dispatch(setCurrentPage('auction'))}
                >
                    Auction
                </button>
            </div>
            <div>
                <button
                    className="bg-green-500 text-black px-3 md:px-4 py-2 rounded-xl hover:bg-green-300 cursor-pointer text-sm sm:text-base md:text-lg lg:text-xl"
                    onClick={() => dispatch(setCurrentPage('myNfts'))}
                >
                    My NFTs
                </button>
            </div>
            <div>
                <button
                    className="bg-green-500 text-black px-3 md:px-4 py-2 rounded-xl hover:bg-green-300 cursor-pointer text-sm sm:text-base md:text-lg lg:text-xl"
                    onClick={() => dispatch(setCurrentPage('aboutUs'))}
                >
                    About Us
                </button>
            </div>
            <div className="w-[84px] md:w-auto text-sm md:text-lg lg:text-xl">
                <ConnectButton
                    accountStatus={{
                        smallScreen: 'avatar',
                        largeScreen: 'full',
                    }}
                    showBalance={{
                        smallScreen: false,
                        largeScreen: true,
                    }}
                />
            </div>
        </header>
    );
};

export default Header;
