import React, { useEffect, useState } from 'react';
import { Button, Spinner, Container, Modal, Form, InputGroup } from 'react-bootstrap';
import { PlayFill, Trash } from 'react-bootstrap-icons';
import { useNavigate } from 'react-router-dom';
import { changeApprove, changePublic, deleteTrack, getAllTracks } from '../services/trackService';
import { useAuth } from "../context/authContext";
import { useMusicPlayer } from "../context/musicPlayerContext";
import { useLoginSessionOut } from "../services/loginSessionOut";
import { ToastContainer } from "react-toastify";
import '../styles/AdminTrackList.css';

const AdminTrackList = () => {
    const { user } = useAuth();
    const navigate = useNavigate();
    const [tracks, setTracks] = useState([]);
    const [filterStatus, setFilterStatus] = useState('all');
    const [searchQuery, setSearchQuery] = useState('');
    const [loading, setLoading] = useState(true);
    const { playTrackList } = useMusicPlayer();
    const handleSessionOut = useLoginSessionOut();

    const [showConfirmDeleteModal, setShowConfirmDeleteModal] = useState(false);
    const [trackIdToDelete, setTrackIdToDelete] = useState(null);

    useEffect(() => {
        if (!(user?.isLoggedIn && user?.role === 'admin')) {
            navigate('/');
            return;
        }
        fetchTracks();
    }, [user, navigate]);

    const fetchTracks = async () => {
        try {
            setLoading(true);
            const data = await getAllTracks();
            setTracks(data);
        } catch (err) {
            console.error('Lỗi khi tải danh sách nhạc:', err);
        } finally {
            setLoading(false);
        }
    };
    
    const handleDelete = (trackId) => {
        setTrackIdToDelete(trackId);
        setShowConfirmDeleteModal(true);
    };

    const handleConfirmDelete = async () => {
        if (!trackIdToDelete) return;
        try {
            await deleteTrack(trackIdToDelete, handleSessionOut);
            setTracks(prev => prev.filter(t => t.trackId !== trackIdToDelete));
        } catch (err) {
            console.error("Lỗi khi xóa track:", err);
        } finally {
            setShowConfirmDeleteModal(false);
            setTrackIdToDelete(null);
        }
    };

    const handleCancelDelete = () => {
        setShowConfirmDeleteModal(false);
        setTrackIdToDelete(null);
    };

    const handleApprove = async (trackId) => {
        try {
            await changeApprove(trackId);
            setTracks(prev =>
                prev.map(t =>
                    t.trackId === trackId ? { ...t, isApproved: !t.isApproved } : t
                )
            );
        } catch (err) {
            console.error("Lỗi khi phê duyệt track:", err);
        }
    };

    const handleTogglePublic = async (trackId) => {
        try {
            await changePublic(trackId);
            setTracks(prev =>
                prev.map(t =>
                    t.trackId === trackId ? { ...t, isPublic: !t.isPublic } : t
                )
            );
        } catch (err) {
            console.error("Lỗi khi thay đổi trạng thái track:", err);
        }
    };

    const handlePlayMusic = (track) => {
        const playList = [{
            id: track.trackId,
            title: track.title,
            subtitle: track.uploaderName || "Musicresu",
            imageUrl: track.imageBase64,
            isPublic: track.isPublic,
        }];
        playTrackList(playList, 0);
    };

    const filteredTracks = tracks.filter(t => {
        const matchStatus =
            filterStatus === 'all' ||
            (filterStatus === 'approved' && t.isApproved) ||
            (filterStatus === 'pending' && !t.isApproved);

        const uploaderName = (t.uploaderName || 'Musicresu').toLowerCase();
        const title = (t.title || '').toLowerCase();

        const matchSearch = uploaderName.includes(searchQuery.toLowerCase()) || title.includes(searchQuery.toLowerCase());

        return matchStatus && matchSearch;
    });

    const stats = {
        total: tracks.length,
        approved: tracks.filter(t => t.isApproved).length,
        pending: tracks.filter(t => !t.isApproved).length
    };

    if (loading) {
        return (
            <div className="admin-page d-flex justify-content-center align-items-center vh-100">
                <Spinner animation="border" variant="light" />
            </div>
        );
    }

    return (
        <div className="admin-track-management">
            <Container fluid className="admin-container">
                <header className="admin-header">
                    <h1 className="admin-title">🎵 Quản lý bài hát</h1>
                    <div className="admin-stats">
                        <span>Tổng: {stats.total}</span>
                        <span>Đã duyệt: {stats.approved}</span>
                        <span>Chờ duyệt: {stats.pending}</span>
                    </div>
                </header>

                <section className="admin-filters">
                    <Form.Select
                        className="filter-select"
                        value={filterStatus}
                        onChange={e => setFilterStatus(e.target.value)}
                    >
                        <option value="all">Tất cả trạng thái</option>
                        <option value="approved">Đã duyệt</option>
                        <option value="pending">Chờ duyệt</option>
                    </Form.Select>
                    <Form.Control
                        type="text"
                        className="filter-input"
                        placeholder="Tìm theo tên nghệ sĩ hoặc tên bài hát..."
                        value={searchQuery}
                        onChange={e => setSearchQuery(e.target.value)}
                    />
                </section>

                <div className="admin-track-list-header">
                    <span className="col-cover">#</span>
                    <span className="col-title">Tiêu đề</span>
                    <span className="col-genre">Thể loại</span>
                    <span className="col-date">Ngày cập nhật</span>
                    <span className="col-status">Trạng thái</span>
                    <span className="col-actions text-end">Hành động</span>
                </div>

                <main className="admin-track-list">
                    {filteredTracks.length === 0 ? (
                        <div className="empty-state">
                            <h4>Không có bài hát nào</h4>
                            <p>Không tìm thấy bài hát nào phù hợp với bộ lọc hiện tại.</p>
                        </div>
                    ) : (
                        filteredTracks.map(track => (
                            <div key={track.trackId} className="admin-track-item">
                                <div className="track-cover-wrapper">
                                    <img src={track.imageBase64 || '/images/default-music.jpg'} alt={track.title} className="track-cover"/>
                                    <button className="play-btn-overlay" onClick={() => handlePlayMusic(track)}>
                                        <PlayFill size={20} />
                                    </button>
                                </div>

                                <div className="track-info-main">
                                    <h3 className="track-title">{track.title}</h3>
                                    <a href={`/personal-profile/${track.uploaderId}`} className="track-artist-link">
                                        {track.uploaderName || 'Musicresu'}
                                    </a>
                                </div>
                                
                                <div className="track-meta-details col-genre">
                                    {track.genres?.join(', ') || 'Không xác định'}
                                </div>
                                
                                <div className="track-meta-details col-date">
                                    {track.lastUpdate ? new Date(track.lastUpdate).toLocaleDateString('vi-VN') : '—'}
                                </div>
                                
                                <div className="track-meta-details col-status">
                                    {track.uploaderId !== null ? (
                                        <span className={`status-badge ${track.isApproved ? 'status-approved' : 'status-wait'}`}>
                                            {track.isApproved ? 'Đã duyệt' : 'Chờ duyệt'}
                                        </span>
                                    ) : (
                                        <span className={`status-badge ${track.isPublic ? 'status-public' : 'status-vip'}`}>
                                            {track.isPublic ? 'Công khai' : 'VIP'}
                                        </span>
                                    )}
                                </div>
                                
                                <div className="track-actions-group">
                                    {track.uploaderId === null && (
                                        <button className="action-btn-text" onClick={() => handleTogglePublic(track.trackId)}>
                                            {track.isPublic ? 'Set VIP' : 'Set Public'}
                                        </button>
                                    )}
                                    {track.uploaderId !== null && (
                                         <button className="action-btn-text" onClick={() => handleApprove(track.trackId)}>
                                            {track.isApproved ? 'Khóa' : 'Duyệt'}
                                        </button>
                                    )}
                                    <button className="action-btn-icon" onClick={() => handleDelete(track.trackId)} title="Xóa">
                                        <Trash size={18} />
                                    </button>
                                </div>
                            </div>
                        ))
                    )}
                </main>
                <ToastContainer />
            </Container>

            <Modal show={showConfirmDeleteModal} onHide={handleCancelDelete} centered className="admin-modal">
                <Modal.Header closeButton>
                    <Modal.Title>Xác nhận xóa</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    Bạn có chắc chắn muốn xóa bài hát này? Hành động này không thể hoàn tác.
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCancelDelete}>Hủy</Button>
                    <Button variant="danger" onClick={handleConfirmDelete}>Xóa</Button>
                </Modal.Footer>
            </Modal>
        </div>
    );
};

export default AdminTrackList;
