import Navbar from './Navbar';
import Footer from './Footer';

const MainLayout = ({ children }) => {
    return (
        <div className="d-flex flex-column min-vh-100"
            style={{
                backgroundImage: `url('/images/background.jpg')`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                backgroundRepeat: 'no-repeat',
                color: 'white',
            }}
        >
            <Navbar />
            <main className="flex-fill" style={{ paddingTop: '90px' }}>
                {children}
            </main>
            <Footer />
        </div>
    );
};

export default MainLayout;