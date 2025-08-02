import './assets/styles/App.css';
import Header from './componentes/Header';
import Gallery from './componentes/Gallery';
import CurrentAuction from './componentes/CurrentAuction';
import MyNfts from './componentes/MyNfts';
import AboutUs from './componentes/AboutUs';
import Footer from './componentes/Footer';
import { useSelector } from 'react-redux';
import { type PageState } from './redux/pagesSlice';

function App() {
    const currentOpenPage = useSelector(
        (state: { currentPage: { currentPage: PageState } }) => state.currentPage.currentPage
    );

    const pageComponents = {
        gallery: <Gallery />,
        currentAuction: <CurrentAuction />,
        myNfts: <MyNfts />,
        aboutUs: <AboutUs />,
    };

    return (
        <>
            <Header />
            <main>{pageComponents[currentOpenPage]}</main>
            <Footer />
        </>
    );
}

export default App;
