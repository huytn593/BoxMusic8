// components/navbar/NavbarSearch.jsx
import React from "react";

const NavbarSearch = ({ searchTerm, setSearchTerm, onSubmit }) => (
    <form
        onSubmit={onSubmit}
        className="d-flex align-items-center"
        style={{ width: '500px', position: 'relative' }}
    >
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
            style={{
                borderRadius: '20px',
                paddingLeft: '35px',
                border: '1px solid #ccc',
                outline: 'none',
                transition: 'border-color 0.3s',
            }}
            onFocus={(e) => (e.target.style.borderColor = '#dc3545')}
            onBlur={(e) => (e.target.style.borderColor = '#ccc')}
        />
    </form>
);

export default NavbarSearch;
