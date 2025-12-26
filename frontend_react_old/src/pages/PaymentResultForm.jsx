import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { Container, Row, Col, Alert, Spinner } from 'react-bootstrap';
import axios from 'axios';

export default function PaymentResultForm() {
    const location = useLocation();
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`

    useEffect(() => {
        const fetchResult = async () => {
            const searchParams = new URLSearchParams(location.search);
            const responseCode = searchParams.get('vnp_ResponseCode');
            const transactionStatus = searchParams.get('vnp_TransactionStatus');

            if (!responseCode || !transactionStatus) {
                setError('Không có dữ liệu giao dịch. Có thể bạn đã hủy trước khi hoàn tất.');
                setLoading(false);
                return;
            }

            const success = responseCode === '00' && transactionStatus === '00';

            try {
                const apiUrl = `${API_BASE}/api/VnPay/return${location.search}`;
                const response = await axios.get(apiUrl);

                setResult({
                    ...response.data,
                    success: success
                });
            } catch (err) {
                setError('Lỗi khi xác thực giao dịch với hệ thống. Vui lòng thử lại.');
                console.error(err);
            } finally {
                setLoading(false);
            }
        };

        fetchResult();
    }, [location.search]);


    const formatCurrency = (amount) => {
        return (Number(amount) / 100).toLocaleString('vi-VN', {
            style: 'currency',
            currency: 'VND',
            minimumFractionDigits: 0
        });
    };

    if (loading) {
        return (
            <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '85vh' }}>
                <Spinner animation="border" variant="light" />
            </div>
        );
    }

    return (
        <div style={{
            minHeight: '85vh',
            background: 'linear-gradient(to bottom, #000000cc, #111111cc)',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '8rem'
        }}>
            <Container>
                {error || !result || !result.orderId ? (
                    <Alert variant="danger" className="text-center fs-5 fw-bold">
                        ❌ {error || 'Thanh toán thất bại hoặc bị hủy giữa chừng.'}
                    </Alert>
                ) : (
                    <>
                        <Alert variant={result.success ? 'success' : 'danger'} className="text-center fs-5 fw-bold">
                            {result.success ? '✅ Thanh toán thành công!' : '❌ Thanh toán thất bại.'}
                        </Alert>

                        <Row className="mb-3 fs-5">
                            <Col sm={5}><strong>Mã giao dịch:</strong></Col>
                            <Col sm={7} className="text-break">{result.orderId}</Col>
                        </Row>
                        <Row className="mb-3 fs-5">
                            <Col sm={5}><strong>Phương thức:</strong></Col>
                            <Col sm={7}>{result.paymentMethod}</Col>
                        </Row>
                        <Row className="mb-3 fs-5">
                            <Col sm={5}><strong>Người dùng:</strong></Col>
                            <Col sm={7} className="text-break">{result.userId}</Col>
                        </Row>
                        <Row className="mb-3 fs-5">
                            <Col sm={5}><strong>Gói:</strong></Col>
                            <Col sm={7}>{result.tier}</Col>
                        </Row>
                    </>
                )}
            </Container>
        </div>
    );
}
