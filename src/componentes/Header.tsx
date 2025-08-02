import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useDispatch } from 'react-redux';
import { setCurrentPage } from '../redux/pagesSlice';
import logoImage from '../assets/images/Yoyo-Logo-Scritta-Scura.png';
import '../assets/styles/Header.css';

const Header: React.FC = () => {
    const dispatch = useDispatch();
    return (
        <header>
            <div className="headerButtonContainer">
                <div onClick={() => dispatch(setCurrentPage('gallery'))} role="button" className="headerButton">
                    <img src={logoImage} alt="yoyo logo image"></img>
                </div>

                <div className="headerButton">
                    <button onClick={() => dispatch(setCurrentPage('currentAuction'))}>Auction</button>
                </div>
                <div className="headerButton">
                    <button onClick={() => dispatch(setCurrentPage('myNfts'))}>My NFTs</button>
                </div>
                <div className="headerButton">
                    <button onClick={() => dispatch(setCurrentPage('aboutUs'))}>About Us</button>
                </div>
            </div>

            <div className="headerButton">
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
