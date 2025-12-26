// components/navbar/NavbarBrand.jsx
import { Link } from 'react-router-dom';

const NavbarBrand = () => (
    <Link to="/" className="navbar-brand d-flex align-items-center gap-2">
        <img src="/images/icon.png" alt="Logo" width="50" height="50" />
        <span className="text-danger fw-bold fs-3">MUSICRESU</span>
    </Link>
);

export default NavbarBrand;
