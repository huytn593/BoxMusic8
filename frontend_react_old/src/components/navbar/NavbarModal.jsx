// components/navbar/NavbarModals.jsx
import React from 'react';
import { Modal, Button } from 'react-bootstrap';

const NavbarModals = ({
                          showLogoutModal,
                          handleCloseLogout,
                          handleConfirmLogout,
                          showSigninModal,
                          handleSigninClose,
                          handleConfirmSignin
                      }) => (
    <>
        <Modal show={showLogoutModal} onHide={handleCloseLogout} centered dialogClassName={"custom-modal-overlay"} backdrop={true}>
            <Modal.Header closeButton>
                <Modal.Title>Xác nhận đăng xuất</Modal.Title>
            </Modal.Header>
            <Modal.Body>Bạn có chắc muốn đăng xuất không?</Modal.Body>
            <Modal.Footer>
                <Button variant="secondary" onClick={handleCloseLogout}>Hủy</Button>
                <Button variant="danger" onClick={handleConfirmLogout}>Đăng xuất</Button>
            </Modal.Footer>
        </Modal>

        <Modal show={showSigninModal} onHide={handleSigninClose} centered dialogClassName={"custom-modal-overlay"} backdrop={true}>
            <Modal.Header closeButton>
                <Modal.Title>Cần phải đăng nhập</Modal.Title>
            </Modal.Header>
            <Modal.Body>Bạn có muốn đăng nhập không?</Modal.Body>
            <Modal.Footer>
                <Button variant="secondary" onClick={handleSigninClose}>Hủy</Button>
                <Button variant="danger" onClick={handleConfirmSignin}>Đồng ý</Button>
            </Modal.Footer>
        </Modal>
    </>
);

export default NavbarModals;
