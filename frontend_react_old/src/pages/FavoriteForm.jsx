import React, { useEffect, useState, useCallback } from 'react';
import { Container, Spinner, Badge, Modal, Button } from 'react-bootstrap';
import { PlayCircle, Info, Heart } from 'lucide-react';
import {
    getMyFavoriteTracks,
    toggleFavorites,
    deleteAllFavorites
} from '../services/favoritesService';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { useNavigate } from 'react-router-dom';
import '../styles/Favorite.css';

const MusicCard = ({ track, onToggleFavorite, onPlay, onInfo }) => {
    return (
        <div className="favorite-music-card">
            <div className="favorite-card-image-container">
                <img
                    src={track.imageUrl || '/images/default-music.jpg'}
                    alt={track.title}
                    className="favorite-card-image"
                />
                {!track.isPublic && (
                    <Badge bg="warning" text="dark" className="vip-badge">
                        👑 VIP
                    </Badge>
                )}
                <div className="favorite-card-overlay">
                    <button className="icon-button" onClick={() => onInfo(track)} title="Thông tin">
                        <Info size={22} />
                    </button>
                    <button className="play-button" onClick={() => onPlay(track)}>
                        <PlayCircle size={50} />
                    </button>
                    <button className="icon-button" onClick={() => onToggleFavorite(track)} title="Bỏ yêu thích">
                        <Heart size={22} fill="red" color="red" />
                    </button>
                </div>
            </div>
            <div className="favorite-card-info">
                <p className="favorite-card-title">{track.title}</p>
                <p className="favorite-card-subtitle">{track.artistName ? track.artistName : 'Musicresu'}</p>
            </div>
        </div>
    );
};

const FavoriteForm = () => {
    const [favoriteTracks, setFavoriteTracks] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showConfirmDeleteModal, setShowConfirmDeleteModal] = useState(false);
    const { playTrackList } = useMusicPlayer();
    const navigate = useNavigate();

    const fetchFavorites = useCallback(async () => {
        setLoading(true);
        try {
            const data = await getMyFavoriteTracks(() => {});
            setFavoriteTracks(data || []);
        } catch (error) {
            console.error("Failed to fetch favorites:", error);
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchFavorites();

        const handleUpdate = () => fetchFavorites();
        window.addEventListener('favorite-updated', handleUpdate);

        return () => window.removeEventListener('favorite-updated', handleUpdate);
    }, [fetchFavorites]);

    const handlePlay = (track) => {
        const playlist = favoriteTracks.map(t => ({
            ...t,
            id: t.id || t.trackId,
            imageUrl: t.imageBase64 || (t.cover ? `/backend/storage/cover_images/${t.cover}` : null) || '/images/default-music.jpg',
        }));

        const index = playlist.findIndex(t => (t.id || t.trackId) === (track.id || track.trackId));
        playTrackList(playlist, index);
    };

    const handleInfo = (track) => {
        navigate(`/track/${track.id || track.trackId}`);
    };

    const handleToggleFavorite = async (track) => {
        const trackId = track.id || track.trackId;
        await toggleFavorites(trackId, () => {});
        setFavoriteTracks(prev => prev.filter(t => (t.id || t.trackId) !== trackId));
    };

    const handleDeleteAll = () => {
        setShowConfirmDeleteModal(true);
    };

    const handleConfirmDelete = async () => {
        await deleteAllFavorites(() => {});
        setFavoriteTracks([]);
        setShowConfirmDeleteModal(false);
    };

    const handleCancelDelete = () => {
        setShowConfirmDeleteModal(false);
    };

    return (
        <div className="favorite-page">
            <Modal show={showConfirmDeleteModal} onHide={handleCancelDelete} centered>
                <Modal.Header closeButton>
                    <Modal.Title>Xác nhận xóa tất cả</Modal.Title>
                </Modal.Header>
                <Modal.Body>Bạn có chắc chắn muốn xóa tất cả bài hát yêu thích? Thao tác này không thể hoàn tác.</Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCancelDelete}>Hủy</Button>
                    <Button variant="danger" onClick={handleConfirmDelete}>Xóa tất cả</Button>
                </Modal.Footer>
            </Modal>

            {loading ? (
                <div className="loading-container">
                    <Spinner animation="border" role="status" />
                </div>
            ) : (
                <Container fluid className="favorite-container py-4">
                    <div className="favorite-header">
                        <h1 className="favorite-title">
                            <Heart size={32} className="favorite-heart-icon" />
                            Bài hát yêu thích
                        </h1>
                        {favoriteTracks.length > 0 && (
                            <Button variant="outline-danger" className="delete-all-btn" onClick={handleDeleteAll}>
                                Xóa tất cả
                            </Button>
                        )}
                    </div>

                    {favoriteTracks.length === 0 ? (
                        <div className="favorite-empty-state text-center">
                            <img src="/images/default-music.jpg" alt="No favorites" className="empty-favorite-img mb-4" />
                            <h3>Chưa có bài hát yêu thích</h3>
                            <p>Nhấn vào trái tim ở bài hát bạn thích để thêm vào đây nhé.</p>
                        </div>
                    ) : (
                        <div className="favorite-grid">
                            {favoriteTracks.map((track) => (
                                <MusicCard
                                    key={track.id || track.trackId}
                                    track={{
                                        ...track,
                                        id: track.id || track.trackId,
                                        title: track.title,
                                        artistName: track.artistName ? track.artistName : 'Musicresu',
                                        imageUrl: track.imageBase64 || (track.cover ? `/backend/storage/cover_images/${track.cover}` : null) || '/images/default-music.jpg',
                                        isPublic: track.isPublic,
                                    }}
                                    onToggleFavorite={handleToggleFavorite}
                                    onPlay={handlePlay}
                                    onInfo={handleInfo}
                                />
                            ))}
                        </div>
                    )}
                </Container>
            )}
        </div>
    );
};

export default FavoriteForm;
