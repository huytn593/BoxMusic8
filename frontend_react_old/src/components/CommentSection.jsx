// src/components/CommentSection.jsx
import React, { useEffect, useState } from 'react';
import { getCommentsByTrackId, postComment, deleteComment } from '../services/commentService';
import { Card, Spinner, Image, Form as BsForm, Button } from 'react-bootstrap';
import { toast } from 'react-toastify';
import { useLoginSessionOut } from "../services/loginSessionOut";
import { useFormik } from 'formik';
import * as Yup from 'yup';
import {useAuth} from "../context/authContext";
import '../styles/CommentSection.css'

export default function CommentSection({ trackId }) {
    const [comments, setComments] = useState([]);
    const [loading, setLoading] = useState(true);
    const handleSessionOut = useLoginSessionOut();
    const { user } = useAuth()

    const fetchComments = async () => {
        try {
            setLoading(true);
            const data = await getCommentsByTrackId(trackId);
            setComments(data);
        } catch (error) {
            console.error("Lỗi khi tải bình luận:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchComments();
    }, [trackId]);

    const formik = useFormik({
        initialValues: {
            content: '',
        },
        validationSchema: Yup.object({
            content: Yup.string()
                .trim()
                .required('Vui lòng nhập nội dung bình luận')
                .max(300, 'Bình luận không được vượt quá 300 ký tự'),
        }),
        onSubmit: async (values, { resetForm }) => {
            try {
                if (!user.isLoggedIn) {
                    toast.info("Đăng nhập để bình luận về bài hát", {
                        position: "top-center",
                        autoClose: 1000,
                        pauseOnHover: false,
                    });
                }
                else{
                    await postComment(trackId, values.content, handleSessionOut);
                    resetForm();
                    fetchComments();
                }
            } catch (error) {
                console.log(error.message);
                toast.error("Lỗi khi gửi bình luận");
            }
        },
    });

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            formik.handleSubmit();
        }
    };

    return (
        <div className="mt-4">
            <BsForm onSubmit={formik.handleSubmit}>
                <BsForm.Group>
                    <BsForm.Control
                        as="textarea"
                        rows={3}
                        name="content"
                        placeholder="Viết bình luận..."
                        value={formik.values.content}
                        onChange={formik.handleChange}
                        onBlur={formik.handleBlur}
                        onKeyDown={handleKeyDown}
                        isInvalid={formik.touched.content && !!formik.errors.content}
                    />
                    <BsForm.Control.Feedback type="invalid">
                        {formik.errors.content}
                    </BsForm.Control.Feedback>
                </BsForm.Group>
            </BsForm>

            <hr />

            {loading ? (
                <div className="text-center">
                    <Spinner animation="border" />
                </div>
            ) : (
                comments.map(comment => (
                    <Card key={comment.commentId} className="my-2 comment-card">
                        <Card.Body className="d-flex">
                            <Image
                                src={comment.imageBase64 || '/images/default-avatar.jpg'}
                                roundedCircle
                                width={48}
                                height={48}
                                className="me-3"
                                style={{ objectFit: 'cover' }}
                            />
                            <div className="flex-grow-1">
                                <h6 className="mb-1">{comment.userName || "Ẩn danh"}</h6>
                                <p className="mb-1">{comment.contents}</p>

                                <div className="d-flex justify-content-between align-items-center">
                                    <small className="text-light">{new Date(comment.createAt).toLocaleString()}</small>

                                    <div>
                                        {user.isLoggedIn && (
                                            <>
                                                {comment.userId === user.id && (
                                                    <Button
                                                        variant="outline-danger"
                                                        size="sm"
                                                        className="me-2"
                                                        onClick={async () => {
                                                            try {
                                                                const deleteStatus = await deleteComment(comment.commentId, handleSessionOut);
                                                                if (deleteStatus){
                                                                    toast.success("Đã xóa bình luận", {
                                                                        position: "top-center",
                                                                        autoClose: 1000,
                                                                        pauseOnHover: false,
                                                                    });
                                                                }
                                                                fetchComments();
                                                            } catch {
                                                                toast.error("Xóa thất bại", {
                                                                    position: "top-center",
                                                                    autoClose: 1000,
                                                                    pauseOnHover: false,
                                                                });
                                                            }
                                                        }}
                                                    >
                                                        Xóa
                                                    </Button>
                                                )}
                                            </>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </Card.Body>
                    </Card>
                ))
            )}
        </div>
    );
}
