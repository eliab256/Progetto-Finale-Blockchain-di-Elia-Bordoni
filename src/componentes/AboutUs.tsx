import logoImage from '../assets/images/Yoyo-Logo-Scritta-Scura.png';
import '../assets/styles/AboutUs.css';

const AboutUs: React.FC = () => {
    return (
        <div className="aboutUsContainer">
            <div className="logoImageContainer">
                <img src={logoImage} alt="yoyo logo image"></img>
            </div>
            <div className="descriptionContainer">
                <h1>About Us</h1>
                <p>
                    YoYo is an inclusive yoga platform created from a personal journey — inspired by the founder' s
                    sister, who faced permanent mobility challenges after an accident. What began as a search for
                    accessible movement has grown into a mission to make yoga truly available to everyone. With the help
                    of yoga teachers, physiotherapists, and wellness experts, YoYo offers personalized programs tailored
                    to each user's physical needs. Whether you're a beginner, pregnant, using prosthetics, or dealing
                    with mobility issues, YoYo adapts to you. To push the experience further, YoYo integrates NFT
                    technology, allowing users to unlock exclusive content, redeem rewards, and join themed events —
                    making the practice of yoga more connected, inclusive, and future-ready.
                </p>
            </div>
        </div>
    );
};

export default AboutUs;
