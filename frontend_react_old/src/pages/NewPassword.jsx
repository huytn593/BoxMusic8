import React, { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { Spinner } from 'react-bootstrap';
import { toast, ToastContainer } from 'react-toastify';

const otpValidationSchema = Yup.object().shape({
    reset_password_otp: Yup.string()
        .required('OTP không được để trống')
        .matches(/^\d{6}$/, 'OTP phải có 6 chữ số'),
});

const passwordValidationSchema = Yup.object().shape({
    newPassword: Yup.string()
        .required('Mật khẩu mới không được để trống')
        .min(8, 'Mật khẩu phải có ít nhất 8 ký tự'),
    confirmPassword: Yup.string()
        .required('Xác nhận mật khẩu không được để trống')
        .oneOf([Yup.ref('newPassword')], 'Mật khẩu không khớp'),
});

function NewPassword() {
    const location = useLocation();
    const navigate = useNavigate();
    const [isLoading, setIsLoading] = useState(false);
    const [isOtpVerified, setIsOtpVerified] = useState(false);
    const [countdown, setCountdown] = useState(0);
    const [verifiedOtp, setVerifiedOtp] = useState('');
    const [isOtpSentInitially, setIsOtpSentInitially] = useState(false);
    const email = location.state?.email;
    const initialCountdown = location.state?.countdown || 0;
    const setFieldValueRef = useRef(null);

    const [otpValues, setOtpValues] = useState(['', '', '', '', '', '']);
    const otpInputRefs = useRef([]);

    // Initialize countdown when component mounts
    useEffect(() => {
        if (!email) {
            toast.error('Vui lòng nhập email để đặt lại mật khẩu', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });
            navigate('/forgot-password');
            return;
        }

        // Set initial countdown from previous page
        if (initialCountdown > 0) {
            setCountdown(initialCountdown);
            setIsOtpSentInitially(true);
        }
    }, [email, navigate, initialCountdown]);

    // Handle countdown timer
    useEffect(() => {
        let timer;
        if (countdown > 0) {
            timer = setInterval(() => {
                setCountdown(prev => prev - 1);
            }, 1000);
        }
        return () => {
            if (timer) {
                clearInterval(timer);
            }
        };
    }, [countdown]);

    // Update form value whenever otpValues changes
    useEffect(() => {
        if (setFieldValueRef.current) {
            setFieldValueRef.current('reset_password_otp', otpValues.join(''));
        }
    }, [otpValues]);

    const handleOtpChange = (e, index) => {
        const { value } = e.target;
        const newOtpValues = [...otpValues];

        if (value.length > 1) {
            // Handle paste
            const pastedData = value.slice(0, 6 - index).split('');
            pastedData.forEach((char, i) => {
                if (index + i < 6) {
                    newOtpValues[index + i] = char.replace(/[^0-9]/g, ''); // Only allow digits
                }
            });
            setOtpValues(newOtpValues);
            // Move focus to the last filled input or the end
            const nextFocusIndex = Math.min(index + pastedData.length, 5);
            if (otpInputRefs.current[nextFocusIndex]) {
                otpInputRefs.current[nextFocusIndex].focus();
            }
            // Auto verify if all 6 digits are filled
            if (newOtpValues.every(val => val !== '')) {
                const fullOtp = newOtpValues.join('');
                verifyOtp(fullOtp);
            }
        } else if (value.match(/[^0-9]/)) {
            // Prevent non-digit input
            newOtpValues[index] = '';
            setOtpValues(newOtpValues);
        } else {
            newOtpValues[index] = value;
            setOtpValues(newOtpValues);

            // Move focus to next input if a digit is entered and it's not the last field
            if (value !== '' && index < 5) {
                otpInputRefs.current[index + 1].focus();
            } else if (value === '' && index > 0) {
                // Move focus to previous input on backspace if current is empty
                otpInputRefs.current[index - 1].focus();
            }

            // Auto verify if all 6 digits are filled
            if (newOtpValues.every(val => val !== '')) {
                const fullOtp = newOtpValues.join('');
                verifyOtp(fullOtp);
            }
        }
    };

    const verifyOtp = async (fullOtp) => {
        setIsLoading(true);
        try {
            const requestBody = {
                email: email,
                otp: fullOtp
            };

            const response = await fetch('http://localhost:5270/api/Auth/verify-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(requestBody),
            });

            let data;
            try {
                const contentType = response.headers.get("content-type");
                if (contentType && contentType.includes("application/json")) {
                    data = await response.json();
                } else {
                    const text = await response.text();
                    throw new Error(text);
                }
            } catch (err) {
                throw new Error("Lỗi máy chủ không xác định");
            }

            if (!response.ok) {
                throw new Error(data.message || 'Xác thực OTP thất bại.');
            }

            setVerifiedOtp(fullOtp);
            setIsOtpVerified(true);
            setOtpValues(['', '', '', '', '', '']); // Clear OTP fields after successful verification
            toast.success('Xác thực OTP thành công.', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });

        } catch (err) {
            toast.error(err.message || 'Xác thực OTP thất-bại.', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });
        } finally {
            setIsLoading(false);
        }
    };

    const handleVerifyOtp = async (values, { setSubmitting, resetForm }) => {
        const fullOtp = otpValues.join('');
        await verifyOtp(fullOtp);
        setSubmitting(false);
    };

    const handleResetPassword = async (values, { setSubmitting, resetForm }) => {
        setIsLoading(true);
        
        // Optimistic update - show success message immediately
        toast.info('Đang xử lý yêu cầu đổi mật khẩu...', {
            position: "top-center",
            autoClose: false,
            pauseOnHover: false
        });

        try {
            const response = await fetch('http://localhost:5270/api/Auth/reset-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    email,
                    otp: verifiedOtp,
                    newPassword: values.newPassword,
                }),
            });

            let data;
            try {
                const contentType = response.headers.get("content-type");
                if (contentType && contentType.includes("application/json")) {
                    data = await response.json();
                } else {
                    const text = await response.text();
                    throw new Error(text);
                }
            } catch (err) {
                throw new Error("Lỗi máy chủ không xác định");
            }

            if (!response.ok) {
                throw new Error(data.message || 'Đặt lại mật khẩu thất bại.');
            }

            // Clear all session data immediately
            localStorage.clear();
            sessionStorage.clear();
            
            // Dismiss the loading toast
            toast.dismiss();
            
            // Show success message
            toast.success('Mật khẩu đã được đặt lại thành công!', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });

            // Reset form and navigate
            resetForm();
            navigate('/signin');
            
        } catch (err) {
            // Dismiss the loading toast
            toast.dismiss();
            
            toast.error(err.message || 'Đặt lại mật khẩu thất bại.', {
                position: "top-center",
                autoClose: 3000,
                pauseOnHover: false
            });
        } finally {
            setSubmitting(false);
            setIsLoading(false);
        }
    };

    const handleResendOtp = async () => {
        if (countdown > 0) return;

        setIsLoading(true);
        try {
            const response = await fetch('http://localhost:5270/api/Auth/send-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email }),
            });

            let data;
            try {
                const contentType = response.headers.get("content-type");
                if (contentType && contentType.includes("application/json")) {
                    data = await response.json();
                }
                else {
                    const text = await response.text();
                    throw new Error(text);
                }
            } catch (err) {
                throw new Error("Lỗi máy chủ không xác định");
            }

            if (!response.ok) {
                throw new Error(data.message || 'Gửi lại OTP thất bại.');
            }

            setCountdown(60);
            setIsOtpSentInitially(true);
            toast.success('OTP mới đã được gửi.', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });
        } catch (err) {
            toast.error(err.message || 'Gửi lại OTP thất bại.', {
                position: "top-center",
                autoClose: 2000,
                pauseOnHover: false
            });
        } finally {
            setIsLoading(false);
        }
    };

    const handlePasteOtp = (e) => {
        e.preventDefault();
        const pastedData = e.clipboardData.getData('text').replace(/[^0-9]/g, '').slice(0, 6);
        if (pastedData.length > 0) {
            const newOtpValues = [...otpValues];
            pastedData.split('').forEach((char, i) => {
                if (i < 6) {
                    newOtpValues[i] = char;
                }
            });
            setOtpValues(newOtpValues);
            
            // Auto verify if all 6 digits are pasted
            if (pastedData.length === 6) {
                verifyOtp(pastedData);
            }
        }
    };

    const handleKeyDown = (e, index) => {
        if (e.key === 'Backspace' && otpValues[index] === '' && index > 0) {
            otpInputRefs.current[index - 1].focus();
        }
    };

    return (
        <div className="d-flex justify-content-center align-items-center pt-5">
            <div className="card p-4 shadow" style={{ width: 500, backgroundColor: 'rgba(0,0,0,0.7)', color: 'white', borderRadius: '0.5rem' }}>
                <div className="d-flex flex-column align-items-center">
                    <img src="/images/icon.png" alt="Logo" width="120" height="120" />
                    <h2 className="mb-4 text-center" style={{ color: '#ff4d4f' }}>Đặt lại mật khẩu</h2>
                </div>

                {!isOtpVerified ? (
                    <Formik
                        key="otp-form"
                        initialValues={{ reset_password_otp: '' }}
                        validationSchema={otpValidationSchema}
                        onSubmit={handleVerifyOtp}
                        enableReinitialize={true}
                        validateOnChange={false}
                        validateOnBlur={false}
                    >
                        {({ isSubmitting, setFieldValue }) => {
                            setFieldValueRef.current = setFieldValue;

                            return (
                                <Form>
                                    <div className="mb-3 text-center">
                                        <label htmlFor="otp-input" className="form-label">OTP</label>
                                        <div 
                                            style={{
                                                display: 'flex',
                                                justifyContent: 'center',
                                                gap: '10px',
                                                marginBottom: '1rem',
                                                position: 'relative'
                                            }}
                                            onPaste={handlePasteOtp}
                                        >
                                            {/* Hidden input for paste handling */}
                                            <input
                                                type="text"
                                                style={{
                                                    position: 'absolute',
                                                    opacity: 0,
                                                    pointerEvents: 'none',
                                                    width: 0,
                                                    height: 0
                                                }}
                                                autoComplete="off"
                                            />
                                            {otpValues.map((digit, index) => (
                                                <input
                                                    key={index}
                                                    id={`otp-input-${index}`}
                                                    type="text"
                                                    maxLength="1"
                                                    value={digit}
                                                    onChange={(e) => handleOtpChange(e, index)}
                                                    onKeyDown={(e) => handleKeyDown(e, index)}
                                                    ref={(el) => otpInputRefs.current[index] = el}
                                                    style={{
                                                        width: '40px',
                                                        height: '50px',
                                                        textAlign: 'center',
                                                        fontSize: '1.5rem',
                                                        borderRadius: '8px',
                                                        border: '1px solid #ccc',
                                                        backgroundColor: 'white',
                                                        color: 'black',
                                                    }}
                                                    autoComplete="off"
                                                />
                                            ))}
                                        </div>
                                        <ErrorMessage name="reset_password_otp" component="div" className="text-danger" />
                                    </div>

                                    <button
                                        type="button"
                                        className="btn btn-danger mt-3 w-100"
                                        disabled={isLoading || countdown > 0}
                                        onClick={handleResendOtp}
                                    >
                                        {isLoading ? (
                                            <Spinner animation="border" size="sm" />
                                        ) : isOtpSentInitially ? (
                                            countdown > 0 ? `Gửi lại OTP (${countdown}s)` : 'Gửi lại OTP'
                                        ) : (
                                            'Gửi OTP'
                                        )}
                                    </button>
                                </Form>
                            );
                        }}
                    </Formik>
                ) : (
                    <Formik
                        key="password-form"
                        initialValues={{ newPassword: '', confirmPassword: '' }}
                        validationSchema={passwordValidationSchema}
                        onSubmit={handleResetPassword}
                        enableReinitialize={false}
                    >
                        {({ isSubmitting }) => {
                            return (
                                <Form>
                                    <div className="mb-3">
                                        <label htmlFor="newPassword" className="form-label">Mật khẩu mới</label>
                                        <Field
                                            name="newPassword"
                                            type="password"
                                            placeholder="Nhập mật khẩu mới"
                                            className="form-control"
                                            style={{ backgroundColor: 'white', color: 'black' }}
                                            autoComplete="new-password"
                                        />
                                        <ErrorMessage name="newPassword" component="div" className="text-danger" />
                                    </div>

                                    <div className="mb-3">
                                        <label htmlFor="confirmPassword" className="form-label">Xác nhận mật khẩu</label>
                                        <Field
                                            name="confirmPassword"
                                            type="password"
                                            placeholder="Nhập lại mật khẩu mới"
                                            className="form-control"
                                            style={{ backgroundColor: 'white', color: 'black' }}
                                            autoComplete="new-password"
                                        />
                                        <ErrorMessage name="confirmPassword" component="div" className="text-danger" />
                                    </div>

                                    <button
                                        type="submit"
                                        className="btn btn-danger w-100 mb-3"
                                        disabled={isSubmitting || isLoading}
                                    >
                                        {isSubmitting || isLoading ? (
                                            <Spinner animation="border" size="sm" />
                                        ) : (
                                            'Đặt lại mật khẩu'
                                        )}
                                    </button>
                                </Form>
                            );
                        }}
                    </Formik>
                )}
            </div>
            <ToastContainer />
        </div>
    );
}

export default NewPassword; 