// src/components/Navbar.jsx
import React, { useState } from "react";
import { useLocation, useNavigate, Link } from 'react-router-dom';
import { useAuth } from "../../context/authContext";
import { useQueryClient } from "@tanstack/react-query";

import '../../styles/Navbar.css';

import NavbarBrand from "../navbar/NavbarBrand";
import NavbarMenuUser from "../navbar/NavbarMenuUser";
import NavbarMenuAdmin from "../navbar/NavbarMenuAdmin";
import NavbarUserDropdown from "../navbar/NavbarUserDropdown";
import NavbarModals from "../navbar/NavbarModal";
import NotificationBell from "../NotificationBell";

const Navbar = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { user, logout } = useAuth();
    const queryClient = useQueryClient();

    const [searchTerm, setSearchTerm] = useState('');
    const [showLogoutModal, setShowLogoutModal] = useState(false);
    const [showConfirmSigninModal, setShowConfirmSigninModal] = useState(false);

    const isActive = (path) => location.pathname === path;

    const handleLogoutClick = () => setShowLogoutModal(true);
    const handleCloseLogout = () => setShowLogoutModal(false);
    const handleConfirmLogout = () => {
        logout();
        queryClient.invalidateQueries(['profile']);
        setShowLogoutModal(false);
        navigate('/');
    };

    const handleConfirmSigninClick = () => setShowConfirmSigninModal(true);
    const handleSigninClose = () => setShowConfirmSigninModal(false);
    const handleConfirmSignin = () => {
        navigate('/signin');
        setShowConfirmSigninModal(false);
    };

    const handleSearchSubmit = (e) => {
        e.preventDefault();
        if (searchTerm.trim() !== '') {
            navigate(`/search?q=${encodeURIComponent(searchTerm.trim())}`);
        }
    };

    return (
        <>
            <nav className="navbar navbar-expand-lg navbar-light bg-black shadow px-4 py-3 mt-0 fixed-top">
                <div className="container-fluid">
                    <NavbarBrand />

                    <button
                        className="navbar-toggler"
                        type="button"
                        data-bs-toggle="collapse"
                        data-bs-target="#navbarNav"
                        aria-controls="navbarNav"
                        aria-expanded="false"
                        aria-label="Toggle navigation"
                    >
                        <span className="navbar-toggler-icon"></span>
                    </button>

                    <div className="collapse navbar-collapse" id="navbarNav">
                        <ul className="navbar-nav mx-auto gap-3 d-flex align-items-center">
                            {(!user?.isLoggedIn || user.role !== "admin") && (
                                <>
                                    <NavbarMenuUser
                                        user={user}
                                        isActive={isActive}
                                        searchTerm={searchTerm}
                                        setSearchTerm={setSearchTerm}
                                        handleSearchSubmit={handleSearchSubmit}
                                        onRequireSignin={handleConfirmSigninClick}
                                    />

                                    {!user?.isLoggedIn && (
                                        <>
                                            <li className="nav-item">
                                                <a href="/signin" className={`nav-link ${isActive("/signin") ? "active text-danger fw-semibold" : "text-secondary"}`}>Đăng nhập</a>
                                            </li>
                                            <li className="nav-item">
                                                <a href="/signup" className="btn btn-danger fw-semibold">Đăng ký</a>
                                            </li>
                                        </>
                                    )}

                                    {user?.isLoggedIn && (
                                        <>
                                            <li className="nav-item">
                                                <Link
                                                    to={`/my-tracks/${user.id}`}
                                                    className={`nav-link ${isActive("/my-tracks") ? "active text-danger fw-semibold" : "text-secondary"}`}
                                                >
                                                    Nhạc của tôi
                                                </Link>
                                            </li>
                                            <li className="nav-item dropdown">
                                                <NavbarUserDropdown user={user} onLogout={handleLogoutClick} />
                                            </li>
                                            {user.role !== "admin" && <NotificationBell />}
                                        </>
                                    )}
                                </>
                            )}

                            {user?.isLoggedIn && user.role === "admin" && (
                                <>
                                    <NavbarMenuAdmin isActive={isActive} searchTerm={searchTerm} setSearchTerm={setSearchTerm} handleSearchSubmit={handleSearchSubmit} />
                                    <li className="nav-item dropdown">
                                        <NavbarUserDropdown user={user} onLogout={handleLogoutClick} />
                                    </li>
                                </>
                            )}
                        </ul>
                    </div>
                </div>
            </nav>

            <NavbarModals
                showLogoutModal={showLogoutModal}
                handleCloseLogout={handleCloseLogout}
                handleConfirmLogout={handleConfirmLogout}
                showSigninModal={showConfirmSigninModal}
                handleSigninClose={handleSigninClose}
                handleConfirmSignin={handleConfirmSignin}
            />
        </>
    );
};

export default Navbar;
