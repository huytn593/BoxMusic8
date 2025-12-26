import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Formik, Form, Field, ErrorMessage } from 'formik';
import * as Yup from 'yup';
import { Spinner } from 'react-bootstrap';
import { toast, ToastContainer } from 'react-toastify';

const validationSchema = Yup.object().shape({
  email: Yup.string()
    .email('Email không đúng định dạng')
    .required('Email không được để trống'),
});

function ForgotPassword() {
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  // Clear any existing state when component mounts
  useEffect(() => {
    if (location.state) {
      navigate(location.pathname, { replace: true });
    }
  }, [location, navigate]);

  const handleSubmit = async (values, { setSubmitting }) => {
    if (isSubmitting) return;
    
    setIsSubmitting(true);
    setIsLoading(true);
    let retryCount = 0;
    const maxRetries = 3;
    const retryDelay = 1000; // Reduced to 1 second

    // Show initial loading state
    toast.info('Đang gửi OTP...', {
        position: 'top-center',
        autoClose: false,
        pauseOnHover: false,
    });

    const sendOtpRequest = async () => {
        try {
            const response = await fetch('http://localhost:5270/api/Auth/send-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: values.email }),
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
                if (response.status === 404) {
                    if (retryCount < maxRetries) {
                        retryCount++;
                        toast.info(`Đang thử lại lần ${retryCount}...`, {
                            position: 'top-center',
                            autoClose: retryDelay,
                            pauseOnHover: false,
                        });
                        await new Promise(resolve => setTimeout(resolve, retryDelay));
                        return sendOtpRequest();
                    }
                    throw new Error('Email không tồn tại trong hệ thống. Vui lòng thử lại sau 10 giây.');
                } else if (response.status === 429) {
                    throw new Error('Vui lòng đợi 30 giây trước khi gửi lại OTP.');
                } else {
                    throw new Error(data.message || 'Gửi OTP thất bại.');
                }
            }

            return data;
        } catch (err) {
            if (retryCount < maxRetries && err.message.includes('không tồn tại')) {
                retryCount++;
                toast.info(`Đang thử lại lần ${retryCount}...`, {
                    position: 'top-center',
                    autoClose: retryDelay,
                    pauseOnHover: false,
                });
                await new Promise(resolve => setTimeout(resolve, retryDelay));
                return sendOtpRequest();
            }
            throw err;
        }
    };

    try {
        await sendOtpRequest();
        
        // Dismiss loading toast
        toast.dismiss();
        
        toast.success('OTP đã được gửi đến email của bạn.', {
            position: 'top-center',
            autoClose: 2000,
            pauseOnHover: false,
        });

        // Navigate immediately
        navigate('/new-password', { 
            state: { 
                email: values.email,
                countdown: 60
            } 
        });
    } catch (err) {
        // Dismiss loading toast
        toast.dismiss();
        
        toast.error(err.message || 'Đã xảy ra lỗi.', {
            position: 'top-center',
            autoClose: 3000,
            pauseOnHover: false,
        });
    } finally {
        setSubmitting(false);
        setIsLoading(false);
        setIsSubmitting(false);
    }
  };

  return (
    <div className="d-flex justify-content-center align-items-center pt-5">
      <div
        className="card p-4 shadow"
        style={{
          width: 500,
          backgroundColor: 'rgba(0,0,0,0.7)',
          color: 'white',
          borderRadius: '0.5rem',
        }}
      >
        <div className="d-flex flex-column align-items-center">
          <img src="/images/icon.png" alt="Logo" width="120" height="120" />
          <h2 className="mb-4 text-center" style={{ color: '#ff4d4f' }}>
            Quên mật khẩu
          </h2>
        </div>

        <Formik
          initialValues={{ email: '' }}
          validationSchema={validationSchema}
          onSubmit={handleSubmit}
        >
          {({ isSubmitting }) => (
            <Form>
              <div className="mb-3">
                <label htmlFor="email" className="form-label">
                  Email
                </label>
                <Field
                  name="email"
                  type="email"
                  placeholder="Nhập email của bạn"
                  className="form-control"
                  style={{ backgroundColor: 'white', color: 'black' }}
                />
                <ErrorMessage
                  name="email"
                  component="div"
                  className="text-danger"
                />
              </div>

              <button
                type="submit"
                className="btn btn-danger w-100 mb-3"
                disabled={isSubmitting || isLoading}
              >
                {isSubmitting || isLoading ? (
                  <Spinner animation="border" size="sm" />
                ) : (
                  'Tiếp tục'
                )}
              </button>
            </Form>
          )}
        </Formik>
      </div>
      <ToastContainer />
    </div>
  );
}

export default ForgotPassword;