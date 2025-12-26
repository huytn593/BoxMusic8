import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Container, Row, Col, Card, Button, Modal, Form, Badge, Spinner, Alert, ListGroup } from 'react-bootstrap';
import { Plus, Pencil, Trash, PlayFill, Search, X, ArrowUp, ArrowDown } from 'react-bootstrap-icons';
import { useAuth } from '../context/authContext';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { getPlaylistDetail, updatePlaylist, deletePlaylist, removeTrackFromPlaylist } from '../services/playlistService';
import { fetchSearchResults } from '../services/searchService';
import { addTrackToPlaylist } from '../services/playlistService';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import '../styles/PlaylistDetail.css';

const PlaylistDetailForm = () => {
    const { playlistId } = useParams();
    const navigate = useNavigate();
    const { user } = useAuth();
    const { playTrackList } = useMusicPlayer();
    
    const [playlist, setPlaylist] = useState(null);
    const [loading, setLoading] = useState(true);
    const [showEditModal, setShowEditModal] = useState(false);
    const [showAddTrackModal, setShowAddTrackModal] = useState(false);
    const [searchResults, setSearchResults] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [searchLoading, setSearchLoading] = useState(false);

    // Edit form states
    const [editName, setEditName] = useState('');
    const [editDescription, setEditDescription] = useState('');
    const [editCover, setEditCover] = useState(null);
    const [previewImage, setPreviewImage] = useState(null);

    useEffect(() => {
        if (playlistId) {
            fetchPlaylistDetail();
        }
    }, [playlistId]);

    const fetchPlaylistDetail = async () => {
        try {
            setLoading(true);
            const data = await getPlaylistDetail(playlistId);
            setPlaylist(data);
            setEditName(data.name);
            setEditDescription(data.description || '');
            setPreviewImage(data.imageBase64);
        } catch (error) {
            toast.error('Không thể tải thông tin playlist');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdatePlaylist = async () => {
        if (!editName.trim()) {
            toast.error('Vui lòng nhập tên playlist');
            return;
        }

        try {
            const playlistData = {
                name: editName,
                description: editDescription,
                isPublic: playlist.isPublic,
                cover: editCover
            };

            await updatePlaylist(playlistId, playlistData);
            toast.success('Cập nhật playlist thành công!');
            setShowEditModal(false);
            fetchPlaylistDetail();
        } catch (error) {
            toast.error(error.message || 'Có lỗi xảy ra khi cập nhật playlist');
        }
    };

    const handleDeletePlaylist = async () => {
        if (window.confirm('Bạn có chắc chắn muốn xóa playlist này?')) {
            try {
                await deletePlaylist(playlistId);
                toast.success('Xóa playlist thành công!');
                navigate('/library/' + user.id);
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
            // Lọc ra những bài hát chưa có trong playlist
            const existingTrackIds = playlist.tracks.map(t => t.trackId);
            const filteredResults = results.tracks.filter(track => !existingTrackIds.includes(track.id));
            setSearchResults(filteredResults);
        } catch (error) {
            toast.error('Không thể tìm kiếm bài hát');
        } finally {
            setSearchLoading(false);
        }
    };

    const handleAddTrackToPlaylist = async (trackId) => {
        try {
            await addTrackToPlaylist(playlistId, trackId);
            toast.success('Đã thêm bài hát vào playlist!');
            setShowAddTrackModal(false);
            setSearchResults([]);
            setSearchQuery('');
            fetchPlaylistDetail();
        } catch (error) {
            toast.error(error.message || 'Vui lòng nâng cấp tài khoản !');
        }
    };

    const handleRemoveTrackFromPlaylist = async (trackId) => {
        if (window.confirm('Bạn có chắc chắn muốn xóa bài hát này khỏi playlist?')) {
            try {
                await removeTrackFromPlaylist(playlistId, trackId);
                toast.success('Đã xóa bài hát khỏi playlist!');
                fetchPlaylistDetail();
            } catch (error) {
                toast.error(error.message || 'Không thể xóa bài hát khỏi playlist');
            }
        }
    };

    const handlePlayPlaylist = () => {
        if (playlist.tracks && playlist.tracks.length > 0) {
            const tracks = playlist.tracks.map(track => ({
                id: track.trackId,
                title: track.title,
                subtitle: track.artistName || 'Musicresu',
                imageUrl: track.imageBase64 || '/images/default-music.jpg',
                isPublic: track.isPublic
            }));
            playTrackList(tracks, 0);
        }
    };

    const handlePlayTrack = (track, index) => {
        const tracks = playlist.tracks.map(t => ({
            id: t.trackId,
            title: t.title,
            subtitle: t.artistName || 'Musicresu',
            imageUrl: t.imageBase64 || '/images/default-music.jpg',
            isPublic: t.isPublic
        }));
        playTrackList(tracks, index);
    };

    const handleImageChange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                setEditCover(reader.result);
                setPreviewImage(reader.result);
            };
            reader.readAsDataURL(file);
        }
    };

    if (loading) {
        return (
            <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
                <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '300px' }}>
                    <Spinner animation="border" role="status" />
                </div>
            </Container>
        );
    }

    if (!playlist) {
        return (
            <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
                <Alert variant="danger">Không tìm thấy playlist hoặc không có quyền truy cập.</Alert>
            </Container>
        );
    }

    const isOwner = user?.id === playlist.userId;

    return (
        <>
            <Container fluid className="bg-dark py-5" style={{ minHeight: '100vh' }}>
                <div className="container">
                    {/* Header */}
                    <div className="playlist-header mb-4">
                        <Row className="align-items-center">
                            <Col md={3}>
                                <div className="playlist-cover-container">
                                    <img
                                        src={playlist.imageBase64 || '/images/default-music.jpg'}
                                        alt={playlist.name}
                                        className="playlist-cover"
                                    />
                                </div>
                            </Col>
                            <Col md={9}>
                                <div className="playlist-info">
                                    <h1 className="text-white fw-bold mb-2">{playlist.name}</h1>
                                    {playlist.description && (
                                        <p className="text-muted mb-3">{playlist.description}</p>
                                    )}
                                    <div className="d-flex align-items-center gap-3 mb-3">
                                        <span className="text-light">
                                            {playlist.tracks.length} bài hát
                                        </span>
                                        <span className="text-muted">
                                            Tạo ngày {new Date(playlist.createdAt).toLocaleDateString()}
                                        </span>
                                        {!playlist.isPublic && (
                                            <Badge bg="warning" text="dark">Riêng tư</Badge>
                                        )}
                                    </div>
                                    <div className="d-flex gap-2">
                                        <Button variant="danger" onClick={handlePlayPlaylist}>
                                            <PlayFill className="me-2" />
                                            Phát tất cả
                                        </Button>
                                        {isOwner && (
                                            <>
                                                <Button variant="outline-light" onClick={() => setShowEditModal(true)}>
                                                    <Pencil className="me-2" />
                                                    Chỉnh sửa
                                                </Button>
                                                <Button variant="outline-light" onClick={() => setShowAddTrackModal(true)}>
                                                    <Plus className="me-2" />
                                                    Thêm bài hát
                                                </Button>
                                                <Button variant="outline-danger" onClick={handleDeletePlaylist}>
                                                    <Trash className="me-2" />
                                                    Xóa playlist
                                                </Button>
                                            </>
                                        )}
                                    </div>
                                </div>
                            </Col>
                        </Row>
                    </div>

                    {/* Tracks List */}
                    <div className="tracks-section">
                        <h3 className="text-white mb-3">Danh sách bài hát</h3>
                        {playlist.tracks.length === 0 ? (
                            <div className="text-center text-light py-5">
                                <h5>Chưa có bài hát nào trong playlist</h5>
                                {isOwner && (
                                    <Button variant="outline-light" onClick={() => setShowAddTrackModal(true)}>
                                        <Plus className="me-2" />
                                        Thêm bài hát đầu tiên
                                    </Button>
                                )}
                            </div>
                        ) : (
                            <ListGroup className="tracks-list">
                                {playlist.tracks.map((track, index) => (
                                    <ListGroup.Item key={track.trackId} className="track-item">
                                        <div className="d-flex align-items-center">
                                            <div className="track-number me-3">
                                                {index + 1}
                                            </div>
                                            <img
                                                src={track.imageBase64 || '/images/default-music.jpg'}
                                                alt={track.title}
                                                className="track-thumbnail me-3"
                                            />
                                            <div className="flex-grow-1">
                                                <div className="track-title">{track.title}</div>
                                                <div className="track-artist">{track.artistName || 'Musicresu'}</div>
                                                <div className="track-added">
                                                    Thêm ngày {new Date(track.addedAt).toLocaleDateString()}
                                                </div>
                                            </div>
                                            <div className="track-actions d-flex gap-2">
                                                {!track.isPublic && (
                                                    <Badge bg="warning" text="dark">VIP</Badge>
                                                )}
                                                <Button
                                                    variant="outline-primary"
                                                    size="sm"
                                                    onClick={() => handlePlayTrack(track, index)}
                                                >
                                                    <PlayFill />
                                                </Button>
                                                {isOwner && (
                                                    <Button
                                                        variant="outline-danger"
                                                        size="sm"
                                                        onClick={() => handleRemoveTrackFromPlaylist(track.trackId)}
                                                    >
                                                        <Trash />
                                                    </Button>
                                                )}
                                            </div>
                                        </div>
                                    </ListGroup.Item>
                                ))}
                            </ListGroup>
                        )}
                    </div>
                </div>
            </Container>

            {/* Edit Playlist Modal */}
            <Modal show={showEditModal} onHide={() => setShowEditModal(false)} size="lg">
                <Modal.Header closeButton>
                    <Modal.Title>✏️ Chỉnh sửa playlist</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <Form>
                        <Form.Group className="mb-3">
                            <Form.Label>Tên playlist *</Form.Label>
                            <Form.Control
                                type="text"
                                value={editName}
                                onChange={(e) => setEditName(e.target.value)}
                                placeholder="Nhập tên playlist"
                            />
                        </Form.Group>
                        <Form.Group className="mb-3">
                            <Form.Label>Mô tả</Form.Label>
                            <Form.Control
                                as="textarea"
                                rows={3}
                                value={editDescription}
                                onChange={(e) => setEditDescription(e.target.value)}
                                placeholder="Mô tả playlist (tùy chọn)"
                            />
                        </Form.Group>
                        <Form.Group className="mb-3">
                            <Form.Label>Ảnh bìa</Form.Label>
                            <div className="d-flex align-items-center gap-3">
                                <div className="playlist-cover-preview">
                                    <img
                                        src={previewImage || '/images/default-music.jpg'}
                                        alt="Preview"
                                        className="img-fluid rounded"
                                        style={{ width: '100px', height: '100px', objectFit: 'cover' }}
                                    />
                                </div>
                                <div>
                                    <Form.Control
                                        type="file"
                                        accept="image/*"
                                        onChange={handleImageChange}
                                    />
                                    <Form.Text className="text-muted">
                                        Nếu không chọn, sẽ giữ ảnh hiện tại
                                    </Form.Text>
                                </div>
                            </div>
                        </Form.Group>
                    </Form>
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={() => setShowEditModal(false)}>
                        Hủy
                    </Button>
                    <Button variant="danger" onClick={handleUpdatePlaylist}>
                        Cập nhật
                    </Button>
                </Modal.Footer>
            </Modal>

            {/* Add Track Modal */}
            <Modal show={showAddTrackModal} onHide={() => setShowAddTrackModal(false)} size="lg">
                <Modal.Header closeButton>
                    <Modal.Title>
                        Thêm bài hát vào "{playlist?.name}"
                    </Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    <div className="mb-3">
                        <div className="input-group">
                            <Form.Control
                                type="text"
                                placeholder="Tìm kiếm bài hát..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                onKeyPress={(e) => e.key === 'Enter' && handleSearchTracks()}
                            />
                            <Button variant="outline-secondary" onClick={handleSearchTracks}>
                                <Search />
                            </Button>
                        </div>
                    </div>

                    {searchLoading ? (
                        <div className="text-center py-3">
                            <Spinner animation="border" role="status" />
                        </div>
                    ) : searchResults.length > 0 ? (
                        <div className="search-results">
                            {searchResults.map((track) => (
                                <div key={track.id} className="search-result-item d-flex align-items-center p-2 border-bottom">
                                    <img
                                        src={track.imageBase64 || '/images/default-music.jpg'}
                                        alt={track.title}
                                        className="me-3"
                                        style={{ width: '50px', height: '50px', objectFit: 'cover', borderRadius: '4px' }}
                                    />
                                    <div className="flex-grow-1">
                                        <div className="fw-bold">{track.title}</div>
                                        <div className="text-muted small">{track.artistName || 'Musicresu'}</div>
                                        {!track.isPublic && (
                                            <Badge bg="warning" text="dark" size="sm">VIP</Badge>
                                        )}
                                    </div>
                                    <Button
                                        variant="outline-primary"
                                        size="sm"
                                        onClick={() => handleAddTrackToPlaylist(track.id)}
                                    >
                                        <Plus />
                                    </Button>
                                </div>
                            ))}
                        </div>
                    ) : searchQuery && !searchLoading ? (
                        <div className="text-center py-3 text-muted">
                            Không tìm thấy bài hát nào hoặc tất cả bài hát đã có trong playlist
                        </div>
                    ) : null}
                </Modal.Body>
            </Modal>

            <ToastContainer />
        </>
    );
};

export default PlaylistDetailForm; 