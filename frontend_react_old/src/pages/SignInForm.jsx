import React, { useEffect, useState } from 'react';
import { toast, ToastContainer } from "react-toastify";
import { useAuth } from "../context/authContext";
import { useNavigate, Link } from "react-router-dom";
import { Spinner } from 'react-bootstrap';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { loginUser } from '../services/authService';
import '../styles/SignIn.css'

const validationSchema = Yup.object().shape({
    username: Yup.string().required('Tên đăng nhập không được để trống'),
    password: Yup.string()
        .required('Mật khẩu không được để trống')
        .min(8, 'Mật khẩu phải có ít nhất 8 ký tự'),
});

export default function SignInForm() {
    const { user, login } = useAuth();
    const navigate = useNavigate();
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        if (user.isLoggedIn) {
            setTimeout(() => {
                navigate('/');
            }, 500);
        }
    }, [user]);

    const handleSubmit = async (values, { setSubmitting }) => {
        setIsLoading(true);

        const result = await loginUser(values);

        if (result.success) {
            setTimeout(() => {
                const role = login(result.token, result.avatarBase64);
                navigate(role === "admin" ? '/statistic' : '/');
            }, 2000);
        } else {
            switch (result.status) {
                case 401:
                    toast.error("Sai tên đăng nhập hoặc mật khẩu", { position: "top-center", autoClose: 2000 });
                    break;
                case 403:
                    toast.error("Tài khoản của bạn đã bị khóa", { position: "top-center", autoClose: 2000 });
                    break;
                case undefined:
                    toast.error("Không thể kết nối đến máy chủ", { position: "top-center", autoClose: 2000 });
                    break;
                default:
                    toast.error("Lỗi máy chủ, vui lòng thử lại sau", { position: "top-center", autoClose: 2000 });
            }
        }

        setTimeout(() => {
            setSubmitting(false);
            setIsLoading(false);
        }, 2500);
    };

    return (
        <>
            {(isLoading) && (
                <>
                    <div className="d-flex justify-content-center align-items-center vh-100">
                        <Spinner animation="border" role="status" />
                    </div>
                    <ToastContainer />
                </>
            )}

            {(!isLoading && !user.isLoggedIn) && (
                <div className="d-flex justify-content-center align-items-center pt-5">
                    <div className="card p-4 shadow" style={{ width: 500, backgroundColor: 'rgba(0,0,0,0.7)', color: 'white', borderRadius: '0.5rem' }}>
                        <div className="d-flex flex-column align-items-center">
                            <img src="/images/icon.png" alt="Logo" width="120" height="120" />
                            <h2 className="mb-4 text-center" style={{ color: '#ff4d4f' }}>Đăng nhập</h2>
                        </div>

                        <Formik
                            initialValues={{ username: '', password: '' }}
                            validationSchema={validationSchema}
                            onSubmit={handleSubmit}
                        >
                            {({ isSubmitting }) => (
                                <Form>
                                    <div className="mb-3">
                                        <label htmlFor="username" className="form-label">Tên đăng nhập</label>
                                        <Field name="username" placeholder="Nhập tên đăng nhập" className="form-control" style={{ backgroundColor: 'white', color: 'black' }} />
                                        <ErrorMessage name="username" component="div" className="text-danger" />
                                    </div>

                                    <div className="mb-3">
                                        <label htmlFor="password" className="form-label">Mật khẩu</label>
                                        <Field name="password" type="password" placeholder="Nhập mật khẩu" className="form-control" style={{ backgroundColor: 'white', color: 'black' }} />
                                        <ErrorMessage name="password" component="div" className="text-danger" />
                                        <div className="text-end mt-1">
                                            <Link to="/forgot-password" className="text-white text-decoration-none forgot-link">
                                                Quên mật khẩu?
                                            </Link>
                                        </div>
                                    </div>

                                    <button type="submit" className="btn btn-danger w-100 mb-3" disabled={isSubmitting}>
                                        {isSubmitting ? <Spinner size="sm" animation="border" /> : 'Đăng nhập'}
                                    </button>
                                </Form>
                            )}
                        </Formik>
                    </div>
                </div>
            )}
        </>
    );
}
