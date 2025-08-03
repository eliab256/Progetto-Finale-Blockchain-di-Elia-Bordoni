import '../assets/styles/Footer.css';

const Footer: React.FC = () => {
    return (
        <footer>
            <div className="footerContainer">
                <div className="footerContent">
                    <ul className="footerMenu">
                        <div className="footerColumn">
                            <div className="footerLinks">
                                <div className="footerLink">
                                    <a href="https://github.com/eliab256" target="_blank" rel="noreferrer">
                                        GitHub
                                    </a>
                                </div>
                                <span className="footerSeparator">·</span>
                                <div className="footerLink">
                                    <a href="https://t.me/Elia_EB" target="_blank" rel="noreferrer">
                                        Support
                                    </a>
                                </div>
                            </div>

                            <div className="footerCopyright">
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
