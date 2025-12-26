import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/authContext';
import { followerService } from '../services/followerService';
import { Container, Row, Col, Card, Button, Spinner, Alert, Badge } from 'react-bootstrap';
import { PersonPlusFill, PersonCheckFill, PlayFill } from 'react-bootstrap-icons';
import { Link } from 'react-router-dom';
import '../styles/Follow.css';

const FollowForm = () => {
    const { userId } = useParams();
    const { user } = useAuth();
    const navigate = useNavigate();
    
    const [followingList, setFollowingList] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (!user?.isLoggedIn) {
            navigate('/signin');
            return;
        }

        if (userId !== user.id) {
            navigate(`/follow/${user.id}`);
            return;
        }

        fetchFollowingList();
    }, [userId, user, navigate]);

    const fetchFollowingList = async () => {
        try {
            setLoading(true);
            const data = await followerService.getFollowingList(userId);
            setFollowingList(data.followingList || []);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const handleFollowToggle = async (followingId) => {
        try {
            const isCurrentlyFollowing = followingList.some(following => following.followingId === followingId);
            
            if (isCurrentlyFollowing) {
                await followerService.unfollowUser(userId, followingId);
                setFollowingList(prevList => 
                    prevList.filter(following => following.followingId !== followingId)
                );
            } else {
                await followerService.followUser(userId, followingId);
                fetchFollowingList();
            }
        } catch (err) {
            setError(err.message);
        }
    };

    const getRoleBadge = (role) => {
        const roleLower = role?.toLowerCase();
        switch (roleLower) {
            case 'vip':
                return (
                    <span
                        style={{
                            background: '#ffc107',
                            color: '#222',
                            borderRadius: 10,
                            padding: '1px 8px 1px 6px',
                            fontSize: 10,
                            fontWeight: 700,
                            boxShadow: '0 2px 8px #0005',
                            border: '1px solid #fff',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 3,
                            minWidth: 35,
                            justifyContent: 'center'
                        }}
                    >
                        <span style={{ fontSize: 10, marginRight: 1 }}>👑</span>
                        <span style={{ fontWeight: 700, letterSpacing: 0.5 }}>VIP</span>
                    </span>
                );
            case 'premium':
                return (
                    <span
                        style={{
                            background: 'linear-gradient(135deg,#6f42c1,#0dcaf0)',
                            color: '#fff',
                            borderRadius: 10,
                            padding: '1px 10px 1px 6px',
                            fontSize: 10,
                            fontWeight: 700,
                            boxShadow: '0 2px 8px #0005',
                            border: '1px solid #fff',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 3,
                            minWidth: 45,
                            justifyContent: 'center'
                        }}
                    >
                        <span style={{ fontSize: 10, marginRight: 1 }}>💎</span>
                        <span style={{ fontWeight: 700, letterSpacing: 0.5 }}>PREMIUM</span>
                    </span>
                );
            case 'admin':
                return (
                    <span
                        style={{
                            background: '#ff2d2d',
                            color: '#111',
                            borderRadius: 10,
                            padding: '1px 10px 1px 6px',
                            fontSize: 10,
                            fontWeight: 700,
                            boxShadow: '0 2px 8px #0005',
                            border: '1px solid #fff',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 3,
                            minWidth: 45,
                            justifyContent: 'center'
                        }}
                    >
                        <span style={{ fontSize: 10, marginRight: 1 }}>⚔️</span>
                        <span style={{ fontWeight: 700, letterSpacing: 0.5 }}>ADMIN</span>
                    </span>
                );
            default:
                return null;
        }
    };

    if (loading) {
        return (
            <Container className="mt-5">
                <div className="text-center">
                    <Spinner animation="border" variant="danger" />
                    <p className="mt-3">Đang tải danh sách theo dõi...</p>
                </div>
            </Container>
        );
    }

    if (error) {
        return (
            <Container className="mt-5">
                <Alert variant="danger">
                    <Alert.Heading>Lỗi!</Alert.Heading>
                    <p>{error}</p>
                </Alert>
            </Container>
        );
    }

    return (
        <div style={{ 
            background: 'linear-gradient(135deg, #2d2d2d 0%, #3d3d3d 100%)',
            minHeight: '100vh',
            padding: '20px 0'
        }}>
            <Container className="mt-5">
                <Row>
                    <Col>
                        <div className="d-flex justify-content-between align-items-center mb-4">
                            <h2 className="text-white fw-bold d-flex align-items-center mb-0">
                                <PersonCheckFill className="me-2" />
                                Danh sách đang theo dõi
                            </h2>
                            <Badge bg="secondary" className="fs-6">
                                {followingList.length} người dùng
                            </Badge>
                        </div>

                        {followingList.length === 0 ? (
                            <Card className="text-center py-5">
                                <Card.Body>
                                    <PersonCheckFill size={48} className="text-muted mb-3" />
                                    <h5 className="text-muted">Bạn chưa theo dõi ai</h5>
                                    <p className="text-muted">Khám phá và theo dõi những nghệ sĩ yêu thích của bạn!</p>
                                    <Link to="/discover">
                                        <Button variant="danger">Khám phá ngay</Button>
                                    </Link>
                                </Card.Body>
                            </Card>
                        ) : (
                            <Row>
                                {followingList.map((following) => (
                                    <Col key={following.followingId} lg={4} md={6} className="mb-4">
                                        <Card className="h-100 follow-card">
                                            <Card.Body className="d-flex flex-column">
                                                <div className="d-flex align-items-center mb-3">
                                                    <div className="me-3">
                                                        <img
                                                            src={following.followingAvatar || "/images/default-avatar.png"}
                                                            alt="Avatar"
                                                            className="rounded-circle"
                                                            style={{
                                                                width: "60px",
                                                                height: "60px",
                                                                objectFit: "cover"
                                                            }}
                                                        />
                                                    </div>
                                                    <div className="flex-grow-1">
                                                        <h6 className="mb-1 fw-bold text-white">
                                                            {following.followingName}
                                                        </h6>
                                                        <div className="d-flex align-items-center gap-2">
                                                            {getRoleBadge(following.followingRole)}
                                                        </div>
                                                    </div>
                                                </div>

                                                <div className="mt-auto">
                                                    <div className="d-flex gap-2">
                                                        <Link 
                                                            to={`/personal-profile/${following.followingId}`}
                                                            className="flex-grow-1"
                                                        >
                                                            <Button 
                                                                variant="outline-light" 
                                                                className="w-100"
                                                            >
                                                                <PlayFill className="me-2" />
                                                                Xem trang cá nhân
                                                            </Button>
                                                        </Link>
                                                        <Button
                                                            variant={following.isFollowing ? "outline-danger" : "danger"}
                                                            onClick={() => handleFollowToggle(following.followingId)}
                                                            className="d-flex align-items-center gap-1"
                                                        >
                                                            {following.isFollowing ? (
                                                                <>
                                                                    <PersonCheckFill size={14} />
                                                                    Bỏ theo dõi
                                                                </>
                                                            ) : (
                                                                <>
                                                                    <PersonPlusFill size={14} />
                                                                    Theo dõi
                                                                </>
                                                            )}
                                                        </Button>
                                                    </div>
                                                </div>
                                            </Card.Body>
                                        </Card>
                                    </Col>
                                ))}
                            </Row>
                        )}
                    </Col>
                </Row>
            </Container>
        </div>
    );
};

export default FollowForm; 