import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { getTracksByArtistId } from '../services/trackService';
import { Container, Button, Spinner, Alert, Badge } from 'react-bootstrap';
import { PlayFill, PersonPlusFill, PersonCheckFill } from 'react-bootstrap-icons';
import { useMusicPlayer } from '../context/musicPlayerContext';
import { getProfileData } from '../services/profileService';
import { useAuth } from '../context/authContext';
import { followUser, unfollowUser, checkFollowing } from '../services/followerService';
import { useLoginSessionOut } from '../services/loginSessionOut';
import '../styles/PersonalProfile.css';

const PersonalProfileForm = () => {
    const { profileId } = useParams();
    const [tracks, setTracks] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const { playTrackList } = useMusicPlayer();
    const [userInfo, setUserInfo] = useState(null);
    const { user } = useAuth();
    const [isFollowing, setIsFollowing] = useState(false);
    const [followLoading, setFollowLoading] = useState(false);
    const handleSessionOut = useLoginSessionOut();
    const [followCount, setFollowCount] = useState(0);

    useEffect(() => {
        const fetchData = async () => {
            try {
                setLoading(true);
                const [profileData, tracksData] = await Promise.all([
                    getProfileData(profileId),
                    getTracksByArtistId(profileId)
                ]);

                setUserInfo(profileData);
                setFollowCount(profileData.followersCount || 0);
                setTracks(tracksData.tracks || []);

                if (user?.id && profileId && user.id !== profileId) {
                    const followingStatus = await checkFollowing(profileId, handleSessionOut);
                    setIsFollowing(followingStatus.following);
                }

            } catch (err) {
                setError(err.message);
                console.error('Lỗi khi fetch profile data hoặc tracks:', err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, [profileId, user]);


    const handlePlay = (trackId) => {
        const index = tracks.findIndex(t => t.id === trackId);
        if (index !== -1) {
            playTrackList(tracks, index);
        }
    };

    const genderToString = (gender) => {
        switch (gender) {
            case 0: return "Nam";
            case 1: return "Nữ";
            case 2: return "Khác";
            default: return "Không muốn trả lời";
        }
    };

    const handleFollow = async () => {
        if (!user?.id) {
            // or navigate to login
            alert('Bạn cần đăng nhập để thực hiện chức năng này!');
            return;
        }
        setFollowLoading(true);
        try {
            if (isFollowing) {
                await unfollowUser(profileId, handleSessionOut);
                setFollowCount(prev => prev - 1);
            } else {
                await followUser(profileId, handleSessionOut);
                setFollowCount(prev => prev + 1);
            }
            setIsFollowing(!isFollowing);
        } catch (err) {
            console.error('Lỗi khi thao tác theo dõi:', err);
            alert('Có lỗi xảy ra, vui lòng thử lại!');
        } finally {
            setFollowLoading(false);
        }
    };

    const renderRoleBadge = (role) => {
        if (!role) return null;
        const roleLower = role.toLowerCase();
        let badgeClass = '';
        let icon = '';
        let text = '';

        if (roleLower === 'vip') {
            badgeClass = 'badge-vip';
            icon = '👑';
            text = 'VIP';
        } else if (roleLower === 'premium') {
            badgeClass = 'badge-premium';
            icon = '💎';
            text = 'Premium';
        } else if (roleLower === 'admin') {
            badgeClass = 'badge-admin';
            icon = '⚔️';
            text = 'Admin';
        } else {
            return null;
        }

        return (
            <div className={`profile-badge ${badgeClass}`}>
                <span role="img" aria-label={text}>{icon}</span> {text}
            </div>
        );
    };


    if (loading) {
        return (
            <Container fluid className="profile-page d-flex justify-content-center align-items-center">
                <Spinner animation="border" variant="light" />
            </Container>
        );
    }

    if (error) {
        return (
            <Container fluid className="profile-page">
                <Alert variant="danger">Lỗi: {error}</Alert>
            </Container>
        );
    }

    return (
        <Container fluid className="profile-page">
            {userInfo && (
                <header className="profile-header">
                    <div className="profile-avatar-wrapper">
                        <img
                            src={userInfo.avatarBase64 || '/images/default-avatar.png'}
                            alt={userInfo.fullname}
                            className="profile-avatar"
                        />
                        {renderRoleBadge(userInfo.role)}
                    </div>
                    <div className="profile-info">
                        <h1 className="profile-name">{userInfo.fullname}</h1>
                        <div className="profile-details">
                            <span><strong>Giới tính:</strong> {genderToString(userInfo.gender)}</span>
                            <span><strong>Ngày sinh:</strong> {userInfo.dateOfBirth ? new Date(userInfo.dateOfBirth).toLocaleDateString('vi-VN') : 'N/A'}</span>
                            <span><strong>Lượt theo dõi:</strong> {followCount}</span>
                        </div>
                        {user?.id && user.id !== profileId && (
                            <Button
                                variant={isFollowing ? 'outline-light' : 'danger'}
                                className="follow-btn"
                                disabled={followLoading}
                                onClick={handleFollow}
                            >
                                {isFollowing ? <><PersonCheckFill /> Đang theo dõi</> : <><PersonPlusFill /> Theo dõi</>}
                            </Button>
                        )}
                    </div>
                </header>
            )}

            <main>
                <h2 className="track-list-header">Bài hát của {userInfo?.fullname || 'nghệ sĩ'}</h2>
                {tracks.length > 0 ? (
                    <ul className="track-list-container">
                        {tracks.map(track => (
                            <li key={track.id} className="track-item">
                                <div className="track-cover-art">
                                    <img
                                        src={track.coverImage || '/images/default-music.jpg'}
                                        alt={track.title}
                                    />
                                    {!track.isPublic && (
                                        <Badge bg="warning" text="dark" className="vip-badge-track">👑 VIP</Badge>
                                    )}
                                </div>
                                <div className="track-info">
                                    <div className="track-title">{track.title}</div>
                                    <div className="track-meta">
                                        <span><strong>Thể loại:</strong> {track.genres?.join(', ') || 'N/A'}</span>
                                        <span><strong>Ngày cập nhật:</strong> {new Date(track.updatedAt).toLocaleDateString('vi-VN')}</span>
                                    </div>
                                </div>
                                <Button
                                    variant="danger"
                                    className="track-play-button d-flex align-items-center justify-content-center"
                                    onClick={() => handlePlay(track.id)}
                                >
                                    <PlayFill size={28} />
                                </Button>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <div className="empty-tracks-message">
                        <p className="h5">Chưa có bài hát nào</p>
                        <p>Người dùng này chưa đăng tải bài hát nào. Hãy quay lại sau nhé!</p>
                    </div>
                )}
            </main>
        </Container>
    );
};

export default PersonalProfileForm;
