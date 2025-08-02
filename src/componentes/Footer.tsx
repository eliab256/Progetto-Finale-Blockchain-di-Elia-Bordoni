import '../assets/styles/Footer.css';

const Footer: React.FC = () => {
    return (
        <footer>
            <div className="footer-container">
                <div className="footer-content">
                    <ul className="footer-menu">
                        <div className="footer-column">
                            <div className="footer-links">
                                <div className="footer-link">
                                    <a href="https://github.com/eliab256" target="_blank" rel="noreferrer">
                                        GitHub
                                    </a>
                                </div>
                                <span className="footer-separator">·</span>
                                <div className="footer-link">
                                    <a href="https://t.me/Elia_EB" target="_blank" rel="noreferrer">
                                        Support
                                    </a>
                                </div>
                            </div>

                            <div className="footer-copyright">
                                <p>© 2025 Elia Bordoni. All rights reserved.</p>
                            </div>
                        </div>
                    </ul>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
