import React, {useState} from 'react';
import {Container, Nav, Tab, Row, Col, Spinner, Button, Alert, Card, Modal} from 'react-bootstrap';
import { Person, GeoAlt, ShieldLock, Link45deg } from 'react-bootstrap-icons';
import '../styles/Profile.css'
import {useNavigate, useParams} from "react-router-dom";
import { queryClient } from "../context/queryClientContext";
import { useUserProfile, updatePersonalData, updatePersonalDataWithAvatar, updateAddress, sendVerifyEmailOtp, verifyEmailOtp } from "../services/profileService";
import { toast, ToastContainer } from "react-toastify";
import {Field, Form, Formik} from "formik";
import * as Yup from 'yup';
import { useAuth } from '../context/authContext'
import {useLoginSessionOut} from "../services/loginSessionOut";

export default function ProfileForm() {
    const navigate = useNavigate();
    const { userId } = useParams();
    const { data: userData, isLoading, error, refetch } = useUserProfile(userId);
    const [ isSubmitting, setSubmitting ] = useState(false);
    const { user, logout } = useAuth();
    const handleSessionOut = useLoginSessionOut()
    const [showOtpModal, setShowOtpModal] = useState(false);
    const [otpValue, setOtpValue] = useState('');
    const [pendingVerify, setPendingVerify] = useState(false);
    const [sendingOtp, setSendingOtp] = useState(false);
    const [otpCountdown, setOtpCountdown] = useState(0);
    const otpTimerRef = React.useRef();
    const [isLoadingAddress, setIsLoadingAddress] = useState(false);
    const [isLoadingPassword, setIsLoadingPassword] = useState(false);
    const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', '']);
    const otpInputRefs = React.useRef([]);

    // Đếm ngược gửi lại OTP
    React.useEffect(() => {
        if (otpCountdown > 0) {
            otpTimerRef.current = setInterval(() => {
                setOtpCountdown((prev) => {
                    if (prev <= 1) {
                        clearInterval(otpTimerRef.current);
                        return 0;
                    }
                    return prev - 1;
                });
            }, 1000);
        }
        return () => clearInterval(otpTimerRef.current);
    }, [otpCountdown]);

    if (isLoading) {
        return (
            <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
                <div className="d-flex justify-content-center align-items-center vh-100">
                    <Spinner animation="border" role="status" />
                </div>
            </Container>
        );
    }

    if(error){
        toast.error(error, { position: "top-center", autoClose: 3000 });
    }

    const expiredDate = new Date(userData.expiredDate);
    const today = new Date();
    const diffTime = expiredDate.getTime() - today.getTime();
    const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    const dob = userData.dateOfBirth ? new Date(userData.dateOfBirth) : new Date();
    const initialValues = {
        fullname: userData.fullname || '',
        email: userData.email || '',
        phoneNumber: userData.phoneNumber || '',
        day: dob.getDate().toString().padStart(2, '0'),
        month: (dob.getMonth() + 1).toString().padStart(2, '0'),
        year: dob.getFullYear().toString(),
        gender: userData.gender || 0,
        avatarBase64: userData.avatarBase64 || '',
        avatarFile: null,
        avatarPreview: '',
        isEmailVerified: userData.isEmailVerified || false,
        address: userData.address || '',
    };

    const profileSchema = Yup.object().shape({
        fullname: Yup.string().required("Họ tên không được bỏ trống"),
        email: Yup.string().email("Email không hợp lệ").required("Email không được bỏ trống"),
        phoneNumber: Yup.string().required("Số điện thoại không được bỏ trống"),
        day: Yup.number().min(1).max(31).required("Ngày không hợp lệ"),
        month: Yup.number().min(1).max(12).required("Tháng không hợp lệ"),
        year: Yup.number().min(1900).max(new Date().getFullYear()).required("Năm không hợp lệ"),
    });

    const handleSubmitNoAvt = async (data) => {
        let result = await updatePersonalData(userId, JSON.stringify(data));
        try {
            if (result === "Thành công") {
                await refetch();
                toast.success("Cập nhật thành công!", {
                    position: "top-center",
                    autoClose: 2000,
                    pauseOnHover: false
                });
                await queryClient.invalidateQueries(['profile', userId]);

            } else if (result === "Phiên đăng nhập hết hạn") {
                logout();
                handleSessionOut();
            } else if (result === "Không thể kết nối đến máy chủ") {
                toast.error("Không thể kết nối đến máy chủ", { position: "top-center", autoClose: 2000, pauseOnHover: false });
            } else {
                toast.error(result || "Lỗi không xác định", { position: "top-center", autoClose: 2000, pauseOnHover: false });
            }
        } catch (err) {
            console.error(err);
            toast.error("Lỗi hệ thống", { position: "top-center", autoClose: 2000, pauseOnHover: false });
        }
        finally {
            setTimeout(() => {
                setSubmitting(false);
            }, 2500)
        }
    }

    const handleSubmitAvatar = async (formData) => {
        let result = await updatePersonalDataWithAvatar(userId, formData);
        try {
            if (result === "Thành công") {
                await refetch();
                toast.success("Cập nhật thành công!", {
                    position: "top-center",
                    autoClose: 2000,
                    pauseOnHover: false
                });
                await queryClient.invalidateQueries(['profile', userId]);
            } else if (result === "Phiên đăng nhập hết hạn") {
                handleSessionOut();
            } else if (result === "Không thể kết nối đến máy chủ") {
                toast.error("Không thể kết nối đến máy chủ", { position: "top-center", autoClose: 2000, pauseOnHover: false });
            } else {
                toast.error(result || "Lỗi không xác định", { position: "top-center", autoClose: 2000, pauseOnHover: false });
            }
        } catch (err) {
            console.error(err);
            toast.error("Lỗi hệ thống", { position: "top-center", autoClose: 2000, pauseOnHover: false });
        }
        finally {
            setTimeout(() => {
                setSubmitting(false);
            }, 2500)
        }
    }

    const handleOtpChange = (e, idx) => {
        const value = e.target.value.replace(/[^0-9]/g, '');
        if (!value) {
            const newDigits = [...otpDigits];
            newDigits[idx] = '';
            setOtpDigits(newDigits);
            if (idx > 0) otpInputRefs.current[idx - 1].focus();
            return;
        }
        if (value.length === 1) {
            const newDigits = [...otpDigits];
            newDigits[idx] = value;
            setOtpDigits(newDigits);
            if (idx < 5) otpInputRefs.current[idx + 1].focus();
        }
    };

    const handleOtpPaste = (e) => {
        const paste = e.clipboardData.getData('text').replace(/[^0-9]/g, '').slice(0, 6);
        if (paste.length) {
            const arr = paste.split('');
            setOtpDigits(arr.concat(Array(6 - arr.length).fill('')));
            if (arr.length < 6) otpInputRefs.current[arr.length].focus();
            else otpInputRefs.current[5].blur();
        }
    };

    return (
        <>
            <Container fluid className="account-settings px-5 pt-5">
            <h1 className="settings-title text-white text-center mb-4">Cài đặt tài khoản</h1>
                <Tab.Container defaultActiveKey="profile">
                    <Row>
                        <Col xl={3} lg={4} md={5} className="custom-sidebar">
                            <Nav variant="pills" className="flex-column custom-tab-nav">
                                <Nav.Item>
                                    <Nav.Link eventKey="profile">
                                        <Person className="me-2" /> Thông tin cá nhân
                                    </Nav.Link>
                                </Nav.Item>
                                <Nav.Item>
                                    <Nav.Link eventKey="contact">
                                        <GeoAlt className="me-2" /> Địa chỉ liên lạc
                                    </Nav.Link>
                                </Nav.Item>
                                {/* <Nav.Item>
                                    <Nav.Link eventKey="social">
                                        <Link45deg className="me-2" /> Liên kết mạng xã hội
                                    </Nav.Link>
                                </Nav.Item> */}
                                {user.role !== "admin" && user.role !== "normal" && user.role !== "artist" && (
                                    <Nav.Item>
                                        <Nav.Link eventKey="tier">
                                            <ShieldLock className="me-2" /> Gói nâng cấp tài khoản
                                        </Nav.Link>
                                    </Nav.Item>
                                )}
                                <Nav.Item>
                                    <Nav.Link eventKey="security">
                                        <ShieldLock className="me-2" /> Mật khẩu & Bảo mật
                                    </Nav.Link>
                                </Nav.Item>
                            </Nav>
                        </Col>

                        <Col xl={9} lg={8} md={7}>
                            <Tab.Content className="p-4 bg-dark rounded shadow text-light">
                                <Tab.Pane eventKey="profile">
                                    <Card className="bg-dark text-light shadow-lg p-4 rounded-4">
                                        <h2 className={"mb-3 border-bottom pb-2"}>👤 Thông tin cá nhân</h2>
                                        {isSubmitting && (
                                            <div className="d-flex justify-content-center align-items-center">
                                                <Spinner animation="border" role="status" />
                                            </div>
                                        )}

                                        {!isSubmitting && (
                                            <Formik
                                                initialValues={initialValues}
                                                validationSchema={profileSchema}
                                                enableReinitialize
                                                onSubmit={async (values) => {
                                                    setSubmitting(true)

                                                    const dateOfBirth = `${values.year.padStart(2, '0')}-${values.month.padStart(2, '0')}-${values.day.padStart(2, '0')}T00:00:00Z`;

                                                    if (values.avatarFile) {
                                                        const formData = new FormData();
                                                        formData.append('Fullname', values.fullname);
                                                        formData.append('Gender', values.gender.toString());
                                                        formData.append('DateOfBirth', dateOfBirth);
                                                        formData.append('Avatar', values.avatarFile);

                                                        await handleSubmitAvatar(formData);
                                                    }
                                                    else {
                                                        const submitData = {
                                                            fullname: values.fullname,
                                                            gender: values.gender,
                                                            dateOfBirth,
                                                        };

                                                        await handleSubmitNoAvt(submitData);
                                                    }

                                                }}
                                            >
                                                {({ values, setFieldValue, resetForm }) => (
                                                    <Form>
                                                        {/* Avatar + nút đổi */}
                                                        <div className="text-center mb-4">
                                                            <img
                                                                src={values.avatarBase64 || values.avatarPreview || '/images/default-avatar.png'}
                                                                alt="Avatar"
                                                                className="rounded-circle"
                                                                style={{ width: '120px', height: '120px', objectFit: 'cover' }}
                                                            />
                                                            <div className="mt-2">
                                                                <label className="btn btn-outline-light btn-sm">
                                                                    Đổi ảnh
                                                                    <input
                                                                        type="file"
                                                                        accept="image/*"
                                                                        hidden
                                                                        onChange={(e) => {
                                                                            const file = e.target.files[0];
                                                                            if (file) {
                                                                                setFieldValue("avatarBase64", null);
                                                                                setFieldValue("avatarFile", file);
                                                                                setFieldValue("avatarPreview", URL.createObjectURL(file));
                                                                            }
                                                                        }}
                                                                    />
                                                                </label>
                                                            </div>
                                                        </div>

                                                        {/* Họ tên */}
                                                        <div className="mb-3">
                                                            <label>Họ tên</label>
                                                            <Field name="fullname" type="text" className="form-control" />
                                                        </div>

                                                        {/* Giới tính */}
                                                        <div className="mb-3">
                                                            <label>Giới tính</label>
                                                            <Field as="select" name="gender" className="form-control">
                                                                <option value={0}>Nam</option>
                                                                <option value={1}>Nữ</option>
                                                                <option value={2}>Khác</option>
                                                                <option value={3}>Không muốn trả lời</option>
                                                            </Field>
                                                        </div>

                                                        {/* Ngày sinh */}
                                                        <div className="mb-3">
                                                            <label>Ngày sinh</label>
                                                            <div className="d-flex gap-2">
                                                                <Field name="day" type="number" placeholder="Ngày" className="form-control" />
                                                                <Field name="month" type="number" placeholder="Tháng" className="form-control" />
                                                                <Field name="year" type="number" placeholder="Năm" className="form-control" />
                                                            </div>
                                                        </div>

                                                        {/* Nút submit */}
                                                        <div className="text-end mt-4 d-flex justify-content-end gap-2">
                                                            <button type="button" onClick={() => resetForm()} className="btn btn-dark">Hủy</button>
                                                            <button type="submit" className="btn btn-danger">Cập nhật</button>
                                                        </div>
                                                    </Form>
                                                )}
                                            </Formik>
                                        )}
                                    </Card>
                                </Tab.Pane>
                                <Tab.Pane eventKey="contact">
                                    <Card className="bg-dark text-light shadow-lg p-4 rounded-4">
                                        <h2 className="mb-3 border-bottom pb-2">📧 Địa chỉ liên lạc</h2>
                                        {isLoadingAddress && (
                                            <div className="d-flex justify-content-center align-items-center">
                                                <Spinner animation="border" role="status" />
                                            </div>
                                        )}
                                        {!isLoadingAddress && (
                                        <Formik
                                            initialValues={{
                                                email: userData.email || '',
                                                isEmailVerified: userData.isEmailVerified || false,
                                                address: userData.address || '',
                                            }}
                                            enableReinitialize
                                            onSubmit={async (values, { setSubmitting }) => {
                                                setIsLoadingAddress(true);
                                                setSubmitting(true);
                                                const result = await updateAddress(userId, values.address);
                                                if (result === 'Thành công') {
                                                    toast.success('Cập nhật địa chỉ thành công!', { position: 'top-center', autoClose: 2000 });
                                                    await refetch();
                                                } else {
                                                    toast.error(result || 'Lỗi không xác định', { position: 'top-center', autoClose: 2000 });
                                                }
                                                setTimeout(() => {
                                                    setIsLoadingAddress(false);
                                                    setSubmitting(false);
                                                }, 2500);
                                            }}
                                        >
                                            {({ values, setFieldValue, isSubmitting }) => (
                                                <Form>
                                                    <div className="mb-3">
                                                        <label>Email</label>
                                                        <div className="d-flex flex-row align-items-center gap-2">
                                                            <Field name="email" type="text" className="form-control" readOnly />
                                                            {values.isEmailVerified ? (
                                                                <span className="badge bg-success">Đã xác minh</span>
                                                            ) : (
                                                                <button
                                                                    type="button"
                                                                    className="btn btn-danger form-action-btn"
                                                                    disabled={sendingOtp || showOtpModal || otpCountdown > 0}
                                                                    onClick={async () => {
                                                                        setSendingOtp(true);
                                                                        const sendRes = await sendVerifyEmailOtp(userId);
                                                                        if (sendRes === 'Đã gửi OTP') {
                                                                            setShowOtpModal(true);
                                                                            setOtpCountdown(60);
                                                                        } else {
                                                                            toast.error(sendRes, { position: 'top-center', autoClose: 2000 });
                                                                        }
                                                                        setSendingOtp(false);
                                                                    }}
                                                                >
                                                                    {otpCountdown > 0 ? `Gửi lại OTP (${otpCountdown}s)` : 'Xác minh'}
                                                                </button>
                                                            )}
                                                        </div>
                                                    </div>
                                                    <div className="mb-3">
                                                        <label>Địa chỉ</label>
                                                        <div className="d-flex flex-row align-items-center gap-2">
                                                            <Field name="address" type="text" className="form-control" placeholder="Nhập địa chỉ liên lạc..." />
                                                            <button type="submit" className="btn btn-danger form-action-btn" disabled={isSubmitting}>Lưu địa chỉ</button>
                                                        </div>
                                                    </div>
                                                </Form>
                                            )}
                                        </Formik>
                                        )}
                                        {/* Modal nhập OTP xác minh email */}
                                        <Modal show={showOtpModal} onHide={() => { setShowOtpModal(false); setOtpValue(''); setOtpCountdown(0); setOtpDigits(['', '', '', '', '', '']); }} centered>
                                            <Modal.Header closeButton className="bg-dark text-white">
                                                <Modal.Title className="text-white">Nhập mã OTP xác minh email</Modal.Title>
                                            </Modal.Header>
                                            <Modal.Body className="bg-dark text-white">
                                                <div className="mb-3 text-center">
                                                    <label className="mb-2">Nhập mã OTP</label>
                                                    <div style={{ display: 'flex', justifyContent: 'center', gap: 10 }} onPaste={handleOtpPaste}>
                                                        {otpDigits.map((digit, idx) => (
                                                            <input
                                                                key={idx}
                                                                type="text"
                                                                inputMode="numeric"
                                                                maxLength={1}
                                                                className="otp-input-box"
                                                                style={{
                                                                    width: 44, height: 54, textAlign: 'center', fontSize: 28,
                                                                    borderRadius: 10, border: '2px solid #444', background: '#222', color: '#fff', outline: 'none'
                                                                }}
                                                                value={digit}
                                                                onChange={e => handleOtpChange(e, idx)}
                                                                ref={el => otpInputRefs.current[idx] = el}
                                                                onFocus={e => e.target.select()}
                                                            />
                                                        ))}
                                                    </div>
                                                </div>
                                                <div className="text-muted small mb-2">OTP sẽ hết hạn sau 5 phút. Nếu chưa nhận được, hãy thử gửi lại sau 60 giây.</div>
                                                <Button
                                                    variant="outline-warning"
                                                    className="mb-2"
                                                    disabled={otpCountdown > 0 || sendingOtp}
                                                    onClick={async () => {
                                                        setSendingOtp(true);
                                                        const sendRes = await sendVerifyEmailOtp(userId);
                                                        if (sendRes === 'Đã gửi OTP') {
                                                            toast.success('Đã gửi lại OTP!', { position: 'top-center', autoClose: 2000 });
                                                            setOtpCountdown(60);
                                                        } else {
                                                            toast.error(sendRes, { position: 'top-center', autoClose: 2000 });
                                                        }
                                                        setSendingOtp(false);
                                                    }}
                                                >
                                                    {otpCountdown > 0 ? `Gửi lại OTP (${otpCountdown}s)` : 'Gửi lại OTP'}
                                                </Button>
                                            </Modal.Body>
                                            <Modal.Footer className="bg-dark">
                                                <Button variant="secondary" onClick={() => { setShowOtpModal(false); setOtpValue(''); setOtpCountdown(0); setOtpDigits(['', '', '', '', '', '']); }}>
                                                    Đóng
                                                </Button>
                                                <Button
                                                    variant="danger"
                                                    disabled={pendingVerify || otpDigits.some(d => d === '')}
                                                    onClick={async () => {
                                                        setPendingVerify(true);
                                                        const otpValue = otpDigits.join('');
                                                        const verifyRes = await verifyEmailOtp(userId, otpValue);
                                                        if (verifyRes === 'Xác minh thành công') {
                                                            toast.success('Xác minh email thành công!', { position: 'top-center', autoClose: 2000 });
                                                            setShowOtpModal(false);
                                                            setOtpValue('');
                                                            setOtpCountdown(0);
                                                            setOtpDigits(['', '', '', '', '', '']);
                                                            await refetch();
                                                        } else {
                                                            toast.error(verifyRes, { position: 'top-center', autoClose: 2000 });
                                                        }
                                                        setPendingVerify(false);
                                                    }}
                                                >
                                                    Xác nhận
                                                </Button>
                                            </Modal.Footer>
                                        </Modal>
                                    </Card>
                                </Tab.Pane>
                                {/* <Tab.Pane eventKey="social">[Liên kết mạng xã hội]</Tab.Pane> */}
                                <Tab.Pane eventKey="tier">
                                    <Card className="bg-dark text-light shadow-lg p-4 rounded-4">
                                        <h2 className="mb-4 border-bottom pb-2">✨ Quản lý gói nâng cấp</h2>

                                        <Row className="mb-3 align-items-center">
                                            <Col md={4} className="fw-bold d-flex align-items-center">
                                                <i className="bi bi-box-seam me-2" /> Tên gói:
                                            </Col>
                                            <Col md={8}>
                                                <span className="text-info">{user.role}</span>
                                            </Col>
                                        </Row>

                                        <Row className="mb-3 align-items-center">
                                            <Col md={4} className="fw-bold d-flex align-items-center">
                                                <i className="bi bi-calendar-check me-2" /> Ngày hết hạn:
                                            </Col>
                                            <Col md={8}>
                                                <span className="text-warning">{expiredDate.toLocaleDateString('vi-VN')}</span>
                                            </Col>
                                        </Row>

                                        <Row className="mb-3 align-items-center">
                                            <Col md={4} className="fw-bold d-flex align-items-center">
                                                <i className="bi bi-hourglass-split me-2" /> Số ngày còn lại:
                                            </Col>
                                            <Col md={8}>
                                                {daysRemaining > 0 ? (
                                                    <span className={`badge bg-${daysRemaining <= 7 ? 'warning text-dark' : 'success'}`}>
                                                      {daysRemaining} ngày
                                                    </span>
                                                ) : (
                                                    <span className="badge bg-danger">Đã hết hạn</span>
                                                )}
                                            </Col>
                                        </Row>

                                        {daysRemaining <= 7 && (
                                            <Alert variant="warning" className="rounded-3 mt-3">
                                                ⚠️ Gói của bạn sắp hết hạn. Vui lòng gia hạn để không bị gián đoạn dịch vụ.
                                            </Alert>
                                        )}

                                        <div className="text-end mt-4">
                                            <Button
                                                variant="danger"
                                                className="px-4 py-2 fw-bold"
                                                onClick={() => navigate(`/upgrade/${user.id}`)}
                                            >
                                                Gia hạn ngay
                                            </Button>
                                        </div>
                                    </Card>

                                </Tab.Pane>
                                <Tab.Pane eventKey="security">
                                    <Card className="bg-dark text-light shadow-lg p-4 rounded-4">
                                        <h2 className="mb-3 border-bottom pb-2">🔒 Mật khẩu & Bảo mật</h2>
                                        {isLoadingPassword && (
                                            <div className="d-flex justify-content-center align-items-center">
                                                <Spinner animation="border" role="status" />
                                            </div>
                                        )}
                                        {!isLoadingPassword && (
                                        <Formik
                                            initialValues={{
                                                oldPassword: '',
                                                newPassword: '',
                                                confirmPassword: ''
                                            }}
                                            validate={values => {
                                                const errors = {};
                                                if (!values.oldPassword) errors.oldPassword = 'Nhập mật khẩu cũ';
                                                if (!values.newPassword) errors.newPassword = 'Nhập mật khẩu mới';
                                                if (values.newPassword && values.newPassword.length < 8) errors.newPassword = 'Mật khẩu mới phải >= 8 ký tự';
                                                if (values.newPassword !== values.confirmPassword) errors.confirmPassword = 'Mật khẩu xác nhận không khớp';
                                                return errors;
                                            }}
                                            onSubmit={async (values, { setSubmitting, resetForm }) => {
                                                setIsLoadingPassword(true);
                                                setSubmitting(true);
                                                const res = await fetch(`http://localhost:5270/api/Profile/change-password/${userId}`, {
                                                    method: 'POST',
                                                    headers: {
                                                        'Content-Type': 'application/json',
                                                        'Authorization': `Bearer ${localStorage.getItem('token')}`,
                                                    },
                                                    body: JSON.stringify({
                                                        oldPassword: values.oldPassword,
                                                        newPassword: values.newPassword
                                                    })
                                                });
                                                if (res.ok) {
                                                    toast.success('Đổi mật khẩu thành công!', { position: 'top-center', autoClose: 2000 });
                                                    resetForm();
                                                } else {
                                                    const msg = await res.text();
                                                    toast.error(msg || 'Đổi mật khẩu thất bại', { position: 'top-center', autoClose: 2000 });
                                                }
                                                setTimeout(() => {
                                                    setIsLoadingPassword(false);
                                                    setSubmitting(false);
                                                }, 2500);
                                            }}
                                        >
                                            {({ errors, touched, isSubmitting }) => (
                                                <Form>
                                                    <div className="mb-3">
                                                        <label>Mật khẩu cũ</label>
                                                        <Field name="oldPassword" type="password" className="form-control" />
                                                        {errors.oldPassword && touched.oldPassword && <div className="text-danger small">{errors.oldPassword}</div>}
                                                    </div>
                                                    <div className="mb-3">
                                                        <label>Mật khẩu mới</label>
                                                        <Field name="newPassword" type="password" className="form-control" />
                                                        {errors.newPassword && touched.newPassword && <div className="text-danger small">{errors.newPassword}</div>}
                                                    </div>
                                                    <div className="mb-3">
                                                        <label>Xác nhận mật khẩu mới</label>
                                                        <Field name="confirmPassword" type="password" className="form-control" />
                                                        {errors.confirmPassword && touched.confirmPassword && <div className="text-danger small">{errors.confirmPassword}</div>}
                                                    </div>
                                                    <div className="d-flex justify-content-between align-items-center mt-4">
                                                        <button type="button" className="btn btn-link text-warning p-0" onClick={() => window.location.href='/forgot-password'}>
                                                            Quên mật khẩu?
                                                        </button>
                                                        <button type="submit" className="btn btn-danger" disabled={isSubmitting}>Đổi mật khẩu</button>
                                                    </div>
                                                </Form>
                                            )}
                                        </Formik>
                                        )}
                                    </Card>
                                </Tab.Pane>
                            </Tab.Content>
                        </Col>
                    </Row>
                </Tab.Container>
            </Container>
            <ToastContainer />
        </>
    );
};
