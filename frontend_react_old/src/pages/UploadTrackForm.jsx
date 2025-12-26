import React, { useState } from 'react';
import {
    Form, Button, Badge, InputGroup, Card, Spinner, Container
} from 'react-bootstrap';
import { useFormik } from 'formik';
import * as Yup from 'yup';
import { Plus, X, CheckCircle } from 'react-bootstrap-icons';
import { uploadTrack } from '../services/trackService';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import '../styles/UploadTrack.css';
import {useLoginSessionOut} from "../services/loginSessionOut";

const UploadTrackForm = () => {
    const [genres, setGenres] = useState([]);
    const [genreInput, setGenreInput] = useState('');
    const [previewImage, setPreviewImage] = useState(null);
    const [previewAudio, setPreviewAudio] = useState(null);
    const [loading, setLoading] = useState(false);
    const handleSessionOut = useLoginSessionOut()

    const formik = useFormik({
        initialValues: {
            title: '',
            cover: null,
            file: null,
        },
        validationSchema: Yup.object({
            title: Yup.string().required('Nhập tiêu đề bài hát'),
            cover: Yup.mixed().required('Chọn ảnh bìa'),
            file: Yup.mixed().required('Chọn file MP3'),
        }),
        onSubmit: async (values, { resetForm }) => {
            if (genres.length === 0) {
                toast.error("Cần ít nhất một thể loại", {
                    position: "top-center",
                    autoClose: 2000,
                    pauseOnHover: false,
                });
                return;
            }

            setLoading(true);

            const formData = new FormData();
            formData.append('title', values.title);
            genres.forEach(g => formData.append('genre', g));

            try {
                const reader = new FileReader();
                reader.onloadend = async () => {
                    formData.append('cover', reader.result);
                    formData.append('file', values.file);

                    const result = await uploadTrack(formData, handleSessionOut);
                    if (result === 'Đã thêm') {
                        toast.success("Tải bài hát thành công!", {
                            position: "top-center",
                            autoClose: 2000,
                            pauseOnHover: false,
                        });

                        resetForm();
                        setGenres([]);
                        setPreviewAudio(null);
                        setPreviewImage(null);
                    } else {
                        toast.error("Có lỗi xảy ra khi tải bài hát", {
                            position: "top-center",
                            autoClose: 2000,
                            pauseOnHover: false,
                        });
                    }
                    setLoading(false);
                };
                reader.readAsDataURL(values.cover);
            } catch (err) {
                console.error(err);
                toast.error("Lỗi không xác định", {
                    position: "top-center",
                    autoClose: 2000,
                    pauseOnHover: false,
                });
                setLoading(false);
            }
        }
    });

    const handleAddGenre = () => {
        const g = genreInput.trim();
        if (g && !genres.includes(g)) setGenres([...genres, g]);
        setGenreInput('');
    };

    const handleRemoveGenre = (g) => {
        setGenres(genres.filter(x => x !== g));
    };

    return (
        <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
            <h1 className="fw-bold text-center mb-4 text-white">🎶 Tải lên nhạc mới</h1>

            <Card className="upload-card bg-dark text-white p-4 rounded-4 shadow-sm mx-auto" style={{ maxWidth: '720px' }}>
                <div className="text-center mb-3">
                    <img
                        src={previewImage || "/images/default-music.jpg"}
                        alt="preview"
                        className="rounded-4 shadow-sm"
                        style={{
                            width: '240px',
                            height: '240px',
                            objectFit: 'cover',
                            border: '2px solid #dc3545'
                        }}
                    />
                </div>

                <Form onSubmit={formik.handleSubmit}>
                    <Form.Group className="mb-3">
                        <Form.Label>Tiêu đề</Form.Label>
                        <Form.Control
                            name="title"
                            value={formik.values.title}
                            onChange={formik.handleChange}
                            isInvalid={!!formik.errors.title}
                            placeholder="Nhập tên bài hát"
                            className="bg-secondary text-white border-0"
                        />
                        <Form.Control.Feedback type="invalid">
                            {formik.errors.title}
                        </Form.Control.Feedback>
                    </Form.Group>

                    <Form.Group className="mb-3">
                        <Form.Label>Thể loại</Form.Label>
                        <InputGroup>
                            <Form.Control
                                value={genreInput}
                                onChange={(e) => setGenreInput(e.target.value)}
                                onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddGenre())}
                                placeholder="Nhập thể loại"
                                className="bg-secondary text-white border-0"
                            />
                            <Button variant="danger" style={{ width: '52px', height: '52px', padding: 0 }} onClick={handleAddGenre}><Plus /></Button>
                        </InputGroup>
                        <div className="mt-2">
                            {genres.map((g, i) => (
                                <Badge key={i} bg="light" text="dark" className="me-2 mb-1 genre-badge">
                                    {g} <X onClick={() => handleRemoveGenre(g)} style={{ cursor: 'pointer' }} />
                                </Badge>
                            ))}
                        </div>
                    </Form.Group>

                    <Form.Group className="mb-3">
                        <Form.Label>Ảnh bìa</Form.Label>
                        <div className="custom-file-wrapper">
                            <input
                                type="file"
                                accept="image/*"
                                id="cover-input"
                                className="d-none"
                                onChange={(e) => {
                                    if (!e.currentTarget.files || e.currentTarget.files.length === 0) return;
                                    const file = e.currentTarget.files[0];
                                    formik.setFieldValue('cover', file);
                                    setPreviewImage(URL.createObjectURL(file));
                                }}

                            />
                            <Button variant="outline-light" onClick={() => document.getElementById('cover-input').click()}>
                                📸 Chọn ảnh bìa
                            </Button>
                            {formik.values.cover && <CheckCircle className="text-success ms-2" />}
                        </div>
                        {formik.errors.cover && (
                            <div className="text-danger mt-1 small">{formik.errors.cover}</div>
                        )}
                    </Form.Group>

                    <Form.Group className="mb-3">
                        <Form.Label>File nhạc (MP3)</Form.Label>
                        <div className="custom-file-wrapper">
                            <input
                                type="file"
                                accept="audio/mpeg"
                                id="audio-input"
                                className="d-none"
                                onChange={(e) => {
                                    if (!e.currentTarget.files || e.currentTarget.files.length === 0) return;
                                    const file = e.currentTarget.files[0];
                                    formik.setFieldValue('file', file);
                                    setPreviewAudio(URL.createObjectURL(file));
                                }}
                            />
                            <Button variant="outline-light" onClick={() => document.getElementById('audio-input').click()}>
                                🎵 Chọn file MP3
                            </Button>
                            {formik.values.file && <CheckCircle className="text-success ms-2" />}
                        </div>
                        {formik.errors.file && (
                            <div className="text-danger mt-1 small">{formik.errors.file}</div>
                        )}
                    </Form.Group>

                    {previewAudio && (
                        <div className="mb-3">
                            <p className="mb-1"><strong>🎧 Nghe thử:</strong></p>
                            <audio controls src={previewAudio} style={{ width: '100%' }} />
                        </div>
                    )}

                    <div className="d-flex justify-content-end gap-2">
                        <Button variant="secondary" onClick={() => {
                            formik.resetForm();
                            setGenres([]);
                            setPreviewAudio(null);
                            setPreviewImage(null);
                        }}>
                            Hủy bỏ
                        </Button>
                        <Button type="submit" disabled={loading} variant="danger">
                            {loading ? <Spinner size="sm" animation="border" /> : 'Tải lên'}
                        </Button>
                    </div>
                </Form>
            </Card>

            <ToastContainer />
        </Container>
    );
};

export default UploadTrackForm;
