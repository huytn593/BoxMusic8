import React, { useEffect, useState } from 'react';
import { Container, Button, Badge, Spinner, Modal } from 'react-bootstrap';
import { PlayCircle, Info, Trash2, Clock } from 'lucide-react';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { useAuth } from '../context/authContext';
import { getUserHistory, deleteHistoryTrack, deleteAllHistory } from '../services/historyService';
import '../styles/Discover.css';
import '../styles/History.css';
import { useNavigate } from "react-router-dom";

const MusicCard = ({ title, artistName, subtitle, imageUrl, isPublic, onPlay, onInfo, onDelete }) => {
    return (
        <div className="history-music-card">
            <div className="history-card-image-container">
                <img
                    src={imageUrl || '/images/default-music.jpg'}
                    alt={title}
                    className="history-card-image"
                />
                {!isPublic && (
                    <Badge bg="warning" text="dark" className="vip-badge">
                        👑 VIP
                    </Badge>
                )}
                <div className="history-card-overlay">
                    <button className="icon-button" onClick={onInfo} title="Thông tin">
                        <Info size={22} />
                    </button>
                    <button className="play-button" onClick={onPlay}>
                        <PlayCircle size={50} />
                    </button>
                    <button className="icon-button" onClick={onDelete} title="Xóa khỏi lịch sử">
                        <Trash2 size={22} />
                    </button>
                </div>
            </div>
            <div className="history-card-info">
                <p className="history-card-title">{title}</p>
                <p className="history-card-artist">{artistName ? artistName : 'Musicresu'}</p>
                <p className="history-card-subtitle">{subtitle}</p>
            </div>
        </div>
    );
};

function timeAgo(date) {
    const now = new Date();
    const past = new Date(date);
    const diff = Math.floor((now - past) / 1000); // seconds

    if (diff < 60) return `${diff} giây trước`;
    if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
    if (diff < 2592000) return `${Math.floor(diff / 86400)} ngày trước`;
    if (diff < 31536000) return `${Math.floor(diff / 2592000)} tháng trước`;
    return `${Math.floor(diff / 31536000)} năm trước`;
}

const HistoryForm = () => {
    const [historyTracks, setHistoryTracks] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);
    const navigate = useNavigate();
    const { playTrackList } = useMusicPlayer();
    const { user } = useAuth();
    const [showConfirmModal, setShowConfirmModal] = useState(false);
    const [deleteTarget, setDeleteTarget] = useState(null); // null: xóa tất cả, object: xóa 1 bài

    useEffect(() => {
        const fetchHistory = async () => {
            if (!user?.isLoggedIn) {
                navigate('/signin');
                return;
            }

            setIsLoading(true);
            setError(null);
            try {
                const data = await getUserHistory(user.id);
                // Transform the data to match the format needed for playTrackList and footer
                const transformedData = data.map(track => ({
                    ...track,
                    id: track.trackId, // Ensure id is available for playTrackList
                    imageUrl: track.imageBase64 // Đảm bảo có imageUrl cho footer
                }));
                setHistoryTracks(transformedData);
            } catch (error) {
                setError('Không thể tải lịch sử nghe nhạc. Vui lòng thử lại sau.');
                console.error('Error fetching history:', error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchHistory();
    }, [user, navigate]);

    const handleDeleteTrack = async (track) => {
        setDeleteTarget(track);
        setShowConfirmModal(true);
    };

    const handleDeleteAll = async () => {
        setDeleteTarget(null);
        setShowConfirmModal(true);
    };

    const handleConfirmDelete = async () => {
        setShowConfirmModal(false);
        if (deleteTarget) {
            // Xóa 1 bài
            try {
                await deleteHistoryTrack(deleteTarget.trackId);
                setHistoryTracks(prev => prev.filter(t => t.trackId !== deleteTarget.trackId));
            } catch (error) {
                console.error('Error deleting track from history:', error);
                setError('Không thể xóa bài hát khỏi lịch sử. Vui lòng thử lại sau.');
            }
        } else {
            // Xóa tất cả
            try {
                await deleteAllHistory();
                setHistoryTracks([]);
            } catch (error) {
                console.error('Error deleting all history:', error);
                setError('Không thể xóa lịch sử. Vui lòng thử lại sau.');
            }
        }
    };

    const handleCancelDelete = () => {
        setShowConfirmModal(false);
        setDeleteTarget(null);
    };

    if (!user?.isLoggedIn) {
        return null; // Component will redirect in useEffect
    }

    return (
        <>
            {/* Modal xác nhận xóa */}
            <Modal show={showConfirmModal} onHide={handleCancelDelete} centered>
                <Modal.Header closeButton>
                    <Modal.Title>Xác nhận xóa</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    {deleteTarget ? (
                        <>Bạn có chắc muốn xóa bài hát <b>{deleteTarget.title}</b> khỏi lịch sử không?</>
                    ) : (
                        <>Bạn có chắc muốn <b>xóa tất cả lịch sử nghe nhạc</b> không? Thao tác này không thể hoàn tác.</>
                    )}
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCancelDelete}>Hủy</Button>
                    <Button variant="danger" onClick={handleConfirmDelete}>Xóa</Button>
                </Modal.Footer>
            </Modal>

            <div className="history-page">
                {isLoading ? (
                    <div className="loading-container">
                        <Spinner animation="border" role="status" />
                    </div>
                ) : (
                    <Container fluid className="history-container py-4">
                        <div className="history-header">
                            <h1 className="history-title">
                                <Clock size={32} className="history-clock-icon" />
                                Lịch sử nghe nhạc
                            </h1>
                            {historyTracks.length > 0 && (
                                <Button variant="outline-danger" className="delete-all-btn" onClick={handleDeleteAll}>
                                    <Trash2 size={18} /> Xóa tất cả
                                </Button>
                            )}
                        </div>

                        {error && (
                            <div className="alert alert-danger" role="alert">
                                {error}
                            </div>
                        )}

                        {!error && historyTracks.length > 0 ? (
                            <div className="history-grid">
                                {historyTracks.map((track) => (
                                    <MusicCard
                                        key={track.trackId}
                                        title={track.title}
                                        artistName={track.artistName ? track.artistName : 'Musicresu'}
                                        subtitle={timeAgo(track.lastPlay)}
                                        imageUrl={track.imageUrl}
                                        isPublic={track.isPublic}
                                        onPlay={() => {
                                            const index = historyTracks.findIndex(t => t.trackId === track.trackId);
                                            playTrackList(historyTracks, index);
                                        }}
                                        onInfo={() => navigate(`/track/${track.trackId}`)}
                                        onDelete={() => handleDeleteTrack(track)}
                                    />
                                ))}
                            </div>
                        ) : !error && (
                            <div className="history-empty-state text-center">
                                <img src="/images/default-music.jpg" alt="No history" className="empty-history-img mb-4" />
                                <h3>Chưa có lịch sử nghe nhạc</h3>
                                <p>Hãy bắt đầu khám phá và nghe nững bài hát bạn yêu thích.</p>
                            </div>
                        )}
                    </Container>
                )}
            </div>
        </>
    );
};

export default HistoryForm;