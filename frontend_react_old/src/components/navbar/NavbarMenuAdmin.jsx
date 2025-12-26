// components/navbar/NavbarMenuAdmin.jsx
import React from "react";
import { Link } from "react-router-dom";

const NavbarMenuAdmin = ({ isActive, searchTerm, setSearchTerm, handleSearchSubmit }) => (
    <>
        <li className="nav-item">
            <Link to="/statistic" className={`nav-link ${isActive("/statistic") ? "active text-danger fw-semibold" : "text-secondary"}`}>Thống kê doanh thu</Link>
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
            <Link to="/track-management" className={`nav-link ${isActive("/track-management") ? "active text-danger fw-semibold" : "text-secondary"}`}>Quản lý nhạc</Link>
        </li>
        <li className="nav-item">
            <Link to="/upload" className={`nav-link ${isActive("/upload") ? "active text-danger fw-semibold" : "text-secondary"}`}>Tải lên nhạc mới</Link>
        </li>
    </>
);

export default NavbarMenuAdmin;
