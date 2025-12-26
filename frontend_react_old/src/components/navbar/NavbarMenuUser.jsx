// components/navbar/NavbarMenuUser.jsx
import React from "react";
import { Link } from "react-router-dom";

const NavbarMenuUser = ({ isActive, user, onRequireSignin, searchTerm, setSearchTerm, handleSearchSubmit }) => (
    <>
        <li className="nav-item">
            <Link to="/" className={`nav-link ${isActive("/") ? "active text-danger fw-semibold" : "text-secondary"}`}>Trang chủ</Link>
        </li>
        <li className="nav-item">
            <Link to="/discover" className={`nav-link ${isActive("/discover") ? "active text-danger fw-semibold" : "text-secondary"}`}>Khám phá</Link>
        </li>
        <li className="nav-item">
            {user?.isLoggedIn ? (
                <Link to="/upload" className={`nav-link ${isActive("/upload") ? "active text-danger fw-semibold" : "text-secondary"}`}>Tải lên</Link>
            ) : (
                <span className="nav-link text-secondary" style={{ cursor: 'pointer' }} onClick={onRequireSignin}>Tải lên</span>
            )}
        </li>
        <li className="nav-item">
            {user?.isLoggedIn ? (
                <Link to={`/recommend/${user.id}`} className={`nav-link ${isActive("/recommend") ? "active text-danger fw-semibold" : "text-secondary"}`}>Dành cho bạn</Link>
            ) : (
                <span className="nav-link text-secondary" style={{ cursor: 'pointer' }} onClick={onRequireSignin}>Dành cho bạn</span>
            )}
        </li>
        <li className="nav-item">
            <form onSubmit={handleSearchSubmit} className="d-flex align-items-center" style={{ width: '500px', position: 'relative' }}>
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="16"
                    height="16"
                    fill="gray"
                    className="bi bi-search"
                    viewBox="0 0 16 16"
                    style={{
                        position: 'absolute',
                        left: '10px',
                        pointerEvents: 'none',
                    }}
                >
                    <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001l3.85 3.85a1 1 0 0 0 1.415-1.415l-3.85-3.85zm-5.242 1.06a5 5 0 1 1 0-10 5 5 0 0 1 0 10z" />
                </svg>
                <input
                    type="text"
                    className="form-control"
                    placeholder="Nhập tên bài hát hoặc tên người dùng..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    style={{ borderRadius: '20px', paddingLeft: '35px', border: '1px solid #ccc' }}
                />
            </form>
        </li>
        <li className="nav-item">
            {user?.isLoggedIn ? (
                <Link to={`/library/${user.id}`} className={`nav-link ${isActive("/library") ? "active text-danger fw-semibold" : "text-secondary"}`}>Thư viện</Link>
            ) : (
                <span className="nav-link text-secondary" style={{ cursor: 'pointer' }} onClick={onRequireSignin}>Thư viện</span>
            )}
        </li>
        <li className="nav-item">
            {user?.isLoggedIn ? (
                <Link to="/histories" className={`nav-link ${isActive("/histories") ? "active text-danger fw-semibold" : "text-secondary"}`}>Lịch sử nghe</Link>
            ) : (
                <span className="nav-link text-secondary" style={{ cursor: 'pointer' }} onClick={onRequireSignin}>Lịch sử nghe</span>
            )}
        </li>
    </>
);

export default NavbarMenuUser;
