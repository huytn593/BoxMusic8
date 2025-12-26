// src/pages/NotFoundForm.jsx
import React from 'react';
import { Container, Button } from 'react-bootstrap';
import { useNavigate } from 'react-router-dom';
import { ExclamationTriangleFill } from 'react-bootstrap-icons';

export default function NotFoundForm() {
    const navigate = useNavigate();

    const handleBackHome = () => {
        navigate('/');
    };

    return (
        <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
            <div className="d-flex justify-content-center">
                <div className="card text-center bg-black p-5 shadow-lg" style={{ maxWidth: '500px', borderRadius: '20px' }}>
                    <div className="mb-4 text-danger">
                        <ExclamationTriangleFill size={60} />
                    </div>
                    <h2 className="text-danger mb-3">404 - Không tìm thấy trang</h2>
                    <p className="text-secondary mb-4">
                        Trang bạn đang tìm kiếm không tồn tại hoặc đã bị xóa.<br />
                        Vui lòng kiểm tra lại đường dẫn hoặc quay về trang chủ.
                    </p>
                    <Button variant="danger" onClick={handleBackHome}>
                        Quay về trang chủ
                    </Button>
                </div>
            </div>

        </Container>
    );
}
