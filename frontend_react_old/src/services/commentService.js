// src/services/commentService.js

const API_BASE = `${process.env.REACT_APP_API_BASE_URL}/api/Comment`;

export const getCommentsByTrackId = async (trackId) => {
    const res = await fetch(`${API_BASE}/comments/${trackId}`);

    if (!res.ok) {
        throw new Error(`Lỗi khi lấy bình luận: ${res.status}`);
    }

    return await res.json();
};

export const postComment = async (trackId, content, handleSessionOut) => {
    const res = await fetch(`${API_BASE}/comments`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify({ trackId, content }),
    });

    if (res.status === 401 || res.status === 403) {
        handleSessionOut();
    }
};

// src/services/commentService.js
export async function deleteComment(commentId, handleSessionOut) {
    const res = await fetch(`http://localhost:5270/api/Comment/delete-comment/${commentId}`, {
        method: 'DELETE',
        headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
    });

    if (res.status === 401 || res.status === 403) return handleSessionOut();
    if (!res.ok) throw new Error('Xóa thất bại');

    return true;
}

