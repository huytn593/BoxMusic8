import 'bootstrap/dist/css/bootstrap.min.css';
import { Link } from 'react-router-dom';

const mainButtonStyle = {
    borderRadius: '2rem',
    fontSize: '1.15rem',
    fontWeight: 600,
    padding: '0.75rem 2.5rem',
    boxShadow: '0 2px 8px rgba(0,0,0,0.08)'
};

export default function HomePage() {
    return (
        <div className="home-page">
            {/* Hero Section */}
            <div className="hero-section text-white py-5" style={{ 
                background: 'linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.7)), url("/images/hero-bg.jpg")',
                backgroundSize: 'cover',
                backgroundPosition: 'center'
            }}>
                <div className="container">
                    <div className="row min-vh-50 align-items-center">
                        <div className="col-lg-6">
                            <h1 className="display-4 fw-bold mb-4">Khám phá âm nhạc mới</h1>
                            <p className="lead mb-4">Nghe nhạc trực tuyến miễn phí. Khám phá hàng triệu bài hát và playlist từ các nghệ sĩ trên toàn thế giới.</p>
                            <Link to="/signup" className="btn btn-danger btn-lg px-4 py-2" style={mainButtonStyle}>
                                Bắt đầu ngay
                            </Link>
                        </div>
                    </div>
                </div>
            </div>

            {/* Explore Trending Playlists Button */}
            <div className="explore-section py-5 bg-black text-center">
                <h3 className="text-white mb-4" style={{fontSize: '2rem', fontWeight: 700}}>Khám phá những gì đang thịnh hành trong cộng đồng Musicresu</h3>
                <Link to="/discover" className="btn btn-light btn-lg fw-bold mb-4" style={mainButtonStyle}>
                    Khám phá playlist đang thịnh hành
                </Link>
            </div>

            {/* Never stop listening Section - background image with overlay text */}
            <div
                className="never-stop-listening-section d-flex align-items-center justify-content-center position-relative"
                style={{
                    minHeight: 560,
                    width: '100%',
                    backgroundImage: 'url(/images/Neverstoplistening.png)',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    backgroundRepeat: 'no-repeat',
                    boxShadow: '0 2px 16px rgba(0,0,0,0.08)',
                }}
            >
                <div
                    className="position-absolute top-0 start-0 w-100 h-100"
                    style={{
                        background: 'rgba(0,0,0,0.25)',
                        zIndex: 1,
                    }}
                ></div>
                <div
                    className="text-center text-white position-relative"
                    style={{
                        zIndex: 2,
                        maxWidth: 700,
                        margin: '0 auto',
                        padding: '32px',
                    }}
                >
                    <h2 className="fw-bold mb-3" style={{fontSize: '3rem', textShadow: '0 2px 8px rgba(0,0,0,0.25)'}}>Âm nhạc không bao giờ dừng</h2>
                    <p className="lead mb-0" style={{fontSize: '1.5rem', fontWeight: 500, lineHeight: 1.5, textShadow: '0 2px 8px rgba(0,0,0,0.18)'}}>
                        Musicresu luôn sẵn sàng cho bạn. Thưởng thức bài hát yêu thích của bạn bất cứ lúc nào, ở đâu, trên bất kỳ thiết bị nào.
                    </p>
                </div>
            </div>

            {/* Thanks for listening. Now join in. Section */}
            <div className="thanks-section py-5 bg-black text-white text-center">
                <div className="container">
                    <h2 className="fw-bold mb-3" style={{fontSize: '2.4rem'}}>Cảm ơn vì đã lắng nghe. Giờ là lúc tham gia.</h2>
                    <p className="mb-4" style={{fontSize: '1.2rem'}}>Lưu bài hát, theo dõi nghệ sĩ và tạo playlist. Tất cả miễn phí.</p>
                    <Link to="/signup" className="btn btn-light btn-lg fw-bold mb-3" style={mainButtonStyle}>
                        Tạo tài khoản
                    </Link>
                    <div className="mt-2">
                        <span className="text-secondary">Đã có tài khoản? </span>
                        <Link to="/signin" className="fw-bold text-white text-decoration-underline">Đăng nhập</Link>
                    </div>
                </div>
            </div>
            {/* Privacy Policy Banner */}
            <div className="privacy-policy-banner text-center py-3" style={{ background: '#18191c', color: '#fff', marginTop: '0', borderTop: '1px solid #222' }}>
                <Link to="/policy" style={{ color: '#ff3b3f', fontWeight: 600, textDecoration: 'underline', fontSize: '1.1rem' }}>
                    Xem Chính sách Quyền riêng tư của chúng tôi
                </Link>
            </div>
        </div>
    );
}
