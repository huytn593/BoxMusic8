import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Container, Row, Col, Button, Modal, Form, Badge, Spinner, Alert } from 'react-bootstrap';
import { Plus, Pencil, Trash, Search } from 'lucide-react';
import { useAuth } from '../context/authContext';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { getUserPlaylists, createPlaylist, deletePlaylist, getUserPlaylistLimits } from '../services/playlistService';
import { fetchSearchResults } from '../services/searchService';
import { addTrackToPlaylist } from '../services/playlistService';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import '../styles/Library.css';

const PlaylistCard = ({ playlist, onAddTrack, onEdit, onDelete }) => (
    <div className="playlist-card" onClick={() => onEdit(playlist)}>
        <div className="playlist-card-image-container">
            <img
                src={playlist.imageBase64 || '/images/default-music.jpg'}
                alt={playlist.name}
                className="playlist-card-image"
            />
            <div className="playlist-card-overlay">
                <button
                    className="icon-button add-track-btn"
                    title="Thêm bài hát"
                    onClick={(e) => {
                        e.stopPropagation();
                        onAddTrack(playlist);
                    }}
                >
                    <Plus size={24} />
                </button>
            </div>
        </div>
        <div className="playlist-card-info">
            <h5 className="playlist-card-title">{playlist.name}</h5>
            <p className="playlist-card-track-count">{playlist.trackCount} bài hát</p>
            <div className="playlist-card-actions">
                <Button
                    variant="outline-light"
                    size="sm"
                    className="action-btn"
                    onClick={(e) => {
                        e.stopPropagation();
                        onEdit(playlist);
                    }}
                >
                    <Pencil size={14} />
                </Button>
                <Button
                    variant="outline-danger"
                    size="sm"
                    className="action-btn"
                    onClick={(e) => {
                        e.stopPropagation();
                        onDelete(playlist.id);
                    }}
                >
                    <Trash size={14} />
                </Button>
            </div>
        </div>
    </div>
);

const LibraryForm = () => {
    const { userId } = useParams();
    const { user } = useAuth();
    const { playTrackList } = useMusicPlayer();
    const navigate = useNavigate();
    
    const [playlists, setPlaylists] = useState([]);
    const [loading, setLoading] = useState(true);
    const [limits, setLimits] = useState(null);
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [showAddTrackModal, setShowAddTrackModal] = useState(false);
    const [selectedPlaylist, setSelectedPlaylist] = useState(null);
    const [searchResults, setSearchResults] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [searchLoading, setSearchLoading] = useState(false);

    // Form states
    const [playlistName, setPlaylistName] = useState('');
    const [playlistDescription, setPlaylistDescription] = useState('');
    const [playlistCover, setPlaylistCover] = useState(null);
    const [previewImage, setPreviewImage] = useState(null);

    useEffect(() => {
        if (userId && user?.id === userId) {
            fetchPlaylists();
            fetchLimits();
        }
    }, [userId, user]);

    const fetchPlaylists = async () => {
        try {
            setLoading(true);
            const data = await getUserPlaylists(userId);
            setPlaylists(data);
        } catch (error) {
            toast.error('Không thể tải danh sách playlist');
        } finally {
            setLoading(false);
        }
    };

    const fetchLimits = async () => {
        try {
            const data = await getUserPlaylistLimits(userId);
            setLimits(data);
        } catch (error) {
            console.error('Error fetching limits:', error);
        }
    };

    const handleCreatePlaylist = async () => {
        if (!playlistName.trim()) {
            toast.error('Vui lòng nhập tên playlist');
            return;
        }

        try {
            const playlistData = {
                name: playlistName,
                description: playlistDescription,
                isPublic: true,
                cover: playlistCover
            };

            await createPlaylist(playlistData);
            toast.success('Tạo playlist thành công!');
            setShowCreateModal(false);
            resetForm();
            fetchPlaylists();
            fetchLimits();
        } catch (error) {
            toast.error(error.message || 'Có lỗi xảy ra khi tạo playlist');
        }
    };

    const handleDeletePlaylist = async (playlistId) => {
        if (window.confirm('Bạn có chắc chắn muốn xóa playlist này?')) {
            try {
                await deletePlaylist(playlistId);
                toast.success('Xóa playlist thành công!');
                fetchPlaylists();
                fetchLimits();
            } catch (error) {
                toast.error(error.message || 'Có lỗi xảy ra khi xóa playlist');
            }
        }
    };

    const handleSearchTracks = async () => {
        if (!searchQuery.trim()) {
            setSearchResults([]);
            return;
        }

        try {
            setSearchLoading(true);
            const results = await fetchSearchResults(searchQuery);
            setSearchResults(results.tracks || []);
        } catch (error) {
            toast.error('Không thể tìm kiếm bài hát');
        } finally {
            setSearchLoading(false);
        }
    };

    const handleAddTrackToPlaylist = async (trackId) => {
        try {
            await addTrackToPlaylist(selectedPlaylist.id, trackId);
            toast.success('Đã thêm bài hát vào playlist!');
            setShowAddTrackModal(false);
            setSearchResults([]);
            setSearchQuery('');
        } catch (error) {
            toast.error(error.message || 'Vui lòng nâng cấp tài khoản !');
        }
    };

    const handleEditPlaylist = (playlist) => {
        navigate(`/playlist/${playlist.id}`);
    };

    const resetForm = () => {
        setPlaylistName('');
        setPlaylistDescription('');
        setPlaylistCover(null);
        setPreviewImage(null);
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                setPlaylistCover(reader.result);
                setPreviewImage(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    const getRoleDisplay = (role) => {
        switch (role) {
            case 'normal': return { text: 'Normal', color: 'secondary' };
            case 'Vip': return { text: 'VIP', color: 'warning' };
            case 'Premium': return { text: 'Premium', color: 'info' };
            case 'admin': return { text: 'Admin', color: 'danger' };
            default: return { text: 'Normal', color: 'secondary' };
        }
    };

    const getLimitsDisplay = (limits) => {
        if (!limits) return '';
        
        const isUnlimited = limits.maxPlaylists === 2147483647;
        
        if (isUnlimited) {
            return `Playlist: ${limits.currentPlaylists} (Không giới hạn)`;
        } else {
            return `Playlist: ${limits.currentPlaylists}/${limits.maxPlaylists} — Tối đa ${limits.maxTracksPerPlaylist} bài/playlist`;
        }
    };

    if (loading) {
        return (
            <div className="loading-container">
                <Spinner animation="border" role="status" />
            </div>
        );
    }

    if (user?.id !== userId) {
        return (
            <div className="library-page">
                <Container className="py-5">
                    <Alert variant="danger">Bạn không có quyền truy cập trang này.</Alert>
                </Container>
            </div>
        );
    }

    return (
        <>
            <div className="library-page">
                <Container fluid className="library-container py-4">
                    <div className="library-header">
                        <div className="library-header-info">
                            <h1 className="library-title">Thư viện</h1>
                            {limits && (
                                <div className="library-limits">
                                    <Badge bg={getRoleDisplay(limits.userRole).color} className="me-2 user-role-badge">
                                        {getRoleDisplay(limits.userRole).text}
                                    </Badge>
                                    <span>
                                        Playlists: <strong>{limits.currentPlaylists} / {limits.maxPlaylists === 2147483647 ? 'Không giới hạn' : limits.maxPlaylists}</strong>
                                    </span>
                                </div>
                            )}
                        </div>
                        <Button 
                            className="create-playlist-btn"
                            onClick={() => setShowCreateModal(true)}
                            disabled={limits && limits.currentPlaylists >= limits.maxPlaylists}
                        >
                            <Plus size={20} className="me-2" />
                            Tạo playlist mới
                        </Button>
                    </div>

                    {playlists.length === 0 ? (
                        <div className="library-empty-state text-center">
                            <img src="/images/default-music.jpg" alt="No playlists" className="empty-library-img mb-4" />
                            <h3>Chưa có playlist nào</h3>
                            <p>Tạo playlist đầu tiên để sắp xếp những bài hát yêu thích của bạn.</p>
                        </div>
                    ) : (
                        <div className="library-grid">
                            {playlists.map((playlist) => (
                                <PlaylistCard
                                    key={playlist.id}
                                    playlist={playlist}
                                    onAddTrack={() => {
                                        setSelectedPlaylist(playlist);
                                        setShowAddTrackModal(true);
                                    }}
                                    onEdit={handleEditPlaylist}
                                    onDelete={handleDeletePlaylist}
                                />
                            ))}
                        </div>
                    )}
                </Container>
            </div>

            {/* Create Playlist Modal */}
            <Modal show={showCreateModal} onHide={() => setShowCreateModal(false)} centered dialogClassName="custom-modal">
                <Modal.Header closeButton>
                    <Modal.Title>Tạo playlist mới</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <Form>
                        <Form.Group className="mb-3">
                            <Form.Label>Tên playlist *</Form.Label>
                            <Form.Control
                                type="text"
                                value={playlistName}
                                onChange={(e) => setPlaylistName(e.target.value)}
                                placeholder="Nhập tên playlist"
                            />
                        </Form.Group>
                        <Form.Group className="mb-3">
                            <Form.Label>Mô tả</Form.Label>
                            <Form.Control
                                as="textarea"
                                rows={3}
                                value={playlistDescription}
                                onChange={(e) => setPlaylistDescription(e.target.value)}
                                placeholder="Mô tả playlist (tùy chọn)"
                            />
                        </Form.Group>
                        <Form.Group className="mb-3">
                            <Form.Label>Ảnh bìa</Form.Label>
                            <div className="d-flex align-items-center gap-3">
                                <img
                                    src={previewImage || '/images/default-music.jpg'}
                                    alt="Preview"
                                    className="playlist-cover-preview"
                                />
                                <div>
                                    <Form.Control
                                        type="file"
                                        accept="image/*"
                                        onChange={handleImageChange}
                                        size="sm"
                                    />
                                    <Form.Text>Ảnh mặc định sẽ được sử dụng nếu không có ảnh nào được chọn.</Form.Text>
                                </div>
                            </div>
                        </Form.Group>
                    </Form>
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={() => setShowCreateModal(false)}>
                        Hủy
                    </Button>
                    <Button variant="primary" onClick={handleCreatePlaylist}>
                        Tạo playlist
                    </Button>
                </Modal.Footer>
            </Modal>

            {/* Add Track Modal */}
            <Modal show={showAddTrackModal} onHide={() => setShowAddTrackModal(false)} centered dialogClassName="custom-modal">
                <Modal.Header closeButton>
                    <Modal.Title>
                        Thêm bài hát vào "{selectedPlaylist?.name}"
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <div className="input-group mb-3">
                        <Form.Control
                            type="text"
                            placeholder="Tìm kiếm theo tên bài hát..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && handleSearchTracks()}
                        />
                        <Button variant="primary" onClick={handleSearchTracks}>
                            <Search size={18} />
                        </Button>
                    </div>

                    {searchLoading ? (
                        <div className="text-center py-4">
                            <Spinner animation="border" role="status" />
                        </div>
                    ) : searchResults.length > 0 ? (
                        <div className="search-results-list">
                            {searchResults.map((track) => (
                                <div key={track.id} className="search-result-item">
                                    <img
                                        src={track.imageBase64 || '/images/default-music.jpg'}
                                        alt={track.title}
                                        className="search-result-img"
                                    />
                                    <div className="search-result-info">
                                        <div className="search-result-title">{track.title}</div>
                                        <div className="search-result-artist">{track.artistName || 'N/A'}</div>
                                    </div>
                                     {!track.isPublic && (
                                        <Badge bg="warning" text="dark" className="me-auto ms-2">VIP</Badge>
                                    )}
                                    <Button
                                        variant="outline-success"
                                        size="sm"
                                        className="ms-auto"
                                        onClick={() => handleAddTrackToPlaylist(track.id)}
                                    >
                                        <Plus size={18}/>
                                    </Button>
                                </div>
                            ))}
                        </div>
                    ) : searchQuery && !searchLoading ? (
                        <div className="text-center py-4 text-muted">
                            Không tìm thấy kết quả phù hợp.
                        </div>
                    ) : null}
                </Modal.Body>
            </Modal>
            <ToastContainer theme="dark" />
        </>
    );
};

export default LibraryForm; 